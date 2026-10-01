import '../models/network_response.dart';
import './network_caller.dart';
import '../utils/api_links.dart';

class DashboardFinanceiroCaller {
  Future<Map<String, dynamic>> obterDashboard({
    int? empresaId,
    int? parceiroId,
    int? contaBancariaId,
    String? dataInicio,
    String? dataFim,
  }) async {
    final params = <String, String>{};
    if (empresaId != null) params['empresaId'] = empresaId.toString();
    if (parceiroId != null) params['parceiroId'] = parceiroId.toString();
    if (contaBancariaId != null) {
      params['contaBancariaId'] = contaBancariaId.toString();
    }
    if (dataInicio != null) params['dataInicio'] = dataInicio;
    if (dataFim != null) params['dataFim'] = dataFim;

    String url = ApiLinks.dashboardFinanceiro;
    if (params.isNotEmpty) {
      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      url = '$url?$query';
    }

    final NetworkResponse response = await NetworkCaller().getRequest(url);
    if (response.isSuccess && response.body != null) {
      return Map<String, dynamic>.from(response.body!);
    }
    return {};
  }

  Future<Map<String, dynamic>> obterKpis({int? empresaId, int? parceiroId, int? dias}) async {
    final url = ApiLinks.dashboardFinanceiroKpis(
      empresaId: empresaId?.toString(),
      parceiroId: parceiroId?.toString(),
      dias: dias,
    );
    final NetworkResponse response = await NetworkCaller().getRequest(url);
    if (response.isSuccess && response.body != null) {
      return Map<String, dynamic>.from(response.body!);
    }
    return {};
  }

  Future<List<dynamic>> obterProjecao({int? empresaId, int? parceiroId, int? meses}) async {
    final url = ApiLinks.dashboardFinanceiroProjecao(
      empresaId: empresaId?.toString(),
      parceiroId: parceiroId?.toString(),
      meses: meses,
    );
    final NetworkResponse response = await NetworkCaller().getRequest(url);
    if (response.isSuccess && response.body != null && response.body is List) {
      return response.body as List<dynamic>;
    }
    return [];
  }
}
