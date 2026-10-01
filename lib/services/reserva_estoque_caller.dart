import '../utils/api_links.dart';
import './network_caller.dart';

class ReservaEstoqueCaller {
  static Future<List<Map<String, dynamic>>> fetchReservas(int pedidoId) async {
    try {
      final url = ApiLinks.reservasPorPedido(pedidoId);
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

  static Future<double> fetchDisponivel(int produtoId) async {
    try {
      final url = ApiLinks.disponivelProduto(produtoId);
      final response = await NetworkCaller().getRequest(url);
      if (response.isSuccess && response.body != null) {
        final data = response.body!['data'];
        if (data is num) return data.toDouble();
        if (data is Map) return (data['saldo'] ?? 0).toDouble();
        if (data is String) return double.tryParse(data) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  static Future<bool> reservar(int pedidoId, Map<String, dynamic> body) async {
    try {
      final url = ApiLinks.reservarEstoque(pedidoId);
      final response = await NetworkCaller().postRequest(url, body);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> liberar(int pedidoId, Map<String, dynamic> body) async {
    try {
      final url = ApiLinks.liberarEstoque(pedidoId);
      final response = await NetworkCaller().postRequest(url, body);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }
}
