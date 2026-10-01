import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/regime_tributario_model.dart';
import '../../windows/screens/details/regime_tributario_detail.dart';

class WindowsRegimeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsRegimeGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<RegimeTributario>(
      telaNome: 'Regime Tributarios', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => RegimeTributario.fromJson(json),
      toJson: (a) => a.toJson(),
      detailScreenBuilder: (item) =>
          WindowsRegimeDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
