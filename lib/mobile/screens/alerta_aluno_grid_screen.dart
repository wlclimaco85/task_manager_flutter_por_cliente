import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Alertas — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileAlertaAlunoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileAlertaAlunoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_alerta_aluno'),
      telaNome: 'alerta_aluno',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_alerta_aluno',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}
