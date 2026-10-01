/// DocumentoBaixaHelper — Funções puras para BaixaDialog
///
/// Helpers encapsulam a lógica de parse de conta/ID/tipo sem dependências de UI ou Network.
/// Facilita testes e reuso em múltiplos contextos (Windows/Web/Mobile).

class DocumentoBaixaHelper {
  /// Retorna a string "PAGAR" ou "RECEBER" conforme isPagar.
  /// Útil para mensagens e logging.
  static String tipoConta(bool isPagar) {
    return isPagar ? 'PAGAR' : 'RECEBER';
  }

  /// Valida se um ID de conta é válido: não null e não vazio.
  static bool itemIdValido(dynamic id) {
    if (id == null) return false;
    final str = id.toString().trim();
    return str.isNotEmpty;
  }

  /// Parse recursivo de corpo de resposta, unwrappando {"data": ...} múltiplos níveis.
  ///
  /// Exemplos:
  /// - null → null
  /// - {} → {}
  /// - {"data": {...}} → {...}
  /// - {"data": {"data": {...}}} → {...}
  /// - {"data": []} → null (não é Map, sai do loop)
  /// - {"data": null} → null (cursor vira null, retorna null)
  static Map<String, dynamic>? parseContaBody(dynamic body) {
    if (body == null) return null;

    dynamic cursor = body;

    // Percorre wrappers {"data": ...} somente enquanto cursor for Map.
    // Sai do loop se cursor['data'] for List ou null.
    while (cursor is Map && cursor.containsKey('data')) {
      final next = cursor['data'];
      if (next == null) return null;
      cursor = next;
    }

    // Retorna Map se cursor for Map, senão null.
    if (cursor is Map) {
      return Map<String, dynamic>.from(cursor);
    }
    return null;
  }
}
