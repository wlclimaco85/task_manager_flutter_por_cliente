import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/calendario_guias_model.dart';

class WindowsCalendarioGuiasGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsCalendarioGuiasGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<CalendarioGuias>(
      telaNome: 'CalendariosGuias',
      hasPermission: hasPermission,
      fromJson: (json) => CalendarioGuias.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}
