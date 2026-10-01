import 'package:flutter/material.dart';
import 'generic_grid_windows_screen.dart';

class TabConfig {
  final String title;
  final IconData icon;
  final bool isGrid;

  /// Para formulário
  final List<FieldConfigWindows>? formFields;

  /// Para grid usando DynamicGridWindowsScreen
  final String? gridTelaNome;

  TabConfig({
    required this.title,
    required this.icon,
    required this.isGrid,
    this.formFields,
    this.gridTelaNome,
  });
}
