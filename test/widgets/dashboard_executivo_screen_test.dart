import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/theme/zen_theme.dart';
import 'package:task_manager_flutter/widgets/dashboard_executivo_screen.dart';

void main() {
  Widget buildTestApp({void Function(int screenIndex)? onNavigateToScreen}) {
    return MaterialApp(
      theme: ZenTheme.lightTheme,
      home: DashboardExecutivoScreen(
        onNavigateToScreen: onNavigateToScreen,
      ),
    );
  }

  testWidgets('DashboardExecutivoScreen renders header, quick actions and KPIs on desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Header
    expect(find.text('Conta Própria'), findsOneWidget);
    expect(
      find.text('Visão consolidada do fluxo de caixa e compromissos do negócio.'),
      findsOneWidget,
    );

    // Quick Actions
    expect(find.text('+ Nova Receita'), findsOneWidget);
    expect(find.text('+ Nova Despesa'), findsOneWidget);
    expect(find.text('+ Novo Contato'), findsOneWidget);
    expect(find.text('+ Nova Venda'), findsOneWidget);

    // Financial KPIs
    expect(find.text('Saldo em Caixa / Bancos'), findsOneWidget);
    expect(find.text('A Receber Hoje'), findsOneWidget);
    expect(find.text('A Pagar Hoje'), findsOneWidget);
    expect(find.text('Saldo Projetado'), findsOneWidget);

    // Chart and Upcoming Dues section
    expect(find.text('Fluxo Financeiro Semestral'), findsOneWidget);
    expect(find.text('Próximos Vencimentos'), findsOneWidget);
  });

  testWidgets('DashboardExecutivoScreen quick actions invoke onNavigateToScreen with correct indices',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final navigatedIndices = <int>[];
    await tester.pumpWidget(buildTestApp(
      onNavigateToScreen: (idx) => navigatedIndices.add(idx),
    ));
    await tester.pumpAndSettle();

    // Tap + Nova Receita -> index 26
    await tester.tap(find.text('+ Nova Receita'));
    await tester.pumpAndSettle();
    expect(navigatedIndices.last, 26);

    // Tap + Nova Despesa -> index 25
    await tester.tap(find.text('+ Nova Despesa'));
    await tester.pumpAndSettle();
    expect(navigatedIndices.last, 25);

    // Tap + Novo Contato -> index 19
    await tester.tap(find.text('+ Novo Contato'));
    await tester.pumpAndSettle();
    expect(navigatedIndices.last, 19);

    // Tap + Nova Venda -> index 95
    await tester.tap(find.text('+ Nova Venda'));
    await tester.pumpAndSettle();
    expect(navigatedIndices.last, 95);
  });

  testWidgets('DashboardExecutivoScreen renders responsively on mobile viewport',
      (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Conta Própria'), findsOneWidget);
    expect(find.text('+ Nova Receita'), findsOneWidget);
    expect(find.text('+ Nova Despesa'), findsOneWidget);
    expect(find.text('Saldo em Caixa / Bancos'), findsOneWidget);
  });
}
