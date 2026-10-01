import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/parceiro_form_rules.dart';
import 'details/parceiro_detail_screen.dart';

class WindowsFornecedorGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsFornecedorGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'parceiro',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      tituloOverride: 'Fornecedor',
      fieldOverrides: [
        ParceiroFormRules.desktopSupplierType(),
        ...ParceiroFormRules.desktopModuleSuppression(),
      ],
      transformFormData: ParceiroFormRules.removeSupplierTypeFromPayload,
      fetchEndpointOverride: ApiLinks.allFornecedores,
      createEndpointOverride: ApiLinks.createFornecedor,
      updateEndpointOverride: ApiLinks.updateFornecedor(''),
      deleteEndpointOverride: ApiLinks.deleteFornecedor(''),
      detailScreenBuilder: (item) => WindowsParceiroDetailScreen(
        item: item,
        hasPermission: hasPermission,
        titleOverride: 'Fornecedor',
      ),
    );
  }
}
