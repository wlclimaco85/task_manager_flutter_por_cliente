import '../../models/network_response.dart';
import 'network_caller.dart';
import '../../utils/api_links.dart';

class BaixaAutomaticaCaller {
  static Future<NetworkResponse> importar({
    required String linhas,
    required String tipo,
  }) async {
    try {
      return await NetworkCaller().postRequest(
        ApiLinks.baixaAutomaticaImportar,
        {'linhas': linhas, 'tipo': tipo},
      );
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> conferir({
    required dynamic id,
    required String acao,
  }) async {
    try {
      return await NetworkCaller().postRequest(
        ApiLinks.baixaAutomaticaConferir(id, acao),
        {},
      );
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> pendentes() async {
    try {
      return await NetworkCaller().getRequest(ApiLinks.baixaAutomaticaPendentes);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> historico({
    required dynamic contaReceberId,
  }) async {
    try {
      return await NetworkCaller()
          .getRequest(ApiLinks.baixaAutomaticaConta(contaReceberId));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }
}
