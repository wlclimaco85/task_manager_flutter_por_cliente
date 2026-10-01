import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';

class RenegotiationHandler {
  static Future<bool> renegotiate({
    required BuildContext context,
    required int vendaId,
    required int compradorId,
    required int vendedorId,
    required int qtdSacos,
    required double vlrSacos,
    required int qtdDisponivel,
    required int negociacaoId,
    // Novo parâmetro: callback opcional
    VoidCallback? onSuccess, // Callback sem argumentos
    // Function(NetworkResponse)? onSuccessWithResponse, // Callback com resposta
    // Function(dynamic)? onError, // Callback para erros
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (qtdSacos > qtdDisponivel) {
        Navigator.of(context).pop();
        _showSnackBar(
          context,
          message:
              "A quantidade de sacos solicitada ($qtdSacos) excede o disponível ($qtdDisponivel).",
          isError: true,
        );
        return false;
      }

      if (vlrSacos <= 0) {
        Navigator.of(context).pop();
        _showSnackBar(
          context,
          message: "O valor por saco deve ser maior que zero.",
          isError: true,
        );
        return false;
      }

      Map<String, dynamic> requestBody = {
        "vendaId": vendaId,
        "compradorId": compradorId,
        "vendedorId": vendedorId,
        "qtdSacos": qtdSacos,
        "vlrSacos": vlrSacos,
        "id": negociacaoId,
      };

      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.insertNegociacao, requestBody);

      Navigator.of(context).pop();

      if (response.isSuccess) {
        _showSnackBar(
          context,
          message: "Proposta enviada com sucesso!",
          isError: false,
        );
        // Executa o callback (se fornecido)
        onSuccess?.call();
        //   onSuccessWithResponse?.call(response);
        return true;
      } else {
        _showSnackBar(
          context,
          message: "Erro ao enviar proposta.",
          isError: true,
        );
        // Callback de erro (se fornecido)
        //  onError?.call(response.statusCode);
        return false;
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar(
        context,
        message: "Erro: ${e.toString()}",
        isError: true,
      );
      // Callback de erro (se fornecido)
      //   onError?.call(e);
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
