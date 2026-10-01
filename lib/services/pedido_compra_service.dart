import '../../../utils/api_links.dart';
import '../../services/network_caller.dart';

class PedidoCompraService {
  static Future<List<Map<String, dynamic>>> fetchAll({
    String? status,
    String? fornecedor,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      String url = ApiLinks.pedidosCompra;
      final params = <String, String>{};
      if (status != null && status != 'Todos') params['status'] = status;
      if (fornecedor != null && fornecedor.isNotEmpty) params['fornecedor'] = fornecedor;
      if (dataInicio != null) params['dataInicio'] = dataInicio;
      if (dataFim != null) params['dataFim'] = dataFim;
      if (params.isNotEmpty) {
        final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
        url = '$url?$query';
      }
      final response = await NetworkCaller().getRequest(url);
      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> fetchById(int id) async {
    try {
      final response = await NetworkCaller().getRequest(ApiLinks.pedidoCompraById(id.toString()));
      if (response.isSuccess && response.body != null) {
        return response.body!['data'] ?? response.body;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> create(Map<String, dynamic> data) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.pedidosCompra, data);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await NetworkCaller().putRequest(ApiLinks.pedidoCompraById(id.toString()), data);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> emitir(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.emitirPedidoCompra(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> aprovar(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.aprovarPedidoCompra(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> receberParcial(int id, Map<String, dynamic> data) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.receberParcialPedidoCompra(id.toString()), data);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> receberTotal(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.receberTotalPedidoCompra(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelar(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.cancelarPedidoCompra(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }
}
