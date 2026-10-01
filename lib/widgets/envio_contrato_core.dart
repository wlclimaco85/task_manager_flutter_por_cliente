import 'package:flutter/material.dart';
import '../../services/checkout_caller.dart';
import '../../mobile/screens/negociacao_screen.dart';
import '../../../utils/api_links.dart';
import '../../../models/auth_utility.dart';
import '../../constants/custom_colors.dart';

class RenegotiationMovimentoContratosHandler {
  static Future<bool> renegotiates({
    required BuildContext context,
    required int vendaId,
    required String status,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Future<void> downloadContract(int contratoId, BuildContext context) async {
      try {
        bool success =
            await CheckoutCaller().downloadContrato(contratoId, context);

        if (success) {
          // Fecha todos os diálogos abertos
          Navigator.of(context).popUntil((route) => route.isFirst);

          // Mostra feedback de sucesso
          _showSnackBar(
            context,
            message: "Contrato baixado com sucesso.",
            isError: false,
          );

          // Navega para a tela de negociação
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NegociacaoCatalogPage(
                title: 'Negociação',
                apiUrl:
                    '${ApiLinks.negociacaoFindByUser}${AuthUtility.userInfo?.data?.id}',
                actionIcon: Icons.edit,
                actionTooltip: 'Editar Produto',
              ),
            ),
          );
        } else {
          _showSnackBar(
            context,
            message: "Erro ao baixar contrato.",
            isError: true,
          );
        }
      } catch (e) {
        _showSnackBar(
          context,
          message: "Erro: ${e.toString()}",
          isError: true,
        );
      }
    }

    Future<void> uploadContract(int negociacaoID) async {
      try {
        CheckoutCaller.uploadContract(negociacaoID);
      } catch (e) {}
    }

    try {
      // Fecha o diálogo de carregamento antes de abrir o novo popup
      Navigator.of(context).pop();

      try {
        void showDownloadAndUploadButtons() {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: CustomColors().getLightGreenBackground(),
                title: Text('Contrato',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CustomColors().getDarkGreenBorder())),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'download' || status == 'both')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download, size: 24),
                          label: const Text('Baixar Contrato Modelo',
                              style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                CustomColors().getDarkGreenBorder(),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                  color: CustomColors().getDarkGreenBorder()),
                            ),
                          ),
                          onPressed: () => downloadContract(vendaId, context),
                        ),
                      ),
                    if (status == 'upload' || status == 'both')
                      const SizedBox(height: 15),
                    if (status == 'upload' || status == 'both')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.upload, size: 24),
                          label: const Text('Enviar Contrato Assinado',
                              style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                CustomColors().getDarkGreenBorder(),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                  color: CustomColors().getDarkGreenBorder()),
                            ),
                          ),
                          onPressed: () => uploadContract(vendaId),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fechar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CustomColors().getDarkGreenBorder())),
                  ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                      color: CustomColors().getDarkGreenBorder(), width: 2),
                ),
              );
            },
          );
        }

        showDownloadAndUploadButtons();

        return true;
      } catch (e) {
        Navigator.of(context).pop();
        _showSnackBar(
          context,
          message: "Erro: ${e.toString()}",
          isError: true,
        );
        return false;
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar(context, message: "Erro: ${e.toString()}", isError: true);
      return false;
    }
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
