import 'dart:convert';

String fiscalErrorMessage(int statusCode, String body) {
  final fallback = 'Erro $statusCode';
  final trimmed = body.trim();
  if (trimmed.isEmpty) return fallback;

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map) {
      final message = decoded['message'] ??
          decoded['mensagem'] ??
          decoded['error'] ??
          decoded['erro'] ??
          decoded['motivo'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return '$fallback: ${message.toString().trim()}';
      }
    }
  } catch (_) {
    if (trimmed.length <= 180 && !trimmed.startsWith('<')) {
      return '$fallback: $trimmed';
    }
  }

  return fallback;
}
