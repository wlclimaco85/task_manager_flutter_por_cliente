import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renderiza branding Sereno e formulario de login no desktop',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Painel lateral sereno (Hero Branding)
    expect(find.text('Gestão Direta &\nConta Própria'), findsOneWidget);
    expect(find.text('Fluxo de Caixa e Extrato Unificado'), findsOneWidget);
    expect(find.text('Contas a Pagar e Receber Sem Fricção'), findsOneWidget);
    expect(find.text('Vendas e Emissão de Cupons/Notas'), findsOneWidget);

    // Campos do formulário
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('Informe seus dados de acesso para continuar'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.text('Entrar no Sistema'), findsOneWidget);
    expect(find.text('Cadastre sua Empresa'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'LoginScreen (desktop) renderiza sem exceptions em resoluções bem diferentes',
      (WidgetTester tester) async {
    for (final size in [const Size(1920, 1080), const Size(1024, 700)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull,
          reason: 'LoginScreen nao deve lancar exception em $size');
      expect(find.text('Gestão Direta &\nConta Própria'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
