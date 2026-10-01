import 'package:flutter/material.dart';
import '../../web/screens/aprovacao_pagamento_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileAprovacaoPagamentoScreen extends StatelessWidget {

  const MobileAprovacaoPagamentoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Aprovação de Pagamento',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.AprovacaoPagamentoScreen(),
      ),
    );
  }
}
