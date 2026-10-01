import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../customization/generic_grid_card.dart';
import '../../utils/grid_colors.dart';

class MobileDetalhePopup extends StatelessWidget {
  final String titulo;
  final Map<String, dynamic> dados;
  final List<FieldConfig> fieldConfigs;

  const MobileDetalhePopup({
    super.key,
    required this.titulo,
    required this.dados,
    required this.fieldConfigs,
  });

  @override
  Widget build(BuildContext context) {
    final campos = fieldConfigs
        .where((f) => f.isInForm || f.showInCard)
        .toList();

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportarPdf(context, campos),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: campos.map((f) => _buildCampoCard(f)).toList(),
        ),
      ),
    );
  }

  Widget _buildCampoCard(FieldConfig campo) {
    final valor = _resolverValor(campo);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: GridColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              campo.icon ?? Icons.label_outline,
              size: 18,
              color: GridColors.secondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campo.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GridColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 14,
                      color: GridColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolverValor(FieldConfig campo) {
    dynamic raw = dados[campo.fieldName];
    if (raw == null) return '—';

    if (campo.fieldType == FieldType.boolean) {
      return raw == true || raw == 'true' ? 'Sim' : 'Não';
    }
    if (campo.fieldType == FieldType.date) {
      try {
        final dt = DateTime.parse(raw.toString());
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }
    if (campo.fieldType == FieldType.dropdown) {
      final displayField = campo.displayFieldName ?? campo.dropdownDisplayField;
      if (raw is Map && raw.containsKey(displayField)) {
        return raw[displayField].toString();
      }
      final options = campo.dropdownOptions ?? [];
      for (final opt in options) {
        if (opt[campo.dropdownValueField].toString() == raw.toString()) {
          return opt[displayField]?.toString() ?? raw.toString();
        }
      }
    }
    return raw.toString();
  }

  Future<void> _exportarPdf(
      BuildContext context, List<FieldConfig> campos) async {
    final doc = pw.Document();

    final linhas = campos
        .map((f) => MapEntry(f.label, _resolverValor(f)))
        .where((e) => e.value != '—')
        .toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green900),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Campo',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Valor',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...linhas.asMap().entries.map((entry) {
                    final par = entry.key.isEven;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: par ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            entry.value.key,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            entry.value.value,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await doc.save();
    if (!context.mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '$titulo.pdf',
    );
  }
}
