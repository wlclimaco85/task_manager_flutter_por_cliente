import '../models/network_response.dart';
import 'network_caller.dart';
import '../utils/api_links.dart';

class RateioCaller {
  static Future<NetworkResponse> listar({
    required String tipo,
    required dynamic id,
  }) async {
    try {
      return await NetworkCaller().getRequest(ApiLinks.rateioListar(tipo, id));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> salvar(Map<String, dynamic> body) async {
    try {
      return await NetworkCaller().postRequest(ApiLinks.rateioSalvar, body);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> deletar({
    required String tipo,
    required dynamic id,
  }) async {
    try {
      return await NetworkCaller().deleteRequest(ApiLinks.rateioDeletar(tipo, id));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> historico({
    required String tipo,
    required dynamic id,
  }) async {
    try {
      return await NetworkCaller().getRequest(ApiLinks.rateioHistorico(tipo, id));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }
}
