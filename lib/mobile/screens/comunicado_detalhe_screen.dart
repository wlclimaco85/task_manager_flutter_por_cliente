import 'package:flutter/material.dart';
import '../../web/screens/comunicado_detalhe_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileComunicadoDetalheScreen extends StatelessWidget {
  final Map<String, dynamic>? comunicado;

  const MobileComunicadoDetalheScreen({super.key, this.comunicado});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Detalhe Comunicado',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.ComunicadoDetalheScreen(
          comunicado: comunicado ?? const {},
        ),
      ),
    );
  }
}
