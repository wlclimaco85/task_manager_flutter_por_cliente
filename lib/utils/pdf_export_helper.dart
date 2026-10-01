import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Helper centralizado para exportação de PDF das telas de saúde/treino do App Academia.
/// Usa os packages `pdf` e `printing` sem depender do backend.
class PdfExportHelper {
  static final _formatoData = DateFormat('dd/MM/yyyy');

  // ---------------------------------------------------------------------------
  // Exportar Dieta
  // ---------------------------------------------------------------------------

  /// Gera e exibe o diálogo de impressão/compartilhamento do PDF de dieta.
  static Future<void> exportarDieta(
    BuildContext context, {
    required String nomeAluno,
    required String nutricionista,
    required String objetivo,
    required String dtConsulta,
    required String dtInicio,
    required String dtFinal,
    required String descricao,
    required String oQueAchou,
    int nota = 0,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _cabecalho('Plano de Dieta', nomeAluno),
              pw.SizedBox(height: 16),
              _linha('Nutricionista', nutricionista),
              _linha('Objetivo', objetivo),
              _linha('Data da Consulta', dtConsulta),
              _linha('Período', '$dtInicio a $dtFinal'),
              pw.SizedBox(height: 12),
              _secao('Descrição / Motivo'),
              _paragrafo(descricao),
              if (oQueAchou.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                _secao('O que Achou'),
                _paragrafo(oQueAchou),
              ],
              if (nota > 0) ...[
                pw.SizedBox(height: 8),
                _linha('Nota', nota.toString()),
              ],
              pw.Spacer(),
              _rodape(),
            ],
          );
        },
      ),
    );

    await _exibirPdf(context, doc, 'dieta_$nomeAluno');
  }

  // ---------------------------------------------------------------------------
  // Exportar Exame
  // ---------------------------------------------------------------------------

  /// Gera e exibe o diálogo de impressão/compartilhamento do PDF de exame.
  static Future<void> exportarExame(
    BuildContext context, {
    required String nomeAluno,
    required String nomeExame,
    required String medico,
    required String dataExame,
    required String dataEntrega,
    required String dataConsulta,
    required String laudo,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _cabecalho('Carteira de Exames', nomeAluno),
              pw.SizedBox(height: 16),
              _linha('Exame', nomeExame),
              _linha('Médico', medico),
              _linha('Data do Exame', dataExame),
              _linha('Data de Entrega', dataEntrega),
              _linha('Data da Consulta', dataConsulta),
              if (laudo.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                _secao('Resultado / Laudo'),
                _paragrafo(laudo),
              ],
              pw.Spacer(),
              _rodape(),
            ],
          );
        },
      ),
    );

    await _exibirPdf(context, doc, 'exame_$nomeAluno');
  }

  // ---------------------------------------------------------------------------
  // Exportar lista genérica (Treino / Avaliação Física via grid dinâmico)
  // ---------------------------------------------------------------------------

  /// Gera e exibe PDF de lista genérica de registros (campos nome/valor).
  /// Usado para telas com DynamicGridWindowsScreen onde os dados são mapa JSON.
  static Future<void> exportarListaGenerica(
    BuildContext context, {
    required String titulo,
    required String nomeAluno,
    required List<Map<String, dynamic>> registros,
    List<String>? camposExibidos,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context ctx) => _cabecalho(titulo, nomeAluno),
        footer: (_) => _rodape(),
        build: (pw.Context ctx) {
          if (registros.isEmpty) {
            return [pw.Text('Nenhum registro encontrado.')];
          }
          return registros.map((reg) {
            final campos = camposExibidos ?? reg.keys.toList();
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: campos
                    .where((c) => reg[c] != null && reg[c].toString().isNotEmpty)
                    .map((c) => _linha(_formatarChave(c), reg[c].toString()))
                    .toList(),
              ),
            );
          }).toList();
        },
      ),
    );

    await _exibirPdf(context, doc, '${titulo.toLowerCase().replaceAll(' ', '_')}_$nomeAluno');
  }

  // ---------------------------------------------------------------------------
  // Componentes internos de layout
  // ---------------------------------------------------------------------------

  static pw.Widget _cabecalho(String titulo, String nomeAluno) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green800, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Abraço Contabilidade — App Academia',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Aluno: $nomeAluno',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Text(
            'Gerado em: ${_formatoData.format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  static pw.Widget _linha(String rotulo, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              '$rotulo:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
          pw.Expanded(
            child: pw.Text(valor, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _secao(String texto) {
    return pw.Text(
      texto,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.green800,
      ),
    );
  }

  static pw.Widget _paragrafo(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Text(texto, style: const pw.TextStyle(fontSize: 11)),
    );
  }

  static pw.Widget _rodape() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Text(
        'Documento gerado pelo App Academia • ${_formatoData.format(DateTime.now())}',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
      ),
    );
  }

  /// Converte chave snake_case em texto legível (ex: "data_exame" → "Data Exame").
  static String _formatarChave(String chave) {
    return chave
        .replaceAll('_', ' ')
        .split(' ')
        .map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  // ---------------------------------------------------------------------------
  // Exibição do PDF
  // ---------------------------------------------------------------------------

  static Future<void> _exibirPdf(
    BuildContext context,
    pw.Document doc,
    String nomeArquivo,
  ) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: '$nomeArquivo.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar PDF: $e')),
        );
      }
    }
  }
}
