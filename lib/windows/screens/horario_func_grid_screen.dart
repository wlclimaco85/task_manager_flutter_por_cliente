import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/horario_func_model.dart';

class WindowsHorarioFuncGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsHorarioFuncGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<HorarioFunc>(
      telaNome: 'HorariosFunc',
      hasPermission: hasPermission,
      fromJson: (json) => HorarioFunc.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}
