import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';

class DpHistoricoFuncionalScreen extends StatefulWidget {
  final int? funcionarioId;
  final String? funcionarioNome;

  const DpHistoricoFuncionalScreen({super.key, this.funcionarioId, this.funcionarioNome});

  @override
  State<DpHistoricoFuncionalScreen> createState() => _DpHistoricoFuncionalScreenState();
}

class _DpHistoricoFuncionalScreenState extends State<DpHistoricoFuncionalScreen> {
  List<dynamic> _historicos = [];
  bool _loading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final url = widget.funcionarioId != null
          ? '${ApiLinks.dpHistoricos}?funcionarioId=${widget.funcionarioId}'
          : ApiLinks.dpHistoricos;
      final res = await NetworkCaller().getRequest(url);
      if (res.isSuccess && res.body != null) {
        final data = res.body!['data'];
        final dados = data is Map ? (data['dados'] ?? data) : data;
        setState(() {
          _historicos = dados is List ? dados : [];
        });
      } else {
        setState(() { _erro = res.errorMessage ?? 'Erro ao carregar histórico funcional'; });
      }
    } catch (e) {
      setState(() { _erro = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F1),
      appBar: AppBar(
        title: Text(widget.funcionarioNome != null
            ? 'Histórico Funcional: ${widget.funcionarioNome}'
            : 'Histórico e Evolução Salarial'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)))
              : _historicos.isEmpty
                  ? const Center(
                      child: Text('Nenhum registro de promoção ou evolução salarial encontrado.',
                          style: TextStyle(color: Colors.black54)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _historicos.length,
                      itemBuilder: (ctx, i) {
                        final h = _historicos[i];
                        final tipo = h['tipo']?.toString() ?? 'REAJUSTE';
                        final dataAlt = h['dataAlteracao']?.toString() ?? '---';
                        final salAnt = h['salarioAnterior'] != null ? 'R\$ ${h['salarioAnterior']}' : '---';
                        final salNovo = h['salarioNovo'] != null ? 'R\$ ${h['salarioNovo']}' : '---';
                        final motivo = h['motivo']?.toString() ?? 'Sem motivo informado';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: _getCorTipo(tipo),
                                  child: const Icon(Icons.trending_up, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(tipo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(dataAlt, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text('Salário: $salAnt  ➜  $salNovo',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: GridColors.success)),
                                      const SizedBox(height: 4),
                                      Text('Motivo: $motivo', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Color _getCorTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'PROMOCAO': return Colors.purple;
      case 'ADMISSAO': return Colors.green;
      case 'DESLIGAMENTO': return Colors.red;
      case 'TRANSFERENCIA': return Colors.blue;
      default: return Colors.teal;
    }
  }
}
