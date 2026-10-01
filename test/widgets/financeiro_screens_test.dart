import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/theme/zen_theme.dart';
import 'package:task_manager_flutter/web/screens/conta_pagar_grid_screen.dart';
import 'package:task_manager_flutter/web/screens/conta_receber_grid_screen.dart';
import 'package:task_manager_flutter/web/screens/dre_screen.dart';

void main() {
  testWidgets('WebContaPagarGridScreen initializes with filters',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: ZenTheme.lightTheme,
        home: Scaffold(
          body: WebContaPagarGridScreen(hasPermission: (_) => true),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WebContaPagarGridScreen), findsOneWidget);
  });

  testWidgets('WebContaReceberGridScreen initializes with filters',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: ZenTheme.lightTheme,
        home: Scaffold(
          body: WebContaReceberGridScreen(hasPermission: (_) => true),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WebContaReceberGridScreen), findsOneWidget);
  });

  testWidgets('WebDreScreen initializes with period selector',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: ZenTheme.lightTheme,
        home: const Scaffold(
          body: WebDreScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WebDreScreen), findsOneWidget);
  });
}
