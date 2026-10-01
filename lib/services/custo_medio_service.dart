import '../models/network_response.dart';
import '../utils/api_links.dart';
import './network_caller.dart';

class CustoMedioService {
  static Future<NetworkResponse> consultar(int produtoId) async {
    try {
      return await NetworkCaller()
          .getRequest(ApiLinks.custoMedioConsultar(produtoId));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> recalcular(int produtoId) async {
    try {
      return await NetworkCaller()
           .postRequest(ApiLinks.custoMedioRecalcular, {});
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> historico(int produtoId) async {
    try {
      return await NetworkCaller()
          .getRequest(ApiLinks.custoMedioHistorico(produtoId));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> baixarPorVenda(int vendaId) async {
    try {
      return await NetworkCaller()
           .postRequest(ApiLinks.baixarPorVenda, {});
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }
}
