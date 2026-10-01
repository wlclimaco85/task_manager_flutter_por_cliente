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
