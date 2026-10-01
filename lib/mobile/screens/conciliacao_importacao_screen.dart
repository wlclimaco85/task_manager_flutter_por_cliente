import 'package:flutter/material.dart';
import '../../web/screens/conciliacao_importacao_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileConciliacaoImportacaoScreen extends StatelessWidget {

  const MobileConciliacaoImportacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Importação de Conciliação',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.ConciliacaoImportacaoScreen(),
      ),
    );
  }
}
