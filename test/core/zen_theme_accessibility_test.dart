import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/theme/zen_theme.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';

double _luminance(Color color) {
  double channel(double c) {
    return (c <= 0.03928) ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(color.r);
  final g = channel(color.g);
  final b = channel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _luminance(c1);
  final l2 = _luminance(c2);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('ZenTheme & Serene Palette WCAG 2.1 AA Contrast Tests', () {
    test('Text Primary (#0F172A) on White background passes WCAG AAA (>= 7:1)', () {
      final ratio = _contrastRatio(GridColors.textPrimary, Colors.white);
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'Text Primary must have AAA contrast on white, got $ratio');
    });

    test('Primary Sage (#3E6B5C) on White background passes WCAG AA for UI/Large Text (>= 4.5:1)', () {
      final ratio = _contrastRatio(GridColors.primary, Colors.white);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Primary Sage must have AA contrast on white, got $ratio');
    });

    test('Primary Deep (#2D5246) on White background passes WCAG AAA (>= 7:1)', () {
      final ratio = _contrastRatio(GridColors.primaryDark, Colors.white);
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'Deep Sage must exceed AAA contrast on white, got $ratio');
    });

    test('White text on Primary Sage (#3E6B5C) passes WCAG AA (>= 4.5:1)', () {
      final ratio = _contrastRatio(Colors.white, GridColors.primary);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Button labels on Primary must have AA contrast, got $ratio');
    });

    test('White text on Sidebar Shell (#2D5246) passes WCAG AAA (>= 7:1)', () {
      final ratio = _contrastRatio(Colors.white, GridColors.shellBackground);
      expect(ratio, greaterThanOrEqualTo(7.0),
          reason: 'Sidebar text on deep sage must have AAA contrast, got $ratio');
    });

    test('Error Velvet Rose (#E11D48) on White background passes WCAG AA (>= 4.5:1)', () {
      final ratio = _contrastRatio(GridColors.error, Colors.white);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'Error color must have AA contrast on white, got $ratio');
    });

    test('ZenTheme produces complete and valid light theme with anti-anxiety background', () {
      final theme = ZenTheme.lightTheme;
      expect(theme.scaffoldBackgroundColor, GridColors.background);
      expect(theme.primaryColor, GridColors.primary);
      expect(theme.cardTheme.color, Colors.white);
      expect(theme.useMaterial3, isTrue);
    });
  });
}
