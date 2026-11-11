import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/localidade_busca_field.dart';

void main() {
  testWidgets('municipio e obrigatorio: sem IBGE de 7 digitos o form nao valida', (t) async {
    final ibge = TextEditingController();
    final nome = TextEditingController();
    final chave = GlobalKey<FormState>();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: chave,
          child: MunicipioBuscaField(label: 'Município de origem', ibge: ibge, nome: nome),
        ),
      ),
    ));
    expect(chave.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('Selecione o município'), findsOneWidget);

    ibge.text = '3170107';
    nome.text = 'Uberaba';
    await t.pump();
    expect(chave.currentState!.validate(), isTrue);
  });

  testWidgets('municipio opcional nao exige selecao', (t) async {
    final chave = GlobalKey<FormState>();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: chave,
          child: MunicipioBuscaField(
              label: 'Município',
              ibge: TextEditingController(),
              nome: TextEditingController(),
              obrigatorio: false),
        ),
      ),
    ));
    expect(chave.currentState!.validate(), isTrue);
  });
}
