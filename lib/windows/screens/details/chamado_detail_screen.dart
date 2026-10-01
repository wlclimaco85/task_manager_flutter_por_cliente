import 'package:flutter/material.dart';
import '../../../models/chamado_model.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;

class WindowsChamadoDetailScreen extends StatelessWidget {
  final Chamado item;
  final SecurityCheck hasPermission;

  const WindowsChamadoDetailScreen({super.key, required this.item, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericDetailFormScreen(
      item: item.toJson(),
      telaNome: 'chamado',
      hasPermission: hasPermission,
    );
  }
}
