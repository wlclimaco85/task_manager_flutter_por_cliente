import 'package:flutter/material.dart';
import '../../../utils/grid_colors.dart';

import '../../../models/nfce/nfce_resultado_model.dart';
import '../../../widgets/nfce/nfce_danfe_panel.dart';
import 'nfce_cancelamento_screen.dart';

/// Tela exibida quando a NFC-e é autorizada pela SEFAZ.
class NfceAutorizadaScreen extends StatelessWidget {
  final NfceResultadoModel resultado;
  final VoidCallback onNovaVenda;

  const NfceAutorizadaScreen({
    super.key,
    required this.resultado,
    required this.onNovaVenda,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('NFC-e Autorizada'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'NFC-e Autorizada',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                NfceDanfeWidget(resultado: resultado),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eventos fiscais disponíveis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A4B00),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'O cancelamento pode ser solicitado pelo app após a autorização, dentro do prazo fiscal permitido. Inutilização e contingência continuam disponíveis nos fluxos próprios.',
                        style: TextStyle(color: Color(0xFF7A4B00), height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 220,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancelar NFC-e'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NfceCancelamentoScreen(
                                resultado: resultado,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Nova venda'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GridColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: onNovaVenda,
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
