import 'package:flutter/material.dart';

import '../../../models/regime_tributario_model.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;

class WebRegimeDetailScreen extends StatelessWidget {
  final RegimeTributario item;
  final SecurityCheck hasPermission;

  const WebRegimeDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return GenericDetailFormScreen(
      item: item.toJson(),
      telaNome: 'regime_tributario',
      hasPermission: hasPermission,
    );
  }
}
