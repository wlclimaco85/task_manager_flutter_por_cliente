import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/dp_ponto_extras_screens.dart';
import 'package:task_manager_flutter/services/dp_ponto_service.dart';
import 'package:task_manager_flutter/web/screens/dp_banco_horas_screen.dart';
import 'package:task_manager_flutter/web/screens/dp_espelho_assinatura_screen.dart';
import 'package:task_manager_flutter/web/screens/dp_pendencias_screen.dart';

class _FakeService extends DpPontoService {
  _FakeService({this.aceiteErro, this.quitarErro, this.status = 'ABERTO'});

  final DpPontoException? aceiteErro;
  final DpPontoException? quitarErro;
  String status;
  final chamadas = <String>[];

  @override
  Future<List<Map<String, dynamic>>> funcionarios() async => [
        {'id': 10, 'nome': 'Maria Souza'},
      ];

  @override
  Future<Map<String, dynamic>> estadoAssinatura(int funcionarioId, int mes, int ano) async => {
        'funcionarioId': funcionarioId, 'nome': 'Maria Souza', 'mes': mes, 'ano': ano, 'status': status,
        'inconsistencias': 0,
        if (status != 'ABERTO') ...{
          'dhAceite': '2026-10-02T09:30:00', 'aceiteIp': '203.0.113.9', 'hashAceite': 'a' * 64, 'aceiteConfere': true,
        },
      };

  @override
  Future<Map<String, dynamic>> aceitarEspelho(int funcionarioId, int mes, int ano) async {
    chamadas.add('aceitar:$funcionarioId');
    if (aceiteErro != null) throw aceiteErro!;
    status = 'ACEITO_FUNC';
    return estadoAssinatura(funcionarioId, mes, ano);
  }

  @override
  Future<Map<String, dynamic>> validarEspelho(int funcionarioId, int mes, int ano, {String? justificativa}) async {
    chamadas.add('validar:$justificativa');
    status = 'FECHADO';
    return estadoAssinatura(funcionarioId, mes, ano);
  }

  @override
  Future<List<Map<String, dynamic>>> alertasBanco() async => [
        {'funcionarioId': 10, 'nome': 'Maria Souza', 'vencidoMin': 120, 'vencendoMin': 60, 'primeiroVencimento': '2026-06-30'},
      ];

  @override
  Future<Map<String, dynamic>> extratoBanco(int funcionarioId) async => {
        'funcionarioId': funcionarioId, 'nome': 'Maria Souza', 'prazoMeses': 6, 'acordo': 'INDIVIDUAL', 'bancoAtivo': true,
        'extrato': {
          'saldo': 180, 'vencido': 120, 'vencendo': 60, 'aVencer': 0, 'devedor': 0,
          'linhas': [
            {'competencia': '2026-01', 'credito': 120, 'debito': 0, 'quitado': 0, 'saldoAcumulado': 120},
            {'competencia': '2026-02', 'credito': 60, 'debito': 0, 'quitado': 0, 'saldoAcumulado': 180},
          ],
          'lotes': [
            {'competencia': '2026-01', 'minutos': 120, 'vencimento': '2026-06-30', 'situacao': 'VENCIDO'},
            {'competencia': '2026-02', 'minutos': 60, 'vencimento': '2026-07-31', 'situacao': 'VENCENDO'},
          ],
        },
      };

  @override
  Future<Map<String, dynamic>> quitarBanco(int funcionarioId, int folhaMes, int folhaAno,
      {int? minutos, String? observacao}) async {
    chamadas.add('quitar:$funcionarioId:$minutos');
    if (quitarErro != null) throw quitarErro!;
    return {'minutos': 120};
  }

  @override
  Future<Map<String, dynamic>> pendencias() async => {
        'total': 2,
        'espelhosSemAceite': [
          {'funcionarioId': 10, 'funcionario': 'Maria Souza', 'referencia': '10/2026', 'detalhe': 'Espelho sem aceite do funcionário'},
        ],
        'ajustesPendentes': [],
        'feriasPendentes': [
          {'funcionarioId': 11, 'funcionario': 'João', 'referencia': '2027-01-04 a 2027-01-18', 'detalhe': 'Solicitação de férias aguardando resposta'},
        ],
        'bancoHoras': [],
      };

  @override
  Future<int> notificarPendencias() async {
    chamadas.add('notificar');
    return 3;
  }
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void _tela(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _selecionarFuncionario(WidgetTester tester, Key chave) async {
  await tester.tap(find.byKey(chave));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Maria Souza').last);
  await tester.pumpAndSettle();
}

void main() {
  group('Assinatura do espelho', () {
    testWidgets('funcionario assina: chama o aceite e mostra IP e hash', (tester) async {
      _tela(tester);
      final svc = _FakeService();
      await tester.pumpWidget(_app(DpEspelhoAssinaturaScreen(service: svc)));
      await tester.pumpAndSettle();
      await _selecionarFuncionario(tester, const Key('dp_assin_funcionario'));

      expect(find.text('Aguardando assinatura do funcionário'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dp_assinar')));
      await tester.pumpAndSettle();

      expect(svc.chamadas, ['aceitar:10']);
      expect(find.text('Assinado pelo funcionário'), findsOneWidget);
      expect(find.textContaining('203.0.113.9'), findsOneWidget);
    });

    testWidgets('erro do backend (outro login) aparece na tela e nada muda', (tester) async {
      _tela(tester);
      final svc = _FakeService(aceiteErro: DpPontoException('Somente o próprio funcionário pode assinar o seu espelho de ponto.', statusCode: 403));
      await tester.pumpWidget(_app(DpEspelhoAssinaturaScreen(service: svc)));
      await tester.pumpAndSettle();
      await _selecionarFuncionario(tester, const Key('dp_assin_funcionario'));

      await tester.tap(find.byKey(const Key('dp_assinar')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Somente o próprio funcionário'), findsOneWidget);
      expect(find.text('Aguardando assinatura do funcionário'), findsOneWidget);
    });

    testWidgets('gestor sem aceite precisa informar justificativa para fechar', (tester) async {
      _tela(tester);
      final svc = _FakeService();
      await tester.pumpWidget(_app(DpEspelhoAssinaturaScreen(service: svc)));
      await tester.pumpAndSettle();
      await _selecionarFuncionario(tester, const Key('dp_assin_funcionario'));

      await tester.tap(find.byKey(const Key('dp_validar')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('dp_justificativa')), 'Funcionário em férias');
      await tester.tap(find.text('Fechar espelho'));
      await tester.pumpAndSettle();

      expect(svc.chamadas, ['validar:Funcionário em férias']);
      expect(find.text('Fechado e validado pelo gestor'), findsOneWidget);
    });

    testWidgets('com aceite vigente o gestor fecha sem justificativa', (tester) async {
      _tela(tester);
      final svc = _FakeService(status: 'ACEITO_FUNC');
      await tester.pumpWidget(_app(DpEspelhoAssinaturaScreen(service: svc)));
      await tester.pumpAndSettle();
      await _selecionarFuncionario(tester, const Key('dp_assin_funcionario'));

      await tester.tap(find.byKey(const Key('dp_validar')));
      await tester.pumpAndSettle();

      expect(svc.chamadas, ['validar:null']);
    });
  });

  group('Banco de horas', () {
    testWidgets('mostra alerta, saldo vencido e extrato', (tester) async {
      _tela(tester);
      final svc = _FakeService();
      await tester.pumpWidget(_app(DpBancoHorasScreen(service: svc)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dp_banco_alertas')), findsOneWidget);

      await _selecionarFuncionario(tester, const Key('dp_banco_funcionario'));

      expect(find.text('03:00'), findsWidgets); // saldo 180 min
      expect(find.text('02:00'), findsWidgets); // vencido 120 min
      expect(find.textContaining('compensação em até 6 meses'), findsOneWidget);
    });

    testWidgets('quitar vencido chama a API com a folha do mes e atualiza', (tester) async {
      _tela(tester);
      final svc = _FakeService();
      await tester.pumpWidget(_app(DpBancoHorasScreen(service: svc)));
      await tester.pumpAndSettle();
      await _selecionarFuncionario(tester, const Key('dp_banco_funcionario'));

      await tester.tap(find.byKey(const Key('dp_quitar')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar').last);
      await tester.pumpAndSettle();

      expect(svc.chamadas, ['quitar:10:null']);
    });

    testWidgets('erro ao quitar mostra a mensagem do backend', (tester) async {
      _tela(tester);
      final svc = _FakeService(quitarErro: DpPontoException('A folha 11/2026 já está fechada: quite na próxima competência.', statusCode: 409));
      await tester.pumpWidget(_app(DpBancoHorasScreen(service: svc)));
      await tester.pumpAndSettle();
      await _selecionarFuncionario(tester, const Key('dp_banco_funcionario'));

      await tester.tap(find.byKey(const Key('dp_quitar')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('já está fechada'), findsOneWidget);
    });
  });

  group('Pendencias do DP', () {
    testWidgets('lista por categoria e dispara os avisos', (tester) async {
      _tela(tester);
      final svc = _FakeService();
      await tester.pumpWidget(_app(DpPendenciasScreen(service: svc)));
      await tester.pumpAndSettle();

      expect(find.text('2 pendência(s)'), findsOneWidget);
      expect(find.textContaining('Espelhos sem aceite do funcionário (1)'), findsOneWidget);
      expect(find.textContaining('Solicitações de férias aguardando resposta (1)'), findsOneWidget);
      expect(find.text('Maria Souza · 10/2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dp_notificar')));
      await tester.pumpAndSettle();
      expect(svc.chamadas, ['notificar']);
      expect(find.text('3 alerta(s) enviado(s).'), findsOneWidget);
    });
  });

  test('wrappers mobile existem para as tres telas (paridade Web/Windows/Mobile)', () {
    expect(const MobileDpEspelhoAssinaturaScreen(), isA<StatelessWidget>());
    expect(const MobileDpBancoHorasScreen(), isA<StatelessWidget>());
    expect(const MobileDpPendenciasScreen(), isA<StatelessWidget>());
  });
}
