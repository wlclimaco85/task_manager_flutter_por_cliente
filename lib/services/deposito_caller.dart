import '../utils/api_links.dart';
import './network_caller.dart';

class DepositoCaller {
  static Future<List<Map<String, dynamic>>> listarDepositos() async {
    try {
      final response = await NetworkCaller().getRequest(ApiLinks.depositos);
      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> criarDeposito(Map<String, dynamic> body) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.depositos, body);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> atualizarDeposito(int id, Map<String, dynamic> body) async {
    try {
      final response = await NetworkCaller().putRequest(ApiLinks.depositoPorId(id), body);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deletarDeposito(int id) async {
    try {
      final response = await NetworkCaller().deleteRequest(ApiLinks.depositoPorId(id));
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> listarLocalizacoes(int depositoId) async {
    try {
      final response = await NetworkCaller().getRequest(ApiLinks.localizacoesPorDeposito(depositoId));
      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> criarLocalizacao(int depositoId, Map<String, dynamic> body) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.criarLocalizacao(depositoId), body);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> consultarSaldo(int produtoId) async {
    try {
      final response = await NetworkCaller().getRequest(ApiLinks.saldoPorProduto(produtoId));
      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (data is List) return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> transferir(Map<String, dynamic> body) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.transferirDeposito, body);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> ajustar(Map<String, dynamic> body) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.ajustarEstoque, body);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }
}
