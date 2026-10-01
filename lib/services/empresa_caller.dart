import '../models/network_response.dart';
import './network_caller.dart';
import '../utils/api_links.dart';

class EmpresaCaller {
  /// Dropdown de empresas para uso em formulários
  static Future<List<Map<String, dynamic>>> loadEmpresas() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allEmpresas);
    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map((item) =>
              {'value': item['id'], 'label': item['nomeFantasia']?.toString() ?? ''})
          .toList();
    }
    return [];
  }
}
