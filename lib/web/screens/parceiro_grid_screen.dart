import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../utils/parceiro_form_rules.dart';
import 'details/parceiro_detail_screen.dart';

class WebParceiroGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebParceiroGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'parceiro',
      tituloOverride: 'Contatos',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fieldOverrides: [
        DropdownHelpers.empresaField(required: true),
        DropdownHelpers.parceiroFieldScopedOrSelectable(),
        ...ParceiroFormRules.desktopModuleSuppression(),
      ],
      detailScreenBuilder: (item) =>
          WebParceiroDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
