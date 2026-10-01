/// Exceção lançada pelo NFeService quando há erro em operações NFe
class NFeServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalException;

  NFeServiceException(
    this.message, {
    this.statusCode,
    this.originalException,
  });

  @override
  String toString() => 'NFeServiceException(message: $message, '
      'statusCode: $statusCode, originalException: $originalException)';
}
