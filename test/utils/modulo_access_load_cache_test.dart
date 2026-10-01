import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

/// Regressao para o BUG de producao: 429 "Limite de requisicoes por tenant
/// atingido" em GET /api/empresa-modulo.
///
/// Causa raiz (uma das contribuintes identificadas): ModuloAccess.load()
/// ja possuia a flag `_loaded` mas nunca a checava no inicio do metodo —
/// toda chamada repetida (main.dart no boot + login_screen.dart apos
/// login, ou qualquer outra chamada futura na mesma sessao) refazia as 2
/// requisicoes de rede (empresa-modulo + parceiro-modulo) sem
/// necessidade, consumindo o orcamento do rate limit por tenant
/// (RateLimiterUtil.MAX_REQUESTS_PER_MINUTE_TENANT) mais rapido que o
/// necessario.
///
/// Este teste prova o cache: com _loaded=true (via setContratadosParaTeste,
/// que so existe para teste), uma nova chamada a load() sem sessao de
/// usuario ativa (AuthUtility.userInfo == null) NAO deve sobrescrever os
/// modulos ja carregados com a lista vazia do fallback deny-by-default —
/// o que so acontece se load() pular a nova checagem de rede.
void main() {
  setUp(() => ModuloAccess.reset());

  test('load() nao refaz fetch quando ja carregado nesta sessao (cache)', () async {
    ModuloAccess.setContratadosParaTeste(['Financeiro']);
    expect(ModuloAccess.modulosContratados, ['Financeiro']);

    // Sem guarda, load() cairia no fallback deny-by-default (sem usuario
    // logado em AuthUtility.userInfo neste teste) e zeraria a lista.
    await ModuloAccess.load();

    expect(ModuloAccess.modulosContratados, ['Financeiro']);
  });

  test('reset() força releitura na proxima chamada a load()', () async {
    ModuloAccess.setContratadosParaTeste(['Financeiro']);
    ModuloAccess.reset();

    await ModuloAccess.load();

    // Sem usuario logado (AuthUtility.userInfo == null) e sem MASTER,
    // cai no fallback deny-by-default: lista vazia.
    expect(ModuloAccess.modulosContratados, isEmpty);
  });
}
