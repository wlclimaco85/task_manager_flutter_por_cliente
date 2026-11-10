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
    final campoValor = tester.widget<TextField>(find.byType(TextField));
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
}
