import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';

class DpFechamentoFolhaScreen extends StatefulWidget {
  const DpFechamentoFolhaScreen({super.key});

  @override
  State<DpFechamentoFolhaScreen> createState() => _DpFechamentoFolhaScreenState();
}

class _DpFechamentoFolhaScreenState extends State<DpFechamentoFolhaScreen> {
  List<dynamic> _competencias = [];
  Map<String, dynamic>? _selectedComp;
  List<dynamic> _holerites = [];
  bool _loading = false;
  bool _processing = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarCompetencias();
  }

  Future<void> _carregarCompetencias() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final res = await NetworkCaller().getRequest(ApiLinks.dpFolhaCompetencias);
      if (res.isSuccess && res.body != null) {
        final data = res.body!['data'];
        final dados = data is Map ? (data['dados'] ?? data) : data;
        setState(() {
          _competencias = dados is List ? dados : [];
          if (_competencias.isNotEmpty && _selectedComp == null) {
            _selecionarCompetencia(_competencias.first);
          }
        });
      }
    } catch (e) {
      setState(() { _erro = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionarCompetencia(Map<String, dynamic> comp) async {
    setState(() {
      _selectedComp = comp;
      _loading = true;
    });
    try {
      final compId = comp['id'];
      final res = await NetworkCaller().getRequest(ApiLinks.dpFolhaHolerites(compId));
      if (res.isSuccess && res.body != null) {
        final data = res.body!['data'];
        final dados = data is Map ? (data['dados'] ?? data) : data;
        setState(() {
          _holerites = dados is List ? dados : [];
        });
      }
    } catch (e) {
      setState(() { _erro = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _processarFolha() async {
    if (_selectedComp == null) return;
    setState(() => _processing = true);
    try {
      final compId = _selectedComp!['id'];
      final res = await NetworkCaller().postRequest(ApiLinks.dpFolhaProcessar(compId), {});

      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folha calculada com sucesso para todos os funcionários!'), backgroundColor: Colors.green),
        );
        await _carregarCompetencias();
        if (_selectedComp != null) {
          await _selecionarCompetencia(_selectedComp!);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar folha: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F1),
      appBar: AppBar(
        title: const Text('Fechamento de Folha de Pagamento & CNAB 240'),
        actions: [
          if (_selectedComp != null)
            ElevatedButton.icon(
              onPressed: _processing ? null : _processarFolha,
              icon: _processing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.calculate),
              label: const Text('Calcular Folha Completa'),
              style: ElevatedButton.styleFrom(backgroundColor: GridColors.success, foregroundColor: Colors.white),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading && _competencias.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra Superior de Seleção de Competência e CNAB 240
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('Competência: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 12),
                              if (_competencias.isEmpty)
                                const Text('Nenhuma competência cadastrada.')
                              else
                                DropdownButton<int>(
                                  value: _selectedComp?['id'],
                                  items: _competencias.map<DropdownMenuItem<int>>((c) {
                                    final mes = c['mes'];
                                    final ano = c['ano'];
                                    final status = c['status'] ?? 'ABERTA';
                                    return DropdownMenuItem<int>(
                                      value: c['id'],
                                      child: Text('$mes/$ano - $status', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    final f = _competencias.firstWhere((c) => c['id'] == val);
                                    _selecionarCompetencia(f);
                                  },
                                ),
                            ],
                          ),
                          if (_selectedComp != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                final compId = _selectedComp!['id'];
                                final url = ApiLinks.dpFolhaCnab240(compId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Download do arquivo de remessa bancária CNAB 240 iniciado...'), backgroundColor: Colors.green),
                                );
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Exportar Remessa CNAB 240 (Crédito Salários)'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tabela de Holerites Calculados
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Holerites da Competência (${_holerites.length} colaboradores)',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _holerites.isEmpty
                                  ? const Center(
                                      child: Text('Nenhum holerite calculado. Clique em "Calcular Folha Completa" acima.',
                                          style: TextStyle(color: Colors.black54)),
                                    )
                                  : ListView.builder(
                                      itemCount: _holerites.length,
                                      itemBuilder: (ctx, i) {
                                        final h = _holerites[i];
                                        final func = h['funcionario'] as Map? ?? {};
                                        final nome = func['nome'] ?? 'Colaborador';
                                        final bruto = h['valorProventos'] ?? '0.00';
                                        final inss = h['valorInss'] ?? '0.00';
                                        final irrf = h['valorIrrf'] ?? '0.00';
                                        final liq = h['valorLiquido'] ?? '0.00';

                                        return Container(
                                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                                          child: ListTile(
                                            leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.person, color: Colors.green)),
                                            title: Text(nome.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text('Bruto: R\$ $bruto | INSS: R\$ $inss | IRRF: R\$ $irrf', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Líquido: R\$ $liq', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: GridColors.success)),
                                                const SizedBox(width: 16),
                                                IconButton(
                                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                                  tooltip: 'Baixar Holerite PDF',
                                                  onPressed: () {
                                                    final hId = h['id'];
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Download do holerite $hId em PDF...'), backgroundColor: Colors.green),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
