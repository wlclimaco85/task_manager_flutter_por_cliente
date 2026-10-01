import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/core/theme/zen_theme.dart';

void main() {
  Widget buildTestApp() {
    return MaterialApp(
      theme: ZenTheme.lightTheme,
      home: const LoginScreen(),
    );
  }

  testWidgets('LoginScreen renders serene fields and actions on Mobile', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Gestão Conta Própria'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email e Senha
    expect(find.text('Entrar no Sistema'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.text('Cadastre sua Empresa'), findsOneWidget);
  });

  testWidgets('LoginScreen renders desktop branding and features on Desktop', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Gestão Direta &\nConta Própria'), findsOneWidget);
    expect(find.text('Fluxo de Caixa e Extrato Unificado'), findsOneWidget);
    expect(find.text('Contas a Pagar e Receber Sem Fricção'), findsOneWidget);
    expect(find.text('Vendas e Emissão de Cupons/Notas'), findsOneWidget);
    expect(find.text('Entrar no Sistema'), findsOneWidget);
  });

  testWidgets('LoginScreen validates empty inputs before submitting', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final entrarBtn = find.text('Entrar no Sistema');
    await tester.tap(entrarBtn);
    await tester.pumpAndSettle();

    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Informe sua senha'), findsOneWidget);
  });
}
