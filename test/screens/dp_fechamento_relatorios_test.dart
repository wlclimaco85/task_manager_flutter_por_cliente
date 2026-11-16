import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/dp_ponto_service.dart';
import 'package:task_manager_flutter/web/screens/dp_fechamento_empresa_screen.dart';
import 'package:task_manager_flutter/web/screens/dp_relatorios_ponto_screen.dart';

class _FakeService extends DpPontoService {
  _FakeService({this.fecharErro, this.relatorioErro, this.bloqueantes = 0});

  final DpPontoException? fecharErro;
  final DpPontoException? relatorioErro;
  final int bloqueantes;
  String status = 'ABERTO';
  final chamadas = <String>[];

  Map<String, dynamic> _previa() => {
        'status': status,
        'totalFuncionarios': 1,
        'totalBloqueantes': bloqueantes,
        'totalAvisos': 0,
        'podeFechar': bloqueantes == 0,
        'funcionarios': [
          {
            'funcionarioId': 1, 'nome': 'Ana Souza', 'setor': 'Vendas', 'situacao': bloqueantes > 0 ? 'BLOQUEADO' : 'OK',
            'normaisMin': 9600, 'he50Min': 150, 'he100Min': 0, 'noturnoMin': 0, 'atrasoMin': 20,
            'saidaAntecipadaMin': 0, 'faltaMin': 0, 'diasFalta': 0, 'dsrPerdidoDias': 0, 'saldoBancoMin': -65,
          }
        ],
        'pendencias': bloqueantes > 0
            ? [
                {'funcionario': 'Ana Souza', 'tipo': 'BATIDA_IMPAR', 'bloqueia': true, 'data': '2026-10-07', 'descricao': 'Número ímpar de batidas'}
              ]
            : [],
      };

  @override
  Future<List<Map<String, dynamic>>> competencias() async => [
        {'mes': 10, 'ano': 2026, 'status': status},
        {'mes': 9, 'ano': 2026, 'status': 'ABERTO'},
      ];

  @override
  Future<Map<String, dynamic>> previa(int mes, int ano) async => _previa();

  @override
  Future<Map<String, dynamic>> fechar(int mes, int ano, {bool forcar = false}) async {
    chamadas.add('fechar:$forcar');
    if (fecharErro != null && !forcar) throw fecharErro!;
    status = 'FECHADO';
    return _previa();
  }

  @override
  Future<Map<String, dynamic>> reabrir(int mes, int ano, String motivo) async {
    chamadas.add('reabrir:$motivo');
    status = 'ABERTO';
    return _previa();
  }

  @override
  Future<Map<String, dynamic>> relatorio(String tipo,
      {String? setorId, String? funcionarioId, required DateTime inicio, required DateTime fim}) async {
    chamadas.add('relatorio:$tipo:$setorId:$funcionarioId');
    if (relatorioErro != null) throw relatorioErro!;
    return {
      'tipo': tipo,
      'titulo': 'Resumo mensal',
      'subtitulo': 'Período',
      'colunas': ['Funcionário', 'Banco'],
      'linhas': tipo == 'ajustes'
          ? []
          : [
              ['Ana Souza', '-01:05']
            ],
      'totais': ['TOTAL', '-01:05'],
    };
  }

  @override
  Future<Uint8List> baixar(String tipo, String formato,
      {String? setorId, String? funcionarioId, required DateTime inicio, required DateTime fim}) async {
    chamadas.add('baixar:$tipo:$formato');
    throw DpPontoException('Você não tem permissão para esta ação.', statusCode: 403);
  }
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  test('formatarMinutos', () {
    expect(formatarMinutos(150), '02:30');
    expect(formatarMinutos(-65), '-01:05');
    expect(formatarMinutos(null), '00:00');
  });

  group('Fechamento da empresa', () {
    testWidgets('mostra a previa, fecha a competencia e permite reabrir com motivo', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final svc = _FakeService();
      await tester.pumpWidget(_app(DpFechamentoEmpresaScreen(service: svc)));
      await tester.pumpAndSettle();

      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('-01:05'), findsOneWidget); // saldo banco

      await tester.tap(find.byKey(const Key('dp_fechar')));
      await tester.pumpAndSettle();
      expect(svc.chamadas, ['fechar:false']);
      expect(find.byKey(const Key('dp_reabrir')), findsOneWidget);
      expect(find.text('FECHADA'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dp_reabrir')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'erro de lançamento');
      await tester.tap(find.text('Reabrir').last);
      await tester.pumpAndSettle();
      expect(svc.chamadas.last, 'reabrir:erro de lançamento');
      expect(find.byKey(const Key('dp_fechar')), findsOneWidget);
    });

    testWidgets('pendencia bloqueante (409) mostra a lista e so fecha apos confirmar', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final svc = _FakeService(
        bloqueantes: 1,
        fecharErro: DpPontoException('Existem 1 pendência(s) bloqueante(s)',
            statusCode: 409, previa: {
          'status': 'ABERTO', 'totalFuncionarios': 1, 'totalBloqueantes': 1, 'totalAvisos': 0, 'podeFechar': false,
          'funcionarios': [], 'pendencias': [],
        }),
      );
      await tester.pumpWidget(_app(DpFechamentoEmpresaScreen(service: svc)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dp_pendencias')), findsOneWidget);

      await tester.tap(find.byKey(const Key('dp_fechar')));
      await tester.pumpAndSettle();
      expect(find.text('Há pendências bloqueantes'), findsOneWidget);
      expect(svc.chamadas, ['fechar:false']);

      await tester.tap(find.text('Fechar mesmo assim'));
      await tester.pumpAndSettle();
      expect(svc.chamadas, ['fechar:false', 'fechar:true']);
    });

    testWidgets('sem permissao (403) mostra a mensagem de erro e nao quebra', (tester) async {
      final svc = _SemPermissao();
      await tester.pumpWidget(_app(DpFechamentoEmpresaScreen(service: svc)));
      await tester.pumpAndSettle();
      expect(find.text('Você não tem permissão para esta ação.'), findsOneWidget);
    });

    testWidgets('layout estreito (mobile) usa lista em vez de tabela', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_app(DpFechamentoEmpresaScreen(service: _FakeService())));
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsNothing);
      expect(find.byKey(const Key('dp_func_1')), findsOneWidget);
    });
  });

  group('Relatorios de ponto', () {
    Future<void> abrir(WidgetTester tester, _FakeService svc, {Size tela = const Size(1400, 1000)}) async {
      tester.view.physicalSize = tela;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_app(DpRelatoriosPontoScreen(
        service: svc,
        carregarSetores: () async => [{'id': 3, 'nome': 'Vendas'}],
        carregarFuncionarios: () async => [{'id': 1, 'nome': 'Ana Souza'}],
      )));
      await tester.pumpAndSettle();
    }

    testWidgets('gera o relatorio com os filtros e mostra tabela com totais', (tester) async {
      final svc = _FakeService();
      await abrir(tester, svc);

      await tester.tap(find.byKey(const Key('dp_setor')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vendas').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dp_gerar')));
      await tester.pumpAndSettle();

      expect(svc.chamadas, ['relatorio:resumo-mensal:3:null']);
      expect(find.byKey(const Key('dp_tabela')), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
    });

    testWidgets('relatorio sem linhas mostra estado vazio', (tester) async {
      final svc = _FakeService();
      await abrir(tester, svc);
      await tester.tap(find.byKey(const Key('dp_tipo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajustes de ponto').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dp_gerar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dp_vazio')), findsOneWidget);
    });

    testWidgets('erro do backend (403) aparece na tela e a exportacao negada mostra aviso', (tester) async {
      final svc = _FakeService(relatorioErro: DpPontoException('Você não tem permissão para esta ação.', statusCode: 403));
      await abrir(tester, svc);
      await tester.tap(find.byKey(const Key('dp_gerar')));
      await tester.pumpAndSettle();
      expect(find.text('Você não tem permissão para esta ação.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dp_pdf')));
      await tester.pumpAndSettle();
      expect(svc.chamadas.last, 'baixar:resumo-mensal:pdf');
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('layout estreito (mobile) mostra cartoes', (tester) async {
      final svc = _FakeService();
      await abrir(tester, svc, tela: const Size(400, 900));
      await tester.tap(find.byKey(const Key('dp_gerar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dp_cartoes')), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);
    });
  });
}

class _SemPermissao extends DpPontoService {
  @override
  Future<List<Map<String, dynamic>>> competencias() async =>
      throw DpPontoException('Você não tem permissão para esta ação.', statusCode: 403);
}
