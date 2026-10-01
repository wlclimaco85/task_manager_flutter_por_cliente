import 'package:flutter/material.dart';
import '../../screens/nfe/design_tokens.dart';

/// Modal de confirmação para ações de manifestação
class ConfirmacaoModalWidget extends StatelessWidget {
  final String titulo;
  final String mensagem;
  final String botaoPrincipal;
  final String botaoSecundario;
  final VoidCallback onBotaoPrincipal;
  final VoidCallback onBotaoSecundario;
  final Color corBotaoPrincipal;
  final IconData? icone;

  const ConfirmacaoModalWidget({
    Key? key,
    required this.titulo,
    required this.mensagem,
    required this.botaoPrincipal,
    required this.botaoSecundario,
    required this.onBotaoPrincipal,
    required this.onBotaoSecundario,
    this.corBotaoPrincipal = ManifestacaoDesignTokens.colorError,
    this.icone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icone != null) ...[
            Icon(icone, color: corBotaoPrincipal),
            SizedBox(width: ManifestacaoDesignTokens.spacing12),
          ],
          Expanded(
            child: Text(
              titulo,
              style: ManifestacaoDesignTokens.textHeadline2,
            ),
          ),
        ],
      ),
      content: Text(
        mensagem,
        style: ManifestacaoDesignTokens.textBodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: onBotaoSecundario,
          child: Text(
            botaoSecundario,
            style: ManifestacaoDesignTokens.textBodyMedium.copyWith(
              color: ManifestacaoDesignTokens.colorNeutral600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onBotaoPrincipal,
          style: ElevatedButton.styleFrom(
            backgroundColor: corBotaoPrincipal,
            padding: EdgeInsets.symmetric(
              horizontal: ManifestacaoDesignTokens.spacing24,
              vertical: ManifestacaoDesignTokens.spacing12,
            ),
          ),
          child: Text(
            botaoPrincipal,
            style: ManifestacaoDesignTokens.textButton,
          ),
        ),
      ],
    );
  }

  /// Exibe o modal
  static void show({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    required String botaoPrincipal,
    required String botaoSecundario,
    required VoidCallback onBotaoPrincipal,
    required VoidCallback onBotaoSecundario,
    Color corBotaoPrincipal = ManifestacaoDesignTokens.colorError,
    IconData? icone,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmacaoModalWidget(
        titulo: titulo,
        mensagem: mensagem,
        botaoPrincipal: botaoPrincipal,
        botaoSecundario: botaoSecundario,
        onBotaoPrincipal: onBotaoPrincipal,
        onBotaoSecundario: onBotaoSecundario,
        corBotaoPrincipal: corBotaoPrincipal,
        icone: icone,
      ),
    );
  }
}
