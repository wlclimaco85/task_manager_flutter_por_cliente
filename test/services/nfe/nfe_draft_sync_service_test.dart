import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/models/nfe/nfe_draft_status.dart';
import 'package:task_manager_flutter/repositories/nfe_draft_repository.dart';
import 'package:task_manager_flutter/services/nfe/nfe_draft_sync_service.dart';

/// Testes reais do serviço de sincronização de rascunhos offline (card
/// W3R3), incluindo o cenário central de conflito: nunca sobrescrever uma
/// NFe já transmitida/autorizada no servidor com um rascunho local
/// desatualizado.
void main() {
  late Directory tempDir;
  late NfeDraftRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nfe_draft_sync_test');
    Hive.init(tempDir.path);
    repository = NfeDraftRepository();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(NfeDraftRepository.boxName);
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('sincroniza com sucesso quando online e servidor aceita', () async {
    final draft = await repository.salvarRascunho(
      nfeIdReferencia: '10',
      dadosFormulario: {'numero': '1'},
      acao: 'emitir',
    );

    final service = NfeDraftSyncService(
      repository: repository,
      getFn: (url) async =>
          http.Response('{"statusNfe":"PENDENTE"}', 200), // não processada
      postFn: (url, body) async => http.Response('{"id":10}', 200),
    );

    final resultado = await service.sincronizar(draft);

    expect(resultado, NfeDraftSyncResult.enviado);
    final restante = await repository.obterRascunho(draft.id);
    // Rascunho enviado é removido da fila local (já virou NFe real)
    expect(restante, isNull);
  });

  test(
      'NUNCA sobrescreve NFe já autorizada no servidor — marca conflito em vez de reenviar',
      () async {
    final draft = await repository.salvarRascunho(
      nfeIdReferencia: '20',
      dadosFormulario: {'numero': '2'},
      acao: 'emitir',
    );

    var postFoiChamado = false;
    final service = NfeDraftSyncService(
      repository: repository,
      getFn: (url) async =>
          http.Response('{"statusNfe":"AUTORIZADA"}', 200), // já processada!
      postFn: (url, body) async {
        postFoiChamado = true;
        return http.Response('{}', 200);
      },
    );

    final resultado = await service.sincronizar(draft);

    expect(resultado, NfeDraftSyncResult.conflito);
    expect(postFoiChamado, isFalse,
        reason:
            'não deve nem tentar reenviar quando já existe NFe processada no servidor');

    final atualizado = await repository.obterRascunho(draft.id);
    expect(atualizado!.status, NfeDraftStatus.conflito);
    expect(atualizado.mensagemErro, isNotNull);
  });

  test('mantém como rascunho (não erro) quando ainda está offline', () async {
    final draft = await repository.salvarRascunho(
      nfeIdReferencia: '30',
      dadosFormulario: {},
      acao: 'emitir',
    );

    final service = NfeDraftSyncService(
      repository: repository,
      getFn: (url) async => throw const SocketException('sem rede'),
      postFn: (url, body) async => http.Response('{}', 200),
    );

    final resultado = await service.sincronizar(draft);

    expect(resultado, NfeDraftSyncResult.semConexao);
    final atualizado = await repository.obterRascunho(draft.id);
    expect(atualizado!.status, NfeDraftStatus.rascunho);
  });

  test('marca como erro quando servidor rejeita por motivo de negócio',
      () async {
    final draft = await repository.salvarRascunho(
      nfeIdReferencia: '40',
      dadosFormulario: {},
      acao: 'emitir',
    );

    final service = NfeDraftSyncService(
      repository: repository,
      getFn: (url) async => http.Response('{"statusNfe":"PENDENTE"}', 200),
      postFn: (url, body) async =>
          http.Response('{"message":"Dados inválidos"}', 422),
    );

    final resultado = await service.sincronizar(draft);

    expect(resultado, NfeDraftSyncResult.erro);
    final atualizado = await repository.obterRascunho(draft.id);
    expect(atualizado!.status, NfeDraftStatus.erro);
    expect(atualizado.mensagemErro, contains('inválidos'));
  });

  test(
      'NUNCA reenvia quando a checagem de status falha sem lançar exceção (fail-closed, não fail-open)',
      () async {
    final draft = await repository.salvarRascunho(
      nfeIdReferencia: '50',
      dadosFormulario: {},
      acao: 'emitir',
    );

    var postFoiChamado = false;
    // GET retorna 401 (token expirado, por ex.) SEM lançar exceção — cenário
    // do achado crítico do code review: TenantContext.get/post não lançam
    // exceção em respostas HTTP não-2xx, então isso não cai no catch de
    // conectividade. O serviço precisa tratar isso como "não confirmado" e
    // bloquear o reenvio, não como "sem conflito".
    final service = NfeDraftSyncService(
      repository: repository,
      getFn: (url) async => http.Response('{"message":"não autorizado"}', 401),
      postFn: (url, body) async {
        postFoiChamado = true;
        return http.Response('{}', 200);
      },
    );

    final resultado = await service.sincronizar(draft);

    expect(resultado, NfeDraftSyncResult.erro);
    expect(postFoiChamado, isFalse,
        reason:
            'não deve reenviar quando não foi possível confirmar o status atual da NFe');

    final atualizado = await repository.obterRascunho(draft.id);
    expect(atualizado!.status, NfeDraftStatus.erro);
  });

  test(
      'NUNCA reenvia quando o corpo da checagem de status vem em formato inesperado',
      () async {
    final draft = await repository.salvarRascunho(
      nfeIdReferencia: '60',
      dadosFormulario: {},
      acao: 'emitir',
    );

    var postFoiChamado = false;
    final service = NfeDraftSyncService(
      repository: repository,
      getFn: (url) async => http.Response('não é json válido', 200),
      postFn: (url, body) async {
        postFoiChamado = true;
        return http.Response('{}', 200);
      },
    );

    final resultado = await service.sincronizar(draft);

    expect(resultado, NfeDraftSyncResult.erro);
    expect(postFoiChamado, isFalse);
  });

  test('sincronizarPendentes processa apenas rascunhos com status pendente',
      () async {
    final d1 = await repository.salvarRascunho(
        nfeIdReferencia: '1', dadosFormulario: {}, acao: 'emitir');
    final d2 = await repository.salvarRascunho(
        nfeIdReferencia: '2', dadosFormulario: {}, acao: 'emitir');
    await repository.atualizarStatus(d2.id, status: NfeDraftStatus.enviado);

    var chamadas = 0;
    final service = NfeDraftSyncService(
      repository: repository,
      getFn: (url) async => http.Response('{"statusNfe":"PENDENTE"}', 200),
      postFn: (url, body) async {
        chamadas++;
        return http.Response('{}', 200);
      },
    );

    await service.sincronizarPendentes();

    expect(chamadas, 1); // só o d1, que estava pendente
  });
}
