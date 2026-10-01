import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Distingue falha real de conectividade (sem internet, timeout, DNS, socket
/// recusado) de erro de negócio/validação retornado pelo backend.
///
/// Usado nos pontos de "salvar/emitir NFe" (card W3R3) para decidir se o
/// dado deve virar rascunho offline (falha de rede real) ou apenas mostrar
/// erro ao usuário (ex.: 400/422 de validação, que não é problema de rede).
class NetworkFailureDetector {
  NetworkFailureDetector._();

  static bool isConnectivityError(Object error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) return true;
    if (error is http.ClientException) return true;

    // Fallback textual best-effort para exceptions não capturadas pelos
    // tipos acima. Hoje só `package:http` é usado nos pontos onde este
    // detector é chamado (TenantContext); se outro cliente HTTP (ex.: dio)
    // for introduzido depois, REVISE estas substrings contra o texto real
    // das exceptions dele — este fallback não foi validado para o dio.
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('connection refused') ||
        text.contains('connection reset') ||
        text.contains('connection closed') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('timeoutexception') ||
        text.contains('connection timed out');
  }
}
