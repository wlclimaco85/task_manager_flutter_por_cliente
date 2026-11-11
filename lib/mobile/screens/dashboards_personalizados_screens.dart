import 'package:flutter/material.dart';

import '../../widgets/dashboards_personalizados_view.dart';

/// Dashboards no Mobile: a mesma tela de Web/Windows, em coluna vertical.
class MobileDashboardsPersonalizadosScreen extends StatelessWidget {
  const MobileDashboardsPersonalizadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboards')),
      body: const SafeArea(child: DashboardsPersonalizadosView()),
    );
  }
}
