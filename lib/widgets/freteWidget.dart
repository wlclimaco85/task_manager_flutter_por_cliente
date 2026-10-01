import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/checkout_caller.dart';
import '../../constants/custom_colors.dart';

class FreteService {
  static void mostrarPopupFrete({
    required BuildContext context,
    required int vendaId,
    required int compradorId,
    required int peso,
    required String cidadeOrigem,
    required String cidadeDestino,
    required String bairroOrigem,
    required String bairroDestino,
  }) {
    late Future<double> freteFuture;
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    Future<double> calcularFrete() async {
      Map<String, dynamic> requestBody = {
        "vendaId": vendaId,
        "compradorId": compradorId,
        "peso": peso,
        "isNegociacao": false,
      };

      try {
        return await CheckoutCaller.carregarVlrFrete(context, requestBody);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao calcular frete: ${e.toString()}')),
        );
        return 0.0;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Detalhes do Frete'),
          content: FutureBuilder<double>(
            future: calcularFrete(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Calculando frete...',
                        style: TextStyle(color: Colors.grey)),
                  ],
                );
              }

              if (snapshot.hasError) {
                return const Text('Erro ao calcular frete',
                    style: TextStyle(color: Colors.red));
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Origem: $bairroDestino - $cidadeOrigem',
                      style:
                          TextStyle(color: CustomColors().getTextColorDesc())),
                  Text('Destino: $bairroOrigem - $cidadeDestino',
                      style:
                          TextStyle(color: CustomColors().getTextColorDesc())),
                  const SizedBox(height: 12),
                  Text('Valor Total: ${formatter.format(snapshot.data!)}',
                      style: TextStyle(
                          color: CustomColors().getTextColorDesc(),
                          fontWeight: FontWeight.bold)),
                  Text('Peso: $peso kg'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: Colors.green[800]!.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Frete: ${formatter.format(snapshot.data!)}'),
                        const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Este é o valor estimado de frete. Será feita uma nova cotação junto aos motoristas parceiros para verificar se conseguiremos manter o preço.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              );
            },
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}
