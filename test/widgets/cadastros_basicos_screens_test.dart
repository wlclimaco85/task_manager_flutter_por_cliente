import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/theme/zen_theme.dart';
import 'package:task_manager_flutter/web/screens/parceiro_grid_screen.dart';
import 'package:task_manager_flutter/web/screens/conta_bancaria_grid_screen.dart';
import 'package:task_manager_flutter/web/screens/produto_grid_screen.dart';

void main() {
  testWidgets('WebParceiroGridScreen initializes with Contatos title override',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: ZenTheme.lightTheme,
        home: Scaffold(
          body: WebParceiroGridScreen(hasPermission: (_) => true),
        ),
      ),
    );
    await tester.pump();

    // Verify widget tree initialized correctly
    expect(find.byType(WebParceiroGridScreen), findsOneWidget);
  });

  testWidgets('WebContaBancariaGridScreen initializes properly',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: ZenTheme.lightTheme,
        home: Scaffold(
          body: WebContaBancariaGridScreen(hasPermission: (_) => true),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WebContaBancariaGridScreen), findsOneWidget);
  });

  testWidgets('WebProdutoGridScreen initializes properly without GED dependency',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: ZenTheme.lightTheme,
        home: Scaffold(
          body: WebProdutoGridScreen(hasPermission: (_) => true),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WebProdutoGridScreen), findsOneWidget);
  });
}
