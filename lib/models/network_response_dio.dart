class NetworkResponseDio {
  final int? statusCode;
  final dynamic body;
  final String? errorMessage;

  NetworkResponseDio({this.statusCode, this.body, this.errorMessage});

  // Método auxiliar para verificar se foi bem-sucedido
  bool get isSuccess => statusCode == 200;
}
