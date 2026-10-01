import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import 'package:http/http.dart' as http;

class ConciliacaoImportacaoScreen extends StatefulWidget {
  const ConciliacaoImportacaoScreen({super.key});

  @override
  State<ConciliacaoImportacaoScreen> createState() =>
      _ConciliacaoImportacaoScreenState();
}

class _ConciliacaoImportacaoScreenState
    extends State<ConciliacaoImportacaoScreen> {
  bool _importando = false;
  List<Map<String, dynamic>> _transacoes = [];
  String? _arquivoNome;
  Uint8List? _arquivoBytes;
  String? _erro;

  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ofx', 'qfx', 'txt'],
      withData: true,
    );
    if (result == null || !mounted) return;

    final file = result.files.first;
    setState(() {
      _arquivoNome = file.name;
      _arquivoBytes = file.bytes;
      _transacoes = [];
      _erro = null;
    });
  }

  Future<void> _importar() async {
    if (_arquivoBytes == null) return;

    setState(() {
      _importando = true;
      _erro = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.conciliacaoImportarOfx),
      );
      request.headers.addAll(TenantContext.headers);
      request.files.add(
        http.MultipartFile.fromBytes(
          'arquivo',
          _arquivoBytes!,
          filename: _arquivoNome,
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        final transacoes = data['transacoes'] ?? data['data'] ?? [];
        setState(() {
          _transacoes = List<Map<String, dynamic>>.from(
            transacoes.map((t) => Map<String, dynamic>.from(t)),
          );
          _importando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_transacoes.length} transação(ões) extraída(s)'),
          backgroundColor: GridColors.success,
        ));
      } else {
        setState(() {
          _erro = 'Erro na importação (${response.statusCode})';
          _importando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Erro: $e';
          _importando = false;
        });
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  String _fmtData(String? d) {
    if (d == null || d.length < 10) return '-';
    return d.substring(0, 10);
  }

  String _fmtValor(dynamic v) {
    final valor = (v is num) ? v.toDouble() : 0.0;
    return 'R\$${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: GridColors.secondary,
        foregroundColor: Colors.white,
        title: const Text('Importação OFX — Conciliação Bancária'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de seleção
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Importar Extrato Bancário (OFX)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GridColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecione um arquivo OFX/QFX para extrair as transações e posteriormente conciliá-las.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _importando ? null : _selecionarArquivo,
                          icon: const Icon(Icons.folder_open, size: 18),
                          label: const Text('Selecionar Arquivo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GridColors.info,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_arquivoNome != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: GridColors.secondaryLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: GridColors.secondary),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.description,
                                    size: 16, color: GridColors.secondary),
                                const SizedBox(width: 6),
                                Text(_arquivoNome!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: GridColors.errorLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: GridColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: GridColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_erro!,
                                  style: const TextStyle(
                                      color: GridColors.error, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: (_arquivoBytes == null || _importando)
                            ? null
                            : _importar,
                        icon: _importando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cloud_upload, size: 18),
                        label: Text(_importando
                            ? 'Importando...'
                            : 'Importar Transações'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GridColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tabela de transações extraídas
            if (_transacoes.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.table_chart,
                              color: GridColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Transações Extraídas (${_transacoes.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: GridColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowColor:
                              WidgetStateProperty.all(GridColors.secondaryLight),
                          headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          columns: const [
                            DataColumn(label: Text('Data')),
                            DataColumn(label: Text('Descrição')),
                            DataColumn(label: Text('Valor'), numeric: true),
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('ID Transação')),
                          ],
                          rows: _transacoes.map((t) {
                            final valor = (t['valor'] ?? 0).toDouble();
                            final tipo = t['tipo']?.toString() ?? '';
                            final tipoColor = tipo == 'CREDITO'
                                ? GridColors.success
                                : GridColors.error;
                            return DataRow(cells: [
                              DataCell(Text(_fmtData(t['data']?.toString()))),
                              DataCell(SizedBox(
                                width: 250,
                                child: Text(
                                  t['descricao']?.toString() ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              DataCell(Text(
                                _fmtValor(t['valor']),
                                style: TextStyle(
                                  color: tipoColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              )),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tipoColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(tipo,
                                    style: TextStyle(
                                        color: tipoColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              )),
                              DataCell(Text(
                                t['transacaoId']?.toString() ?? '-',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_transacoes.isEmpty && !_importando && _erro == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma transação importada',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
