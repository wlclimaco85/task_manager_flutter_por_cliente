import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/alerta_polling_service.dart';
import 'package:task_manager_flutter/services/notificador_plataforma.dart';

class _NotificadorFake implements NotificadorPlataforma {
  var inicializado = false;
  final notificacoes = <({String titulo, String corpo})>[];

  @override
  Future<void> inicializar() async {
    inicializado = true;
  }

  @override
  Future<void> notificar(
      {required String titulo, required String corpo}) async {
    notificacoes.add((titulo: titulo, corpo: corpo));
  }

  @override
  Future<String> solicitarPermissao() async => 'granted';

  @override
  Future<String> statusPermissao() async => 'granted';
}

void main() {
  test('primeira leitura com um alerta pendente dispara notificacao nativa',
      () async {
    final notificador = _NotificadorFake();
    final service = AlertaPollingService.paraTeste(
      notificador: notificador,
      buscarNotificacoes: () async => [
        {'id': 10, 'mensagem': 'Cliente enviou documento pendente'},
      ],
    );

    await service.iniciar();
    service.parar();

    expect(notificador.inicializado, isTrue);
    expect(notificador.notificacoes, hasLength(1));
    expect(notificador.notificacoes.single.titulo, 'Abraço Contabilidade');
    expect(notificador.notificacoes.single.corpo,
        'Cliente enviou documento pendente');
  });

  test('primeira leitura com varios alertas pendentes dispara resumo unico',
      () async {
    final notificador = _NotificadorFake();
    final service = AlertaPollingService.paraTeste(
      notificador: notificador,
      buscarNotificacoes: () async => [
        {'id': 11, 'mensagem': 'Primeiro alerta'},
        {'id': 12, 'mensagem': 'Segundo alerta'},
      ],
    );

    await service.iniciar();
    service.parar();

    expect(notificador.notificacoes, hasLength(1));
    expect(notificador.notificacoes.single.corpo,
        'Você tem 2 notificações pendentes.');
  });

  test('leituras seguintes notificam somente ids novos', () async {
    final notificador = _NotificadorFake();
    var chamada = 0;
    final service = AlertaPollingService.paraTeste(
      notificador: notificador,
      buscarNotificacoes: () async {
        chamada++;
        if (chamada == 1) {
          return [
            {'id': 20, 'mensagem': 'Alerta inicial'},
          ];
        }
        return [
          {'id': 20, 'mensagem': 'Alerta inicial'},
          {'id': 21, 'mensagem': 'Novo alerta depois do login'},
        ];
      },
    );

    await service.executarCicloParaTeste();
    await service.executarCicloParaTeste();

    expect(notificador.notificacoes, hasLength(2));
    expect(notificador.notificacoes.last.corpo, 'Novo alerta depois do login');
  });
}
