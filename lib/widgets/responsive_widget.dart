import 'package:flutter/material.dart';

/// Widget base responsivo que usa LayoutBuilder para selecionar builder correto
/// baseado em breakpoints.
///
/// Breakpoints:
/// - Mobile: width < 768px
/// - Tablet: 768 <= width < 1024px
/// - Desktop: width >= 1024px
///
/// Se um builder não for fornecido, fallback para o anterior na cadeia:
/// desktop (se não definido) → tablet → mobile
class ResponsiveWidget extends StatelessWidget {
  /// Builder para layout mobile (width < 768px)
  final Widget Function(BuildContext, double) mobileBuilder;

  /// Builder para layout tablet (768 <= width < 1024px)
  /// Se não fornecido, usa mobileBuilder
  final Widget Function(BuildContext, double)? tabletBuilder;

  /// Builder para layout desktop (width >= 1024px)
  /// Se não fornecido, usa tabletBuilder ou mobileBuilder
  final Widget Function(BuildContext, double)? desktopBuilder;

  static const int breakpointMobile = 768;
  static const int breakpointTablet = 1024;

  const ResponsiveWidget({
    required this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Selecionar builder apropriado baseado em breakpoint
        if (width < breakpointMobile) {
          // Mobile
          return mobileBuilder(context, width);
        } else if (width < breakpointTablet) {
          // Tablet
          return (tabletBuilder ?? mobileBuilder)(context, width);
        } else {
          // Desktop
          return (desktopBuilder ?? tabletBuilder ?? mobileBuilder)(context, width);
        }
      },
    );
  }
}
