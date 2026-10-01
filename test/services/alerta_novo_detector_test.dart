// test/services/alerta_novo_detector_test.dart
//
// Cobre AlertaNovoDetector -- o nucleo puro (sem plugin nativo/dart:html)
// do polling de notificacoes nativas (toast Windows/desktop/mobile e popup
// do navegador) pedido pelo usuario para SolicitacaoAcesso. Testavel sem
// mocks de plataforma porque so compara ids.
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/alerta_novo_detector.dart';

void main() {
  final detector = const AlertaNovoDetector();

  group('AlertaNovoDetector', () {
    test('primeira leitura (baseline): todo alerta existente vira "conhecido", nunca "novo" sozinho', () {
      final atuais = [
        {'id': 1, 'mensagem': 'a'},
        {'id': 2, 'mensagem': 'b'},
      ];

      final ids = detector.extrairIds(atuais);

      expect(ids, {1, 2});
    });

    test('detecta como novo somente o alerta cujo id nao estava nos conhecidos', () {
      final conhecidos = {1, 2};
      final atuais = [
        {'id': 1, 'mensagem': 'ja existia'},
        {'id': 2, 'mensagem': 'ja existia tambem'},
        {'id': 3, 'mensagem': 'nova solicitacao de acesso de Fulano'},
      ];

      final novos = detector.detectarNovos(
        idsConhecidos: conhecidos,
        alertasAtuais: atuais,
      );

      expect(novos, hasLength(1));
      expect(novos.first['id'], 3);
      expect(novos.first['mensagem'], 'nova solicitacao de acesso de Fulano');
    });

    test('nao notifica de novo o mesmo alerta em leituras subsequentes (id ja conhecido)', () {
      final conhecidos = {1, 2, 3};
      final atuais = [
        {'id': 1, 'mensagem': 'a'},
        {'id': 2, 'mensagem': 'b'},
        {'id': 3, 'mensagem': 'ja notificado no ciclo anterior'},
      ];

      final novos = detector.detectarNovos(
        idsConhecidos: conhecidos,
        alertasAtuais: atuais,
      );

      expect(novos, isEmpty);
    });

    test('lista vazia de alertas atuais nunca gera "novos"', () {
      final novos = detector.detectarNovos(
        idsConhecidos: {1, 2},
        alertasAtuais: [],
      );

      expect(novos, isEmpty);
    });

    test('ignora item sem id valido (nem int nem string numerica) em vez de quebrar', () {
      final atuais = [
        {'id': 'abc', 'mensagem': 'id invalido'},
        {'mensagem': 'sem campo id'},
        {'id': 5, 'mensagem': 'valido'},
      ];

      final novos = detector.detectarNovos(
        idsConhecidos: {},
        alertasAtuais: atuais,
      );

      expect(novos, hasLength(1));
      expect(novos.first['id'], 5);
    });

    test('aceita id vindo como String numerica (JSON de backend as vezes serializa assim)', () {
      final atuais = [
        {'id': '42', 'mensagem': 'id como string'},
      ];

      final novos = detector.detectarNovos(idsConhecidos: {}, alertasAtuais: atuais);
      final ids = detector.extrairIds(atuais);

      expect(novos, hasLength(1));
      expect(ids, {42});
    });
  });
}
