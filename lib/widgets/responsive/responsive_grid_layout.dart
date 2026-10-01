import 'package:flutter/material.dart';

/// Grid layout responsivo mobile-first com breakpoints configuráveis
/// - Mobile (<768px): 1 coluna
/// - Tablet (768px-1024px): 2 colunas
/// - Desktop (>=1024px): 3 colunas
class ResponsiveGridLayout extends StatelessWidget {
  static const int breakpointMobile = 768;
  static const int breakpointTablet = 1024;

  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final double? runSpacing;

  const ResponsiveGridLayout({
    required this.children,
    this.padding,
    this.spacing,
    this.runSpacing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = _calculateCrossAxisCount(width);
        return _buildGridView(crossAxisCount);
      },
    );
  }

  /// Calcula o número de colunas baseado na largura disponível.
  ///
  /// Retorna:
  /// - 1 coluna para width < 768px (mobile)
  /// - 2 colunas para 768px <= width < 1024px (tablet)
  /// - 3 colunas para width >= 1024px (desktop)
  int _calculateCrossAxisCount(double width) {
    if (width < breakpointMobile) {
      return 1;
    } else if (width < breakpointTablet) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Constrói o GridView com configurações responsivas.
  ///
  /// Usa valores padrão:
  /// - Spacing: 8.0
  /// - Padding: EdgeInsets.all(8.0)
  Widget _buildGridView(int crossAxisCount) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(8.0),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: runSpacing ?? 8.0,
        crossAxisSpacing: spacing ?? 8.0,
        children: children,
      ),
    );
  }
}
