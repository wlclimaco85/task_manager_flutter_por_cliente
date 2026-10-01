/// Exceção base para erros relacionados a NFe
class NfeException implements Exception {
  final String message;

  NfeException(this.message);

  @override
  String toString() => message;
}

/// Exceção lançada quando erro ocorre na requisição ao repository
class NfeRepositoryException extends NfeException {
  NfeRepositoryException(String message) : super('NfeRepository Error: $message');
}

/// Exceção lançada quando NFe não é encontrada
class NfeNotFoundException extends NfeException {
  NfeNotFoundException(String message) : super('NFe não encontrada: $message');
}

/// Exceção lançada quando erro de validação ocorre
class NfeValidationException extends NfeException {
  NfeValidationException(String message) : super('Erro de validação: $message');
}

/// Exceção lançada quando API retorna erro
class NfeApiException extends NfeException {
  final int? statusCode;

  NfeApiException(String message, {this.statusCode})
      : super('API Error (${statusCode ?? 'unknown'}): $message');
}
