import 'package:flutter/material.dart';

import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;
import '../../../widgets/produto_detail_tabs.dart';

class WebProdutoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const WebProdutoDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    final produtoId = item['id'] as int? ?? 0;

    return GenericDetailFormScreen(
      item: item,
      telaNome: 'produto',
      hasPermission: hasPermission,
      relatedTabs: buildProdutoRelatedTabs(produtoId),
    );
  }
}
