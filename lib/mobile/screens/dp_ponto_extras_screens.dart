import 'package:flutter/material.dart';

import '../../utils/grid_colors.dart';
import '../../web/screens/dp_banco_horas_screen.dart';
import '../../web/screens/dp_espelho_assinatura_screen.dart';
import '../../web/screens/dp_pendencias_screen.dart';

/// Mobile: envelopa as telas de Assinatura do Espelho, Banco de Horas e Pendencias do DP (layout vertical) com AppBar.
class _MobileDpEnvelope extends StatelessWidget {
  const _MobileDpEnvelope({required this.titulo, required this.corpo});

  final String titulo;
  final Widget corpo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(child: corpo),
    );
  }
}

class MobileDpEspelhoAssinaturaScreen extends StatelessWidget {
  const MobileDpEspelhoAssinaturaScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _MobileDpEnvelope(titulo: 'Assinatura do Espelho', corpo: DpEspelhoAssinaturaScreen());
}

class MobileDpBancoHorasScreen extends StatelessWidget {
  const MobileDpBancoHorasScreen({super.key});

  @override
  Widget build(BuildContext context) => const _MobileDpEnvelope(titulo: 'Banco de Horas', corpo: DpBancoHorasScreen());
}

class MobileDpPendenciasScreen extends StatelessWidget {
  const MobileDpPendenciasScreen({super.key});

  @override
  Widget build(BuildContext context) => const _MobileDpEnvelope(titulo: 'Pendências do DP', corpo: DpPendenciasScreen());
}
