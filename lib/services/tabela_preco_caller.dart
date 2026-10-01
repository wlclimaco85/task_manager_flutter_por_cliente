import '../models/network_response.dart';
import 'network_caller.dart';
import '../utils/api_links.dart';

class TabelaPrecoCaller {
  static Future<NetworkResponse> listarTabelas() async {
    try {
      return await NetworkCaller().getRequest(ApiLinks.tabelasPreco);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> salvarTabela(Map<String, dynamic> body) async {
    try {
      return await NetworkCaller().postRequest(ApiLinks.tabelasPreco, body);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> atualizarTabela(
      String id, Map<String, dynamic> body) async {
    try {
      return await NetworkCaller()
          .putRequest(ApiLinks.tabelaPrecoById(id), body);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> deletarTabela(String id) async {
    try {
      return await NetworkCaller().deleteRequest(ApiLinks.tabelaPrecoById(id));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> listarItens(String tabelaId) async {
    try {
      return await NetworkCaller()
          .getRequest(ApiLinks.itensTabelaPreco(tabelaId));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> salvarItem(
      String tabelaId, Map<String, dynamic> body) async {
    try {
      return await NetworkCaller()
          .postRequest(ApiLinks.salvarItemTabelaPreco(tabelaId), body);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> deletarItem(
      String tabelaId, String itemId) async {
    try {
      return await NetworkCaller()
          .deleteRequest(ApiLinks.deletarItemTabelaPreco(tabelaId, itemId));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> listarDescontos() async {
    try {
      return await NetworkCaller().getRequest(ApiLinks.descontos);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> salvarDesconto(Map<String, dynamic> body) async {
    try {
      return await NetworkCaller().postRequest(ApiLinks.descontos, body);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> atualizarDesconto(
      String id, Map<String, dynamic> body) async {
    try {
      return await NetworkCaller().putRequest(ApiLinks.descontoById(id), body);
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }

  static Future<NetworkResponse> deletarDesconto(String id) async {
    try {
      return await NetworkCaller().deleteRequest(ApiLinks.descontoById(id));
    } catch (e) {
      return NetworkResponse(false, -1, null);
    }
  }
}
