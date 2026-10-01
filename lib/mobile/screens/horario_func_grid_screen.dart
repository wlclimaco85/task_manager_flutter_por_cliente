import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Horários de Funcionário — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileHorarioFuncGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileHorarioFuncGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_horario_func'),
      telaNome: 'horario_func',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_horario_func',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}
