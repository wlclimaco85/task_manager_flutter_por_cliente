import '../models/network_response.dart';
import 'network_caller.dart';
import '../utils/api_links.dart';

class AprovacaoPagamentoCaller {
  static Future<NetworkResponse> fila({required int empresaId}) async {
    try {
      final uri = '${ApiLinks.aprovacaoPagamentoFila}?empresaId=$empresaId';
      return await NetworkCaller().getRequest(uri);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> historico({
    required dynamic contaPagarId,
  }) async {
    try {
      return await NetworkCaller()
          .getRequest(ApiLinks.aprovacaoPagamentoConta(contaPagarId));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> solicitar(dynamic contaPagarId) async {
    try {
      return await NetworkCaller().postRequest(
        ApiLinks.aprovacaoPagamentoSolicitar(contaPagarId),
        {},
      );
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> aprovar({
    required dynamic aprovacaoId,
    required String justificativa,
  }) async {
    try {
      return await NetworkCaller().postRequest(
        ApiLinks.aprovacaoPagamentoAprovar(aprovacaoId),
        {'justificativa': justificativa},
      );
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> reprovar({
    required dynamic aprovacaoId,
    required String justificativa,
  }) async {
    try {
      return await NetworkCaller().postRequest(
        ApiLinks.aprovacaoPagamentoReprovar(aprovacaoId),
        {'justificativa': justificativa},
      );
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }
}
