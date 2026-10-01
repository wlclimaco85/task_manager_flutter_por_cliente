import 'package:flutter/material.dart';
import '../../web/screens/envio_documento_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileEnvioDocumentoScreen extends StatelessWidget {

  const MobileEnvioDocumentoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Envio de Documentos',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.EnvioDocumentoScreen(),
      ),
    );
  }
}
