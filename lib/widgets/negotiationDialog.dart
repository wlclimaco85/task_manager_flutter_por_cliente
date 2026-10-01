import 'package:flutter/material.dart';
import '../../../models/venda_model.dart';
import '../../constants/custom_colors.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/showSnackBar.dart';
import '../utils/grid_texts.dart';

class NegotiationDialog extends StatefulWidget {
  final Produto product;
  final int compradorId;

  const NegotiationDialog({
    super.key,
    required this.product,
    required this.compradorId,
  });

  @override
  State<NegotiationDialog> createState() => _NegotiationDialogState();
}

class _NegotiationDialogState extends State<NegotiationDialog> {
  late final TextEditingController _qtdController;
  late final TextEditingController _valorController;

  @override
  void initState() {
    super.initState();
    _qtdController = TextEditingController();
    _valorController = TextEditingController();
  }

  @override
  void dispose() {
    _qtdController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CustomColors().getLightGreenBackground(),
      title: Text(
        'Negociar Arroz em Casca LOTE - ${widget.product.id ?? "Sem descrição"}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quantidade atual: ${widget.product.qtdSacos ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _qtdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nova quantidade',
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: CustomColors().getDarkGreenBorder(), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: CustomColors().getDarkGreenBorder(), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Valor atual por saco: R\$${widget.product.vlrSacos ?? 0.0}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valorController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Novo valor por saco',
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: CustomColors().getDarkGreenBorder(), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: CustomColors().getDarkGreenBorder(), width: 2),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(150, 50),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            final int qtdSacos = int.tryParse(_qtdController.text.trim()) ?? 0;
            final double vlrSacos =
                double.tryParse(_valorController.text.trim()) ?? 0.0;

            final response = await renegotiate(
              vendaId: widget.product.id!,
              compradorId: widget.compradorId,
              vendedorId: widget.product.parceiro?.id ?? 0,
              qtdSacos: qtdSacos,
              vlrSacos: vlrSacos,
              qtdDisponivel: widget.product.qtdSacos!,
            );

            if (!mounted) return;
            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response
                    ? 'Proposta enviada com sucesso!'
                    : 'Erro ao renegociar.'),
                backgroundColor: response ? Colors.green : Colors.red,
              ),
            );
          },
          child: const Text('Enviar Proposta'),
        ),
      ],
    );
  }

  Future<bool> renegotiate({
    required int vendaId,
    required int compradorId,
    required int vendedorId,
    required int qtdSacos,
    required double vlrSacos,
    required int qtdDisponivel,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (qtdSacos > qtdDisponivel) {
        Navigator.of(context).pop();
        showSnackBar(
          message:
              "A quantidade de sacos solicitada ($qtdSacos) excede o disponível ($qtdDisponivel).",
          isError: true,
          context: context,
        );
        return false;
      }

      if (vlrSacos <= 0) {
        Navigator.of(context).pop();
        showSnackBar(
          message: "O valor por saco deve ser maior que zero.",
          isError: true,
          context: context,
        );
        return false;
      }

      Map<String, dynamic> requestBody = {
        "vendaId": vendaId,
        "compradorId": compradorId,
        "vendedorId": vendedorId,
        "qtdSacos": qtdSacos,
        "vlrSacos": vlrSacos,
      };

      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.insertNegociacao, requestBody);

      Navigator.of(context).pop();

      if (response.isSuccess) {
        showSnackBar(
          message: "Proposta enviada com sucesso!",
          isError: false,
          context: context,
        );
        return true;
      } else {
        showSnackBar(
          message: "Erro ao enviar proposta.",
          isError: true,
          context: context,
        );
        return false;
      }
    } catch (e) {
      Navigator.of(context).pop();
      showSnackBar(
        message: "Erro: ${e.toString()}",
        isError: true,
        context: context,
      );
      return false;
    }
  }
}
