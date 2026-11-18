import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/web/screens/nfe_grid_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('NF-e entrada oferece a acao Devolver NF-e ao lado de Aceitar/Recusar', (tester) async {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('A RenderFlex overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WebNfeGridScreen(entrada: true))),
    );
    await tester.pump();

    final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
      find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>),
    );
    final rotulos = grid.customActions!().map((a) => a.label).toList();

    expect(rotulos, containsAllInOrder(['Aceitar', 'Recusar', 'Devolver NF-e', 'DANFE', 'XML']));
  });
}
