import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/pedido_model.dart';

class WindowsPedidoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsPedidoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Pedido>(
      telaNome: 'Pedidos',
      hasPermission: hasPermission,
      fromJson: (json) => Pedido.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}
