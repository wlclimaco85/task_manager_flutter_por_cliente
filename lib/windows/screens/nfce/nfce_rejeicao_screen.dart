import 'package:flutter/material.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/grid_texts.dart';

/// Tela exibida quando a NFC-e é rejeitada pela SEFAZ.
class NfceRejeicaoScreen extends StatelessWidget {
  final String motivo;
  final String? codigoRetorno;
  final String? chaveAcesso;
  final String? xMotivo;
  final VoidCallback onTentarNovamente;
  final VoidCallback onCancelar;

  const NfceRejeicaoScreen({
    super.key,
    required this.motivo,
    this.codigoRetorno,
    this.chaveAcesso,
    this.xMotivo,
    required this.onTentarNovamente,
    required this.onCancelar,
  });

  String get _motivoNormalizado {
    final partes = <String>[];
    if (codigoRetorno != null && codigoRetorno!.trim().isNotEmpty) {
      partes.add(GridTexts.rejectionCode(codigoRetorno!.trim()));
    }
    final motivoBase = motivo.trim();
    if (motivoBase.isNotEmpty) {
      partes.add(motivoBase);
    } else if (xMotivo != null && xMotivo!.trim().isNotEmpty) {
      partes.add(xMotivo!.trim());
    }
    return partes.isEmpty ? GridTexts.rejectionWithoutMessage : partes.join(' — ');
  }

  /// Mapeia códigos de rejeição conhecidos para mensagens amigáveis.
  String get _orientacao {
    final codigo = (codigoRetorno ?? '').trim();
    final texto = '${motivo.toLowerCase()} ${xMotivo?.toLowerCase() ?? ''}';

    if (codigo == '225' || texto.contains('assinatura')) {
      return GridTexts.signatureDigitalError;
    }
    if (codigo == '228') {
      return GridTexts.certificateDateTimeMismatch;
    }
    if (codigo == '227') {
      return GridTexts.duplicateAccessKeyNotice;
    }
    if (codigo == '539' || texto.contains('csc')) {
      return GridTexts.invalidCscNotice;
    }
    if (codigo == '999' || texto.contains('schema')) {
      return GridTexts.xmlSchemaErrorNotice;
    }
    if (codigo.startsWith('2')) {
      return GridTexts.fiscalValidationRejectionNotice;
    }
    if (codigo.startsWith('5')) {
      return GridTexts.registryOrStructuralRejectionNotice;
    }
    return GridTexts.checkSaleDataAndRetryNotice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(GridTexts.nfceRejectedTitle),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          GridTexts.nfceRejectedTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Motivo
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          GridTexts.rejectionReasonLabel,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _motivoNormalizado,
                          style: const TextStyle(color: Colors.red),
                        ),
                        if (xMotivo != null && xMotivo!.trim().isNotEmpty &&
                            xMotivo!.trim() != motivo.trim()) ...[
                          const SizedBox(height: 8),
                          SelectableText(xMotivo!),
                        ],
                        if (chaveAcesso != null && chaveAcesso!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            GridTexts.accessKeyCaption,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(chaveAcesso!),
                        ],
                        const Divider(height: 24),
                        const Text(
                          GridTexts.whatToDoLabel,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_orientacao),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botoes
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text(GridTexts.cancelSale),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red),
                        onPressed: onCancelar,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text(GridTexts.retryAgain),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GridColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: onTentarNovamente,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
