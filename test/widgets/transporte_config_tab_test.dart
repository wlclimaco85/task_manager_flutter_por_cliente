import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/transporte_config_tab.dart';

void main() {
  testWidgets('sem parceiro salvo mostra aviso e nao chama a rede',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TransporteConfigTab(parceiroId: 0)),
    ));
    await tester.pump();

    expect(find.text('ID do parceiro não disponível'), findsOneWidget);
    expect(find.text('Salvar'), findsNothing);
  });

  test('opcoes de emitente/transportador seguem o esquema do MDF-e', () {
    expect(kTransporteTiposEmitente.map((o) => o['value']), [1, 2, 3]);
    expect(kTransporteTiposTransportador.map((o) => o['value']), [1, 2, 3]);
  });
}
