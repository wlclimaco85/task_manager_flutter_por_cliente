import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/dp_exportacao_folha_service.dart';
import 'package:task_manager_flutter/widgets/dp/dp_exportacao_folha_screen.dart';

class _Fake extends DpExportacaoFolhaService {
  _Fake({this.erro});
  final List<String>? erro;
  int gerados = 0;

  @override
  Future<List<DpMapeamentoLinha>> carregarMapeamento(int empId) async => [
        DpMapeamentoLinha(eventoPonto: 'HE50', descricao: 'Hora extra 50%', unidade: 'HORAS', codigoEvento: '50'),
        DpMapeamentoLinha(eventoPonto: 'FALTAS', descricao: 'Faltas (dias)', unidade: 'DIAS'),
      ];

  @override
  Future<DpExportacaoArquivo> gerar(
      {required int empId, required String competencia, required String layout, String? codEmpresa}) async {
    gerados++;
    if (erro != null) throw DpExportacaoErro(erro!);
    return DpExportacaoArquivo('folha_$layout.txt', Uint8List(0), 3, 1);
  }
}

void main() {
  testWidgets('mostra mapeamento e gera arquivo com aviso', (tester) async {
    final fake = _Fake();
    DpExportacaoArquivo? salvo;
    await tester.pumpWidget(MaterialApp(
        home: DpExportacaoFolhaScreen(service: fake, empresaId: 7, salvarArquivo: (a) async => salvo = a)));
    await tester.pumpAndSettle();

    expect(find.text('Hora extra 50%'), findsNothing); // rotulo traz a unidade na mesma Text
    expect(find.textContaining('Hora extra 50%'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('dpExpGerar')));
    await tester.tap(find.byKey(const Key('dpExpGerar')));
    await tester.pumpAndSettle();

    expect(fake.gerados, 1);
    expect(salvo?.nome, 'folha_dominio.txt');
    expect(find.byKey(const Key('dpExpAviso'), skipOffstage: false), findsOneWidget);
    expect(find.textContaining('1 funcionário(s) com ponto ainda não fechado', skipOffstage: false), findsOneWidget);
  });

  testWidgets('exibe todos os erros de validacao do backend', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: DpExportacaoFolhaScreen(service: _Fake(erro: ['Sem mapeamento X', 'CPF obrigatorio']), empresaId: 7)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('dpExpGerar')));
    await tester.tap(find.byKey(const Key('dpExpGerar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dpExpErros'), skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Sem mapeamento X', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('CPF obrigatorio', skipOffstage: false), findsOneWidget);
  });
}