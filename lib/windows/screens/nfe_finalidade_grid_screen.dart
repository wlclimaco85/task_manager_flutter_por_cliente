import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WindowsNfeFinalidadeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsNfeFinalidadeGridScreen({super.key, required this.hasPermission});
  @override
  Widget build(BuildContext context) => DynamicGridWindowsScreen<Map<String, dynamic>>(
    telaNome: 'nfe_finalidade', hasPermission: hasPermission,
    fromJson: (j) => j, toJson: (a) => a);
}
