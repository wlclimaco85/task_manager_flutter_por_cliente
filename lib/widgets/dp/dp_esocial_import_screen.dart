import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';

class DpEsocialImportScreen extends StatefulWidget {
  const DpEsocialImportScreen({super.key});

  @override
  State<DpEsocialImportScreen> createState() => _DpEsocialImportScreenState();
}

class _DpEsocialImportScreenState extends State<DpEsocialImportScreen> {
  final TextEditingController _xmlController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _resultado;
  String? _erro;

  Future<void> _importarXml() async {
    final xml = _xmlController.text.trim();
    if (xml.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cole o conteúdo XML do evento eSocial antes de importar.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _resultado = null;
      _erro = null;
    });

    try {
      final res = await NetworkCaller().postRequest(
        ApiLinks.dpEsocialImportar,
        {'xml': xml},
      );


      if (res.isSuccess && res.body != null) {
        final data = res.body!['data'];
        setState(() {
          _resultado = data is Map ? Map<String, dynamic>.from(data) : null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('XML do eSocial processado com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() {
          _erro = res.errorMessage ?? 'Erro ao processar XML do eSocial.';
        });
      }
    } catch (e) {
      setState(() {
        _erro = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F1),
      appBar: AppBar(
        title: const Text('Importação eSocial (XML)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel Esquerdo: Entrada XML
            Expanded(
              flex: 5,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.upload_file, color: GridColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Conteúdo XML do Evento eSocial',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Eventos suportados: S-2200 (Admissão), S-2205 (Alteração Cadastral), S-2206 (Alteração Contratual), S-2230 (Afastamento/Férias), S-2299 (Desligamento) e S-1030 (Tabela de Cargos CBO).',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TextField(
                          controller: _xmlController,
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: '<?xml version="1.0" encoding="UTF-8"?>\n<eSocial xmlns="...">\n  <evtAdmissao ...>\n  ...</evtAdmissao>\n</eSocial>',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Color(0xFFFAFAFA),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _importarXml,
                            icon: _loading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.play_arrow),
                            label: const Text('Processar e Importar Evento'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GridColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _xmlController.clear();
                                _resultado = null;
                                _erro = null;
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Limpar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Painel Direito: Preview e Resultado do Processamento
            Expanded(
              flex: 4,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Resultado da Importação',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_erro != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(_erro!, style: TextStyle(color: Colors.red.shade800)),
                        ),
                      if (_resultado != null) ...[
                        _buildInfoTile('Evento Identificado', _resultado!['evento']?.toString() ?? '---'),
                        _buildInfoTile('Mensagem', _resultado!['mensagem']?.toString() ?? '---'),
                        if (_resultado!['nome'] != null)
                          _buildInfoTile('Funcionário', _resultado!['nome'].toString()),
                        if (_resultado!['cpf'] != null)
                          _buildInfoTile('CPF', _resultado!['cpf'].toString()),
                        if (_resultado!['cargoId'] != null)
                          _buildInfoTile('Cargo Importado', _resultado!['nomeCargo']?.toString() ?? '---'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.done_all, color: Colors.green),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Dados salvos e sincronizados com o banco de dados e telas do sistema!',
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_erro == null) ...[
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Nenhum evento processado ainda.\nCole o XML ao lado e clique em Processar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black45),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
