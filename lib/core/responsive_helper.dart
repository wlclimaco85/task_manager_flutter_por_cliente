import 'package:flutter/material.dart';

enum Breakpoint { mobile, tablet, desktop }

class ResponsiveHelper {
  /// Define os breakpoints em pixels
  static const int breakpointMobile = 768;
  static const int breakpointTablet = 1024;

  /// Retorna o breakpoint baseado na largura
  Breakpoint getBreakpoint(double width) {
    if (width < breakpointMobile) {
      return Breakpoint.mobile;
    } else if (width < breakpointTablet) {
      return Breakpoint.tablet;
    } else {
      return Breakpoint.desktop;
    }
  }

  /// Verifica se é mobile
  bool isMobile(double width) {
    return getBreakpoint(width) == Breakpoint.mobile;
  }

  /// Verifica se é tablet
  bool isTablet(double width) {
    return getBreakpoint(width) == Breakpoint.tablet;
  }

  /// Verifica se é desktop
  bool isDesktop(double width) {
    return getBreakpoint(width) == Breakpoint.desktop;
  }

  /// Retorna padding responsivo baseado na largura
  double paddingForBreakpoint(double width) {
    if (isMobile(width)) {
      return 8.0;
    } else if (isTablet(width)) {
      return 16.0;
    } else {
      return 24.0;
    }
  }

  /// Retorna tamanho de fonte escalado baseado na largura
  double fontSizeForBreakpoint(double width, double baseSize) {
    if (isMobile(width)) {
      return baseSize * 0.875; // 87.5% do tamanho base
    } else if (isTablet(width)) {
      return baseSize; // 100% do tamanho base
    } else {
      return baseSize * 1.125; // 112.5% do tamanho base
    }
  }
}
