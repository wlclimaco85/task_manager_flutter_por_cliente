import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/nfe_action_feedback.dart';

void main() {
  group('NfeActionFeedback', () {
    test('mantem status correto apos recusa bem-sucedida', () {
      expect(NfeActionFeedback.recusaStatus, 'REJEITADA');
    });

    test('retorna mensagem especifica para cancelamento indisponivel', () {
      final message = NfeActionFeedback.cancelamentoErrorMessage(
        500,
        'Cancelamento SOAP ainda nao implementado',
      );

      expect(message, contains('Cancelamento da NF-e indisponivel'));
      expect(message, isNot(contains('Erro 500')));
    });

    test('nao esconde erro funcional de cancelamento sem sinal de SOAP', () {
      expect(
        NfeActionFeedback.cancelamentoErrorMessage(
          500,
          'Prazo de cancelamento expirado',
        ),
        'Erro 500. Tente novamente.',
      );
    });

    test('retorna mensagem generica para outros erros http', () {
      expect(
        NfeActionFeedback.cancelamentoErrorMessage(400, 'Motivo invalido'),
        'Erro 400. Tente novamente.',
      );
    });
  });
}
