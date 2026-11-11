import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/login_modulos_vitrine.dart';

Future<void> _pump(WidgetTester tester,
    Future<List<Map<String, dynamic>>> Function() carregar) async {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: LoginModulosVitrine(maxWidth: 1000, carregar: carregar),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('lista os modulos pagos cadastrados no Painel do Dono',
      (tester) async {
    await _pump(
      tester,
      () async => [
        {'nome': 'NFS-e', 'descricao': 'Nota de servico', 'valorMensal': 49.9},
        {'nome': 'Estoque e giro', 'descricao': 'Controle de estoque'},
      ],
    );
    expect(find.text('Já vem no sistema'), findsOneWidget);
    expect(find.text('Módulos que podem ser contratados'), findsOneWidget);
    expect(find.text('NFS-e'), findsOneWidget);
    expect(find.text('Estoque e giro'), findsOneWidget);
    expect(find.text('Opcional'), findsNWidgets(2));
    expect(find.text('R\$ 49,90/mês'), findsOneWidget);
  });

  testWidgets('sem modulos pagos (erro ou lista vazia) nao exibe a secao paga',
      (tester) async {
    await _pump(tester, () async => throw Exception('sem rede'));
    expect(find.text('Já vem no sistema'), findsOneWidget);
    expect(find.text('Módulos que podem ser contratados'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('icone por palavra-chave do nome do modulo', () {
    expect(iconeParaModulo('NFC-e'), Icons.point_of_sale_outlined);
    expect(iconeParaModulo('Modulo Novo'), Icons.extension_outlined);
  });
}
