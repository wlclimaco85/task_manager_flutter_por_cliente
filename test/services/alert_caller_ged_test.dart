import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/alert_caller.dart';

void main() {
  test('sino mapeia notificacao GED com cliente e nome do arquivo', () {
    final alerts = mapNotificacoesToAlerts(
      [
        {
          'tipo': 'GED',
          'mensagem':
              'GED - Empresa Abraco enviou o arquivo "documento.pdf" para o cliente Eduardo.',
          'dataVencimento': '2026-08-26T10:00:00',
          'referenciaId': 21,
        }
      ],
      loginId: 254,
    );

    expect(alerts, hasLength(1));
    expect(alerts.single.id, 21);
    expect(alerts.single.idUserDestino, 254);
    expect(alerts.single.status, 'GED');
    expect(alerts.single.texto, contains('Eduardo'));
    expect(alerts.single.texto, contains('documento.pdf'));
  });
}
