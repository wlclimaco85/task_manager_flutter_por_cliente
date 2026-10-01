import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'nfce_service.dart';

class PrintServiceNfce {
  final NfceService _nfceService;

  PrintServiceNfce({NfceService? nfceService})
      : _nfceService = nfceService ?? NfceService();

  Future<void> imprimirDanfe(BuildContext context, int nfceId) async {
    try {
      final pdfBytes = await _nfceService.baixarDanfe(nfceId);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'DANFE_NFC-e_$nfceId.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao imprimir DANFE: $e')),
        );
      }
    }
  }

  Future<void> compartilharDanfe(BuildContext context, int nfceId) async {
    try {
      final pdfBytes = await _nfceService.baixarDanfe(nfceId);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'DANFE_NFC-e_$nfceId.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar DANFE: $e')),
        );
      }
    }
  }
}
