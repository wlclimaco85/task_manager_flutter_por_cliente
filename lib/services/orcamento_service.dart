import '../../../utils/api_links.dart';
import '../../services/network_caller.dart';

class OrcamentoService {
  static Future<List<Map<String, dynamic>>> fetchAll({
    String? status,
    String? cliente,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      String url = ApiLinks.orcamentos;
      final params = <String, String>{};
      if (status != null && status != 'Todos') params['status'] = status;
      if (cliente != null && cliente.isNotEmpty) params['cliente'] = cliente;
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
      final response = await NetworkCaller().getRequest(ApiLinks.orcamentoById(id.toString()));
      if (response.isSuccess && response.body != null) {
        return response.body!['data'] ?? response.body;
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> create(Map<String, dynamic> data) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.orcamentos, data);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await NetworkCaller().putRequest(ApiLinks.orcamentoById(id.toString()), data);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> aprovar(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.aprovarOrcamento(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> reprovar(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.reprovarOrcamento(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> converter(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.converterOrcamento(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> novaVersao(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.novaVersaoOrcamento(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelar(int id) async {
    try {
      final response = await NetworkCaller().postRequest(ApiLinks.cancelarOrcamento(id.toString()), null);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }
}
