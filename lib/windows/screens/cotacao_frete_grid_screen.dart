import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/cotacao_frete_model.dart';

class WindowsCotacaoFreteGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsCotacaoFreteGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<CotacaoFrete>(
      telaNome: 'CotacoesFrete',
      hasPermission: hasPermission,
      fromJson: (json) => CotacaoFrete.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}
