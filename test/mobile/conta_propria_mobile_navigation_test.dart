import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/theme/zen_theme.dart';
import 'package:task_manager_flutter/mobile/screens/bottom_navbar_screen.dart';
import 'package:task_manager_flutter/widgets/dashboard_executivo_screen.dart';

void main() {
  testWidgets('Mobile BottomNavBarScreen renders 5 Conta Própria slots',
      (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final origDebugPrint = debugPrint;
    addTearDown(() => debugPrint = origDebugPrint);
    final origOnError = FlutterError.onError;
    addTearDown(() => FlutterError.onError = origOnError);

    await tester.pumpWidget(
      MaterialApp(
        theme: ZenTheme.lightTheme,
        home: const BottomNavBarScreen(),
      ),
    );
    await tester.pump();

    // Verify 5 slots
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Financeiro'), findsOneWidget);
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.text('Contatos'), findsOneWidget);
    expect(find.text('Mais'), findsOneWidget);

    // Initial screen should be DashboardExecutivoScreen
    expect(find.byType(DashboardExecutivoScreen), findsOneWidget);
  });
}
