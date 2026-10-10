import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/main.dart';

void main() {
  testWidgets('mostra loading enquanto carrega estado inicial', (tester) async {
    await tester.pumpWidget(const TaskManagerApp(loggedIn: null));

    expect(find.text('Carregando sistema'), findsOneWidget);
    expect(find.text('Gestão Empresarial'), findsWidgets);
  });
}
