import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/widgets/importacao_boleto_pdf.dart';

void main() {
  tearDown(() => AuthUtility.userInfo = null);

  test('valorDeTexto aceita formato brasileiro e americano e recusa invalido/zero', () {
    expect(valorDeTexto('1.234,56'), 1234.56);
    expect(valorDeTexto('150,75'), 150.75);
    expect(valorDeTexto('150.75'), 150.75);
    expect(valorDeTexto(' R\$ 99,90 '), 99.9);
    expect(valorDeTexto(''), isNull);
    expect(valorDeTexto('0'), isNull);
    expect(valorDeTexto('abc'), isNull);
  });

  test('BoletoPreview.fromJson le os campos do backend e tem tributo como padrao', () {
    final p = BoletoPreview.fromJson({
      'tipoDocumento': 'BOLETO_FORNECEDOR',
      'valor': 150.75,
      'dataVencimento': '2026-12-10',
      'parceiroId': 7,
      'parceiroNome': 'Fornecedor X',
      'jaImportado': false,
    });
    expect(p.valor, 150.75);
    expect(p.vencimento, DateTime(2026, 12, 10));
    expect(p.parceiroId, 7);
    expect(p.tipoSugerido, kBoletoTipoTributo);
    expect(BoletoPreview.fromJson({}).tipoDocumento, 'DESCONHECIDO');
  });

  test('corpo da importacao leva descricao, data ISO, parceiro, empresa e tipo', () {
    final d = montarDadosImportacaoBoleto(
      empresaId: 10,
      parceiroId: 7,
      parceiroNome: 'Fornecedor X',
      valor: 150.75,
      vencimento: DateTime(2026, 12, 9),
      tipo: kBoletoTipoHonorarios,
    );
    expect(d, {
      'descricao': 'Boleto - Fornecedor X',
      'valor': 150.75,
      'dataVencimento': '2026-12-09',
      'empresaId': 10,
      'parceiroId': 7,
      'tipo': 'HONORARIOS',
    });
  });

  /// Abre o popup e devolve um acessor do resultado (preenchido quando o dialogo fecha).
  Future<Map<String, dynamic>? Function()> abrir(
      WidgetTester tester, BoletoPreview preview) async {
    AuthUtility.userInfo = LoginModel(
      token: 't',
      login: Login(id: 1, empresa: Empresa(id: 10)),
    );
    Map<String, dynamic>? resultado;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () async {
            resultado = await showDialog<Map<String, dynamic>>(
              context: ctx,
              builder: (_) =>
                  BoletoConfirmacaoDialog(nomeArquivo: 'b.pdf', preview: preview),
            );
          },
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return () => resultado;
  }

  BoletoPreview completo({bool jaImportado = false, String? aviso}) => BoletoPreview(
        tipoDocumento: 'BOLETO_FORNECEDOR',
        valor: 150.75,
        vencimento: DateTime(2026, 12, 10),
        parceiroId: 7,
        parceiroNome: 'Fornecedor X',
        jaImportado: jaImportado,
        aviso: aviso,
      );

  testWidgets('popup mostra cliente, valor e vencimento e vem com Tributo marcado',
      (tester) async {
    await abrir(tester, completo());

    expect(find.text('Confirmar importação do boleto'), findsOneWidget);
    expect(find.text('Fornecedor X'), findsOneWidget);
    expect(find.text('10/12/2026'), findsOneWidget);
    final campoValor = tester.widget<TextField>(find.byType(TextField).first);
    expect(campoValor.controller!.text, '150,75');
    final checks =
        tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile)).toList();
    expect(checks.map((c) => c.value), [true, false, false]); // Tributo, Honorarios, Outros
  });

  testWidgets('marcar Honorarios desmarca Tributo e confirma com o tipo escolhido',
      (tester) async {
    final resultado = await abrir(tester, completo());

    await tester.tap(find.text('Honorários'));
    await tester.pump();
    final checks =
        tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile)).toList();
    expect(checks.map((c) => c.value), [false, true, false]);

    await tester.tap(find.text('Confirmar e gerar conta'));
    await tester.pumpAndSettle();
    final dados = resultado();
    expect(dados, isNotNull);
    expect(dados!['tipo'], 'HONORARIOS');
    expect(dados['parceiroId'], 7);
    expect(dados['empresaId'], 10);
    expect(dados['valor'], 150.75);
    expect(dados['dataVencimento'], '2026-12-10');
  });

  testWidgets('cancelar nao devolve dados', (tester) async {
    final resultado = await abrir(tester, completo());
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(resultado(), isNull);
  });

  testWidgets('sem cliente/vencimento o botao Confirmar fica desabilitado e mostra o aviso',
      (tester) async {
    await abrir(
        tester,
        const BoletoPreview(
            tipoDocumento: 'DESCONHECIDO',
            aviso: 'Tipo de documento não reconhecido: confira os dados.'));

    expect(find.text('Não identificado'), findsOneWidget);
    expect(find.textContaining('não reconhecido'), findsOneWidget);
    final botao = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirmar e gerar conta'));
    expect(botao.onPressed, isNull);
  });

  testWidgets('titulo ja importado nao permite confirmar', (tester) async {
    await abrir(
        tester,
        completo(
            jaImportado: true,
            aviso: 'Já existe um título com estes dados: a importação será recusada.'));
    final botao = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirmar e gerar conta'));
    expect(botao.onPressed, isNull);
  });
  testWidgets('conta a receber: rotulo Cliente (pagador) e Honorarios sugerido marcado',
      (tester) async {
    AuthUtility.userInfo = LoginModel(
      token: 't',
      login: Login(id: 1, empresa: Empresa(id: 10)),
    );
    Map<String, dynamic>? resultado;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () async {
            resultado = await showDialog<Map<String, dynamic>>(
              context: ctx,
              builder: (_) => BoletoConfirmacaoDialog(
                nomeArquivo: 'b.pdf',
                receber: true,
                preview: BoletoPreview(
                  tipoDocumento: 'BOLETO_FORNECEDOR',
                  valor: 1500,
                  vencimento: DateTime(2026, 12, 10),
                  parceiroId: 7,
                  parceiroNome: 'Cliente Pagador',
                  tipoSugerido: kBoletoTipoHonorarios,
                ),
              ),
            );
          },
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Cliente (pagador)'), findsOneWidget);
    expect(find.text('Cliente Pagador'), findsOneWidget);
    final checks =
        tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile)).toList();
    expect(checks.map((c) => c.value), [false, true, false]); // Honorarios marcado

    await tester.tap(find.text('Confirmar e gerar conta'));
    await tester.pumpAndSettle();
    expect(resultado!['tipo'], 'HONORARIOS');
    expect(resultado!['parceiroId'], 7);
    expect(resultado!['valor'], 1500);
  });

  test('formatarDocumento formata CNPJ e CPF e devolve digitos nos outros casos', () {
    expect(formatarDocumento('63434696000184'), '63.434.696/0001-84');
    expect(formatarDocumento('12345678909'), '123.456.789-09');
    expect(formatarDocumento('123'), '123');
    expect(formatarDocumento(null), '');
  });

  test('cadastro do cliente: usa fantasia/razao da ReceitaWS e o documento so com digitos', () {
    final d = montarDadosCadastroClienteReceitaWs(
      documento: '63.434.696/0001-84',
      receita: {
        'nome': 'ACME COMERCIO LTDA',
        'nomeFantasia': 'Acme',
        'logradouro': 'Rua A',
        'numero': '10',
        'municipio': 'Uberaba',
        'uf': 'MG',
        'cep': '38000-000',
        'email': 'a@acme.com',
        'telefone': '(34) 3333-3333',
      },
      empresaId: 10,
      empresaNome: 'Abraco',
    );
    expect(d['cpf'], '63434696000184');
    expect(d['cnpj'], '63434696000184');
    expect(d['nome'], 'Acme');
    expect(d['razaoSocial'], 'ACME COMERCIO LTDA');
    expect(d['rua'], 'Rua A');
    expect(d['cidade'], 'Uberaba');
    expect(d['estado'], 'MG');
    expect(d['empresaId'], 10);
    expect(d['status'], 'ATIVO');
    // consulta falhou: so o documento, o resto em branco para preencher
    final vazio = montarDadosCadastroClienteReceitaWs(documento: '63434696000184');
    expect(vazio['nome'], '');
    expect(vazio['cnpj'], '63434696000184');
  });

  testWidgets('popup mostra o fornecedor e a observacao do boleto e envia a observacao',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final resultado = await abrir(
        tester,
        BoletoPreview(
          tipoDocumento: 'BOLETO_FORNECEDOR',
          valor: 150.75,
          vencimento: DateTime(2026, 12, 10),
          parceiroId: 7,
          parceiroNome: 'Cliente X',
          beneficiarioNome: 'Fornecedor X Ltda',
          beneficiarioDocumento: '12345678000195',
          numeroDocumento: 'NF-123',
          observacao: 'Não receber após o vencimento.',
        ));

    expect(find.text('Fornecedor / Beneficiário'), findsOneWidget);
    expect(find.text('Fornecedor X Ltda'), findsOneWidget);
    expect(find.text('12.345.678/0001-95'), findsOneWidget);
    expect(find.text('Doc. NF-123'), findsOneWidget);
    final campos = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(campos.any((c) => c.controller?.text == 'Não receber após o vencimento.'), isTrue);

    await tester.enterText(find.widgetWithText(TextField, 'Não receber após o vencimento.'),
        'Pagar até dia 9');
    await tester.tap(find.text('Confirmar e gerar conta'));
    await tester.pumpAndSettle();
    expect(resultado()!['observacao'], 'Pagar até dia 9');
  });

  testWidgets('sem fornecedor identificado avisa; observacao vazia nao vai no corpo', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final resultado = await abrir(tester, completo());
    expect(find.text('Não identificado no boleto'), findsOneWidget);
    await tester.tap(find.text('Confirmar e gerar conta'));
    await tester.pumpAndSettle();
    expect(resultado()!.containsKey('observacao'), isFalse);
  });

  testWidgets('cliente nao encontrado com CNPJ lido: oferece cadastrar pela ReceitaWS', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await abrir(
        tester,
        BoletoPreview(
          tipoDocumento: 'FGTS',
          valor: 178.31,
          vencimento: DateTime(2026, 11, 19),
          documento: '63434696000184',
          aviso: 'Cliente não identificado automaticamente',
        ));
    expect(find.text('Não identificado'), findsOneWidget);
    expect(find.text('Cadastrar 63.434.696/0001-84 (ReceitaWS)'), findsOneWidget);
  });

  testWidgets('cliente ja encontrado ou sem documento: nao mostra o botao de cadastrar', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await abrir(
        tester,
        BoletoPreview(
          tipoDocumento: 'BOLETO_FORNECEDOR',
          valor: 10,
          vencimento: DateTime(2026, 12, 10),
          parceiroId: 7,
          parceiroNome: 'X',
          documento: '63434696000184',
        ));
    expect(find.textContaining('(ReceitaWS)'), findsNothing);
  });
}
