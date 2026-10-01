/// Deteccao pura de alertas GENUINAMENTE novos entre duas leituras de
/// `/api/notificacoes`. Sem dependencia de plataforma (nada de
/// flutter_local_notifications/dart:html aqui) -- so compara ids, por isso
/// e testavel com flutter_test puro, sem mocks de plugin nativo.
///
/// "Novo" = item cujo id nao estava no conjunto de ids ja conhecidos da
/// leitura anterior. Isso evita notificar de novo um alerta que ja existia
/// antes do app iniciar o polling (baseline da primeira leitura) e evita
/// notificar 2x o mesmo alerta em leituras subsequentes.
class AlertaNovoDetector {
  const AlertaNovoDetector();

  List<Map<String, dynamic>> detectarNovos({
    required Set<int> idsConhecidos,
    required List<Map<String, dynamic>> alertasAtuais,
  }) {
    final novos = <Map<String, dynamic>>[];
    for (final alerta in alertasAtuais) {
      final id = _extrairId(alerta['id'] ??
          alerta['referenciaId'] ??
          alerta['alertaId'] ??
          alerta['codAlerta']);
      if (id != null && !idsConhecidos.contains(id)) {
        novos.add(alerta);
      }
    }
    return novos;
  }

  /// Ids validos presentes em [alertas] -- usado para atualizar o conjunto
  /// de "conhecidos" apos cada leitura (baseline inicial ou incremento).
  Set<int> extrairIds(List<Map<String, dynamic>> alertas) {
    final ids = <int>{};
    for (final alerta in alertas) {
      final id = _extrairId(alerta['id'] ??
          alerta['referenciaId'] ??
          alerta['alertaId'] ??
          alerta['codAlerta']);
      if (id != null) ids.add(id);
    }
    return ids;
  }

  int? _extrairId(dynamic valor) {
    if (valor is int) return valor;
    if (valor is String) return int.tryParse(valor);
    return null;
  }
}
