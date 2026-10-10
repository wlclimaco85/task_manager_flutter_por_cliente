import '../models/network_response.dart';
import './network_caller.dart';
import '../utils/api_links.dart';

class EmpresaCaller {
  /// Dropdown de empresas para uso em formulários
  static Future<List<Map<String, dynamic>>> loadEmpresas() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allEmpresas);
    if (response.isSuccess && response.body != null) {
      // Aceita {data: {dados: [...]}} (paginado) e {data: [...]} (lista direta).
      final raw = response.body!['data'];
      final List<dynamic> data =
          raw is Map ? (raw['dados'] as List<dynamic>? ?? []) : (raw is List ? raw : []);
      return data
          .whereType<Map>()
          .map((item) =>
              {'value': item['id'], 'label': item['nomeFantasia']?.toString() ?? ''})
          .toList();
    }
    return [];
  }
}
