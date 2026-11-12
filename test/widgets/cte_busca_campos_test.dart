import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/cte_busca_campos.dart';
import 'package:task_manager_flutter/widgets/cte_emissao_view.dart';

void main() {
  group('parteDoParceiro', () {
    test('preenche documento, nome, endereco e municipio do cadastro', () {
      final d = parteDoParceiro({
        'cpf': '12.345.678/0001-95',
        'nome': 'Fantasia',
        'razaoSocial': 'Razao LTDA',
        'ie': '123',
        'telefone1': '(31) 3333-4444',
        'endereco': {
          'rua': 'Rua A',
          'numero': '10',
          'bairro': 'Centro',
          'cep': '30110-000',
          'cidade': {'ibge': '3106200', 'nome': 'Belo Horizonte'},
          'estado': {'uf': 'MG'},
        },
      });
      expect(d.documento, '12345678000195');
      expect(d.nome, 'Razao LTDA');
      expect(d.cep, '30110000');
      expect(d.logradouro, 'Rua A');
      expect(d.ibge, '3106200');
      expect(d.municipio, 'Belo Horizonte');
      expect(d.uf, 'MG');
    });

    test('cadastro sem endereco deixa os campos vazios (ficam editaveis)', () {
      final d = parteDoParceiro({'nome': 'So nome', 'cpf': '12345678901'});
      expect(d.nome, 'So nome');
      expect(d.logradouro, isEmpty);
      expect(d.ibge, isEmpty);
      expect(d.municipio, isEmpty);
    });

    test('IBGE invalido nao e aproveitado', () {
      final d = parteDoParceiro({
        'nome': 'X',
        'endereco': {
          'cidade': {'ibge': '31', 'nome': 'BH'}
        }
      });
      expect(d.ibge, isEmpty);
      expect(d.municipio, isEmpty);
    });
  });

  group('calcularCargaCte', () {
    Map<String, dynamic> item(String d, num q, num v, {bool servico = false}) =>
        {'descricao': d, 'quantidade': q, 'valor': v, 'isServico': servico};

    test('soma so itens que nao sao servico e escolhe o de maior quantidade', () {
      final r = calcularCargaCte([
        {
          'itens': [item('ARROZ', 10, 100), item('FRETE', 1, 50, servico: true)]
        },
        {
          'itens': [item('FEIJAO', 3, 30), item('ARROZ', 5, 60)]
        },
      ]);
      expect(r.valor, 190); // 100 + 30 + 60 (o servico fica fora)
      expect(r.produto, 'ARROZ'); // 10 + 5 = 15 > 3
    });

    test('so servicos: valor zero e sem produto predominante', () {
      final r = calcularCargaCte([
        {
          'itens': [item('FRETE', 1, 50, servico: true)]
        }
      ]);
      expect(r.valor, 0);
      expect(r.produto, isNull);
    });

    test('lista vazia', () {
      final r = calcularCargaCte([]);
      expect(r.valor, 0);
      expect(r.produto, isNull);
    });
  });

  group('formulario do CT-e', () {
    Future<void> abrir(WidgetTester t) async {
      final erros = <FlutterErrorDetails>[];
      final antigo = FlutterError.onError;
      FlutterError.onError = (d) => erros.add(d);
      addTearDown(() => FlutterError.onError = antigo);
      t.view.physicalSize = const Size(1400, 900);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(home: cteFormPageParaTeste()));
    }

    testWidgets('aba Partes: busca de parceiro e CEP com botao de busca', (t) async {
      await abrir(t);
      await t.tap(find.text('3. Partes'));
      await t.pumpAndSettle();
      expect(find.text('Parceiro (buscar cadastro)'), findsWidgets);
      expect(find.byTooltip('Buscar CEP'), findsWidgets);
      // CEP vem antes do logradouro no endereco
      final cep = t.getTopLeft(find.widgetWithText(TextFormField, 'CEP (opcional)').first);
      final logr = t.getTopLeft(find.widgetWithText(TextFormField, 'Logradouro').first);
      expect(cep.dy < logr.dy || (cep.dy == logr.dy && cep.dx < logr.dx), isTrue);
    });

    testWidgets('aba Valores: busca de servico; aba Carga: busca de NF-e cadastradas', (t) async {
      await abrir(t);
      await t.tap(find.text('4. Valores e impostos'));
      await t.pumpAndSettle();
      expect(find.text('Serviço (buscar cadastro)'), findsOneWidget);
      await t.tap(find.text('5. Carga e documentos'));
      await t.pumpAndSettle();
      expect(find.text('Buscar NF-e cadastradas'), findsOneWidget);
    });

    testWidgets('buscar NF-e sem chave informa o motivo', (t) async {
      await abrir(t);
      await t.tap(find.text('5. Carga e documentos'));
      await t.pumpAndSettle();
      await t.tap(find.text('Buscar NF-e cadastradas'));
      await t.pumpAndSettle();
      expect(find.text('Informe ao menos uma chave ou número de NF-e.'), findsOneWidget);
    });

    testWidgets('sem overflow nos dropdowns da aba Dados gerais', (t) async {
      final erros = <FlutterErrorDetails>[];
      final antigo = FlutterError.onError;
      FlutterError.onError = (d) => erros.add(d);
      addTearDown(() => FlutterError.onError = antigo);
      t.view.physicalSize = const Size(1400, 900);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(home: cteFormPageParaTeste()));
      await t.pumpAndSettle();
      expect(erros.where((e) => e.exceptionAsString().contains('overflowed')), isEmpty);
    });
  });

  group('resolverNumerosNfe', () {
    const chave = '35260112345678000190550010000001231000001234';

    test('troca numero de NF-e pela chave e mantem as chaves de 44 digitos', () async {
      final r = await resolverNumerosNfe('123\n$chave', buscar: (n) async => [
            {'chave': chave, 'numero': n}
          ]);
      expect(r.texto, '$chave\n$chave');
      expect(r.avisos, isEmpty);
    });

    test('numero sem cadastro, com erro ou com varias NF-e fica no texto e gera aviso', () async {
      final r = await resolverNumerosNfe('1 2 3', buscar: (n) async {
        if (n == '1') return [];
        if (n == '2') return null;
        return [
          {'chave': 'A'},
          {'chave': 'B'}
        ];
      });
      expect(r.texto, '1\n2\n3');
      expect(r.avisos, hasLength(3));
      expect(r.avisos.last, contains('A, B'));
    });
  });
}
