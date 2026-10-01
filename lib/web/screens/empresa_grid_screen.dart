import 'package:flutter/material.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import 'details/empresa_detail_screen.dart';

class WebEmpresaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebEmpresaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final appId = TenantContext.aplicativoId;
    final fetchEndpoint =
        '${ApiLinks.baseUrl}/api/empresa?skipTenantEmpresa=true'
        '${appId != null ? '&codApp=$appId' : ''}';
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'empresa',
      fetchEndpointOverride: fetchEndpoint,
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      detailScreenBuilder: (item) =>
          WebEmpresaDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
