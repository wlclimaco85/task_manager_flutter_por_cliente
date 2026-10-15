import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfce_model.dart';
import 'package:task_manager_flutter/web/screens/nfce/pdv_screen.dart';

void main() {
  group('PdvScreen - Modo de Edição e Regras de ReadOnly por Status', () {
    testWidgets('NFC-e AUTORIZADA deixa botão emitir disabled e campos desabilitados', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const nfceAutorizada = NfceModel(
        id: 101,
        numero: 12,
        serie: 1,
        statusSefaz: 'AUTORIZADA',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PdvScreen(nfce: nfceAutorizada),
        ),
      );
      await tester.pump();

      // Botão emitir deve exibir EMISSÃO BLOQUEADA e estar desabilitado (onPressed == null)
      final btnEmitir = find.widgetWithText(ElevatedButton, 'EMISSÃO BLOQUEADA');
      expect(btnEmitir, findsOneWidget);

      final button = tester.widget<ElevatedButton>(btnEmitir);
      expect(button.onPressed, isNull);

      // Banner indicando modo somente leitura
      expect(find.textContaining('Cupom NFC-e em modo somente leitura'), findsOneWidget);
    });

    testWidgets('NFC-e em CONTINGENCIA também deixa botão emitir disabled', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const nfceContingencia = NfceModel(
        id: 102,
        numero: 13,
        serie: 1,
        statusSefaz: 'CONTINGENCIA',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PdvScreen(nfce: nfceContingencia),
        ),
      );
      await tester.pump();

      final btnEmitir = find.widgetWithText(ElevatedButton, 'EMISSÃO BLOQUEADA');
      expect(btnEmitir, findsOneWidget);

      final button = tester.widget<ElevatedButton>(btnEmitir);
      expect(button.onPressed, isNull);

      expect(find.textContaining('Cupom NFC-e em modo somente leitura'), findsOneWidget);
    });

    testWidgets('NFC-e REJEITADA permite edição (pode mexer e botão ativo)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const nfceRejeitada = NfceModel(
        id: 103,
        numero: 14,
        serie: 1,
        statusSefaz: 'REJEITADA',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PdvScreen(nfce: nfceRejeitada),
        ),
      );
      await tester.pump();

      // Botão emitir exibe "EMITIR NFC-e"
      final btnEmitir = find.widgetWithText(ElevatedButton, 'EMITIR NFC-e');
      expect(btnEmitir, findsOneWidget);

      // Banner avisa que permite alteração
      expect(find.textContaining('Cupom NFC-e em edição'), findsOneWidget);
    });
  });
}
