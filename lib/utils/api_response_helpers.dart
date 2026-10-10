/// Extrai a lista de itens de uma resposta JSON decodificada da API.
///
/// Aceita 3 formatos usados pelos endpoints deste backend:
/// - lista JSON crua: `[...]`
/// - `{"data": [...], "response": {...}}` (padrão `Response.builder()` do
///   backend Spring, ex.: `GET /api/parceiro/empresa/{id}`)
/// - `{"content": [...]}` (padrão de paginação Spring Data)
///
/// Retorna lista vazia se `decoded` não corresponder a nenhum desses formatos.
List<dynamic> extrairListaDeResposta(dynamic decoded) {
  if (decoded is List) return decoded;
  if (decoded is Map) {
    if (decoded['data'] is List) return decoded['data'] as List;
    if (decoded['content'] is List) return decoded['content'] as List;
  }
  return const [];
}

/// Extrai a lista de itens de uma resposta paginada no formato
/// `{"data": {"dados": [...], "totalElements": N}, "response": {...}}`,
/// usado por vários endpoints paginados deste backend (ex.:
/// `GET /api/produto_contabil`, `GET /api/nfse_item`).
///
/// Também aceita `{"data": [...]}` e lista crua como fallback, delegando
/// para [extrairListaDeResposta].
List<dynamic> extrairListaPaginada(dynamic decoded) {
  if (decoded is Map &&
      decoded['data'] is Map &&
      (decoded['data'] as Map)['dados'] is List) {
    return (decoded['data'] as Map)['dados'] as List;
  }
  return extrairListaDeResposta(decoded);
}

/// Representa o resultado de uma resposta Spring Page contendo a lista de itens,
/// total de elementos e se é a última página.
class ResultadoPaginadoSpring {
  final List<dynamic> itens;
  final int totalElements;
  final bool isLast;

  const ResultadoPaginadoSpring({
    required this.itens,
    required this.totalElements,
    required this.isLast,
  });
}

/// Extrai itens, total e flag isLast de respostas no formato Spring Page `Page<T>`
/// (`{"content": [...], "totalElements": N, "last": bool}`).
/// Mantém compatibilidade com outros formatos caso encapsulado em data.
ResultadoPaginadoSpring extrairResultadoPaginadoSpring(dynamic decoded) {
  if (decoded is Map) {
    final Map map = (decoded['data'] is Map) ? (decoded['data'] as Map) : decoded;
    final List<dynamic> itens;
    if (map['content'] is List) {
      itens = map['content'] as List;
    } else if (map['dados'] is List) {
      itens = map['dados'] as List;
    } else if (map['data'] is List) {
      itens = map['data'] as List;
    } else {
      itens = const [];
    }

    final total = (map['totalElements'] as num?)?.toInt() ?? itens.length;
    final isLast = (map['last'] as bool?) ?? (itens.length < 20);
    return ResultadoPaginadoSpring(
      itens: itens,
      totalElements: total,
      isLast: isLast,
    );
  }
  if (decoded is List) {
    return ResultadoPaginadoSpring(
      itens: decoded,
      totalElements: decoded.length,
      isLast: true,
    );
  }
  return const ResultadoPaginadoSpring(
    itens: [],
    totalElements: 0,
    isLast: true,
  );
}
