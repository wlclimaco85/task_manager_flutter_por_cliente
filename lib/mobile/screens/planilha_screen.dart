import 'package:flutter/material.dart';

import '../../widgets/planilha_view.dart';

class MobilePlanilhaScreen extends StatelessWidget {
  const MobilePlanilhaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planilhas')),
      body: const SafeArea(child: PlanilhaView()),
    );
  }
}
