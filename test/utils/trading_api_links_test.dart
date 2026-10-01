import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/api_links.dart';

void main() {
  group('ApiLinks — Trading Broker Config', () {
    test('tradingBrokerConfig aponta para o endpoint esperado no backend principal', () {
      expect(ApiLinks.tradingBrokerConfig, contains('/boletobancos/api/trading/broker-config'));
    });

    test('tradingOperacoes continua apontando para operacao-assistida', () {
      expect(ApiLinks.tradingOperacoes, contains('/boletobancos/api/trading/operacao-assistida'));
    });
  });
}
