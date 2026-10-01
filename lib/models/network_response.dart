class NetworkResponse {
  final bool isSuccess;
  final int statusCode;
  final Map<String, dynamic>? body;
  final String? errorMessage;

  NetworkResponse(this.isSuccess, this.statusCode, dynamic rawBody, [this.errorMessage])
      : body = _toMap(rawBody);

  /// Converte qualquer resposta JSON para Map<String, dynamic>.
  /// Se o backend retornar uma lista diretamente, envolve em {data: [...]}.
  static Map<String, dynamic>? _toMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List) return {'data': raw};
    return {'data': raw};
  }
}

