import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/regime_tributario_model.dart';
import '../../web/screens/details/regime_tributario_detail.dart';

class WebRegimeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebRegimeGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<RegimeTributario>(
      telaNome: 'regime_tributario', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => RegimeTributario.fromJson(json),
      toJson: (a) => a.toJson(),
      detailScreenBuilder: (item) =>
          WebRegimeDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
