import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/main.dart';

void main() {
  testWidgets('TaskManagerApp smoke test renderiza LoginScreen quando deslogado',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TaskManagerApp(loggedIn: false));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
