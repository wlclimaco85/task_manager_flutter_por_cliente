import '../models/network_response.dart';
import 'network_caller.dart';
import '../utils/api_links.dart';

class AprovacaoCompraCaller {
  static Future<NetworkResponse> fila() async {
    try {
      return await NetworkCaller().getRequest(ApiLinks.aprovacaoCompraFila);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> solicitar(dynamic pedidoCompraId) async {
    try {
      return await NetworkCaller()
          .postRequest(ApiLinks.aprovacaoCompraSolicitar(pedidoCompraId), {});
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
        ApiLinks.aprovacaoCompraAprovar(aprovacaoId),
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
        ApiLinks.aprovacaoCompraReprovar(aprovacaoId),
        {'justificativa': justificativa},
      );
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> pedido(dynamic pedidoCompraId) async {
    try {
      return await NetworkCaller()
          .getRequest(ApiLinks.aprovacaoCompraPedido(pedidoCompraId));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }
}
