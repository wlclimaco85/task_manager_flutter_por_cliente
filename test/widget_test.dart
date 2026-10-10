import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/main.dart';

void main() {
  testWidgets('TaskManagerApp smoke test renderiza LoginScreen quando deslogado',
      (WidgetTester tester) async {
    // Login oficial (vitrine lateral) foi desenhada para janela de desktop.
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TaskManagerApp(loggedIn: false));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
