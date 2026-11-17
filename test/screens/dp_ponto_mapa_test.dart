import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/dp_ponto_extras_screens.dart';
import 'package:task_manager_flutter/services/dp_ponto_service.dart';
import 'package:task_manager_flutter/services/localizacao_ponto.dart';
import 'package:task_manager_flutter/services/ponto_service.dart';
import 'package:task_manager_flutter/web/screens/dp_ponto_mapa_screen.dart';

class _FakeService extends DpPontoService {
  _FakeService({this.decidirErro});

  final DpPontoException? decidirErro;
  final chamadas = <String>[];

  @override
  Future<Map<String, dynamic>> mapaPontos(DateTime inicio, DateTime fim, {String? status, String? funcionarioId}) async {
    chamadas.add('mapa:$status');
    return {
      'pendentes': 1,
      'centros': [
        {'tipo': 'EMPRESA', 'id': 1, 'nome': 'Padaria', 'latitude': -23.5503, 'longitude': -46.6340, 'raioKm': 1.0},
      ],
      'pontos': [
        {
          'pontoId': 500, 'funcionarioId': 10, 'funcionario': 'Maria Souza', 'dataHora': '2026-11-16T08:00:00',
          'latitude': -23.5503, 'longitude': -46.6140, 'distanciaKm': 2.04, 'raioKm': 1.0, 'status': 'PENDENTE',
          'referencia': 'Padaria', 'refLatitude': -23.5503, 'refLongitude': -46.6340, 'motivo': null,
        },
        {
          'pontoId': 501, 'funcionarioId': 11, 'funcionario': 'João', 'dataHora': '2026-11-16T08:05:00',
          'latitude': -23.5505, 'longitude': -46.6335, 'distanciaKm': 0.06, 'raioKm': 1.0, 'status': 'DENTRO',
          'referencia': 'Padaria', 'refLatitude': -23.5503, 'refLongitude': -46.6340, 'motivo': null,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> decidirPonto(int pontoId, bool aprovar, {String? motivo}) async {
    chamadas.add('decidir:$pontoId:$aprovar:$motivo');
    if (decidirErro != null) throw decidirErro!;
    return {'pontoId': pontoId, 'status': aprovar ? 'APROVADO' : 'REPROVADO'};
  }
}

void _tela(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('Mapa dos pontos', () {
    testWidgets('mostra o mapa, os indicadores e a lista das batidas fora do raio', (tester) async {
      _tela(tester);
      final svc = _FakeService();
      await tester.pumpWidget(_app(DpPontoMapaScreen(service: svc)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('dp_mapa')), findsOneWidget);
      expect(find.byKey(const Key('dp_mapa_ponto_500')), findsOneWidget);
      expect(find.byKey(const Key('dp_mapa_ponto_501')), findsOneWidget);
      expect(find.textContaining('Batidas fora do raio aguardando aprovação (1)'), findsOneWidget);
      expect(find.textContaining('Maria Souza'), findsWidgets);
      expect(svc.chamadas, ['mapa:null']);
    });

    testWidgets('aprovar chama a API e recarrega', (tester) async {
      _tela(tester);
      final svc = _FakeService();
      await tester.pumpWidget(_app(DpPontoMapaScreen(service: svc)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('dp_aprovar_500')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(svc.chamadas, ['mapa:null', 'decidir:500:true:null', 'mapa:null']);
      expect(find.text('Ponto aprovado.'), findsOneWidget);
    });

    testWidgets('reprovar exige o motivo digitado e envia para a API', (tester) async {
      _tela(tester);
      final svc = _FakeService();
      await tester.pumpWidget(_app(DpPontoMapaScreen(service: svc)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('dp_reprovar_500')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byKey(const Key('dp_mapa_motivo')), 'Estava em visita particular');
      await tester.tap(find.text('Reprovar').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(svc.chamadas, contains('decidir:500:false:Estava em visita particular'));
    });

    testWidgets('erro do backend ao decidir aparece na tela', (tester) async {
      _tela(tester);
      final svc = _FakeService(decidirErro: DpPontoException('Sem permissão para esta ação.', statusCode: 403));
      await tester.pumpWidget(_app(DpPontoMapaScreen(service: svc)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('dp_aprovar_500')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sem permissão para esta ação.'), findsOneWidget);
    });
  });

  group('Localizacao obrigatoria para bater o ponto', () {
    final original = LocalizacaoPonto.provedor;
    tearDown(() => LocalizacaoPonto.provedor = original);

    test('GPS desligado: o ponto nao e registrado e o motivo e mostrado', () async {
      LocalizacaoPonto.provedor = () async =>
          throw const LocalizacaoIndisponivelException('A localização do aparelho está desligada. Ative o GPS/localização para bater o ponto.');
      final ok = await PontoService.registrarPonto(1);
      expect(ok, isFalse);
      expect(PontoService.ultimoErro, contains('localização do aparelho está desligada'));
    });

    test('permissao negada: o ponto nao e registrado', () async {
      LocalizacaoPonto.provedor = () async =>
          throw const LocalizacaoIndisponivelException('Permissão de localização negada. Permita o acesso à localização nas configurações para bater o ponto.');
      final ok = await PontoService.registrarPonto(1);
      expect(ok, isFalse);
      expect(PontoService.ultimoErro, contains('Permissão de localização negada'));
    });
  });

  test('wrapper mobile existe para o mapa (paridade Web/Windows/Mobile)', () {
    expect(const MobileDpPontoMapaScreen(), isA<StatelessWidget>());
  });
}
