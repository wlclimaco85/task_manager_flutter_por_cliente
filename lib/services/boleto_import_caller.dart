import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class BoletoImportCaller {
  static Future<Map<String, dynamic>> importar({
    required List<Map<String, dynamic>> boletos,
  }) async {
    final url = TenantContext.applyToUrl(ApiLinks.importacaoBoletos) +
        '?empId=${TenantContext.empresaId}';
    final response = await http.post(
      Uri.parse(url),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode(boletos),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erro ${response.statusCode}: ${response.body}');
  }
}
