import '../models/network_response.dart';
import './network_caller.dart';
import '../utils/api_links.dart';

class DreCaller {
  Future<Map<String, dynamic>> obterDre({
    required int empresaId,
    required String dataInicio,
    required String dataFim,
    int? centroCustoId,
    bool compararPeriodoAnterior = false,
  }) async {
    final body = <String, dynamic>{
      'empresaId': empresaId,
      'dataInicio': dataInicio,
      'dataFim': dataFim,
      'compararPeriodoAnterior': compararPeriodoAnterior,
    };
    if (centroCustoId != null) {
      body['centroCustoId'] = centroCustoId;
    }

    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.dre, body);
    if (response.isSuccess && response.body != null) {
      return Map<String, dynamic>.from(response.body!);
    }
    return {};
  }

  Future<List<String>> obterPeriodos() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.drePeriodos);
    if (response.isSuccess && response.body != null) {
      final data = response.body!['data'] ?? response.body!['periodos'] ?? [];
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      }
    }
    return [];
  }
}
