import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/tipo_produto_model.dart';

class WindowsTipoProdutoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsTipoProdutoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<TipoProduto>(
      telaNome: 'TiposProduto',
      hasPermission: hasPermission,
      fromJson: (json) => TipoProduto.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}
