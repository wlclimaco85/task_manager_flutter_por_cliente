import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/web_home_responsiva.dart';

Future<void> _montar(WidgetTester tester, double largura) async {
  tester.view.physicalSize = Size(largura, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: WebHomeResponsiva(
      mobileBuilder: (_) => const Text('LAYOUT_MOBILE'),
      webBuilder: (_) => const Text('LAYOUT_WEB'),
    ),
  ));
}

void main() {
  test('limite e 599 px inclusive', () {
    expect(WebHomeResponsiva.usaLayoutMobile(599), isTrue);
    expect(WebHomeResponsiva.usaLayoutMobile(375), isTrue);
    expect(WebHomeResponsiva.usaLayoutMobile(600), isFalse);
  });

  testWidgets('tela de celular (375 px) usa o layout mobile', (tester) async {
    await _montar(tester, 375);
    expect(find.text('LAYOUT_MOBILE'), findsOneWidget);
    expect(find.text('LAYOUT_WEB'), findsNothing);
  });

  testWidgets('599 px ainda e mobile e 600 px ja e web', (tester) async {
    await _montar(tester, 599);
    expect(find.text('LAYOUT_MOBILE'), findsOneWidget);
    await _montar(tester, 600);
    expect(find.text('LAYOUT_WEB'), findsOneWidget);
  });

  testWidgets('desktop (1400 px) usa o layout web', (tester) async {
    await _montar(tester, 1400);
    expect(find.text('LAYOUT_WEB'), findsOneWidget);
  });
}
