import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renderiza layout vertical nativo em resolucoes mobile',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
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

    // No mobile exibe 'Gestão Conta Própria' e o formulário vertical
    expect(find.text('Gestão Conta Própria'), findsOneWidget);
    expect(find.text('Acesse o painel executivo da sua empresa'), findsOneWidget);
    expect(find.text('Entrar no Sistema'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
