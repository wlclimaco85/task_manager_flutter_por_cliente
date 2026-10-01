import 'network_caller.dart';
import '../utils/api_links.dart';

/// Service for rateio entre centros de custo operations.
class RateioService {
  final NetworkCaller _caller = NetworkCaller();

  /// List rateio items for a given lancamento type and id.
  Future<List<Map<String, dynamic>>> getRateio({
    required String tipo,
    required dynamic id,
  }) async {
    final response = await _caller.getRequest(ApiLinks.rateioListar(tipo, id));
    if (response.isSuccess && response.body != null) {
      return _extractList(response.body!);
    }
    return [];
  }

  /// Save (create/update) rateio items for a lancamento.
  Future<bool> saveRateio(Map<String, dynamic> body) async {
    final response = await _caller.postRequest(ApiLinks.rateioSalvar, body);
    return response.isSuccess;
  }

  /// Delete rateio for a given lancamento type and id.
  Future<bool> deleteRateio({
    required String tipo,
    required dynamic id,
  }) async {
    final response = await _caller.deleteRequest(ApiLinks.rateioDeletar(tipo, id));
    return response.isSuccess;
  }

  /// Get rateio history for a given lancamento type and id.
  Future<List<Map<String, dynamic>>> getHistorico({
    required String tipo,
    required dynamic id,
  }) async {
    final response = await _caller.getRequest(ApiLinks.rateioHistorico(tipo, id));
    if (response.isSuccess && response.body != null) {
      return _extractList(response.body!);
    }
    return [];
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is List) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    if (body.containsKey('content') && body['content'] is List) {
      return List<Map<String, dynamic>>.from(body['content']);
    }
    final values = body.values.whereType<List>();
    if (values.isNotEmpty) {
      return List<Map<String, dynamic>>.from(values.first);
    }
    return [];
  }
}
