import '../models/network_response.dart';
import '../utils/api_links.dart';
import 'network_caller.dart';

class ConsultaCnpjService {
  ConsultaCnpjService._();

  /// Consulta dados de CNPJ no backend ou fallback ReceitaWS.
  /// Retorna os dados cadastrais estruturados ou null se falhar/inválido.
  static Future<Map<String, dynamic>?> consultar(String cnpjRaw) async {
    final cnpj = cnpjRaw.replaceAll(RegExp(r'\D'), '');
    if (cnpj.length != 14) return null;

    try {
      // 1. Tenta endpoint backend /api/receitaws/cnpj/{cnpj}
      var resp = await NetworkCaller()
          .getRequest('${ApiLinks.baseUrl}/api/receitaws/cnpj/$cnpj');
      if (resp.isSuccess && resp.body != null && resp.body is Map) {
        final b = resp.body as Map;
        final data = b['data'] is Map ? b['data'] as Map : b;
        return Map<String, dynamic>.from(data);
      }

      // 2. Fallback backend /api/parceiro/consulta-cnpj/{cnpj}
      resp = await NetworkCaller()
          .getRequest('${ApiLinks.baseUrl}/api/parceiro/consulta-cnpj/$cnpj');
      if (resp.isSuccess && resp.body != null && resp.body is Map) {
        final b = resp.body as Map;
        if (b['data'] != null && b['data'] is Map) {
          return Map<String, dynamic>.from(b['data'] as Map);
        }
      }

      // 3. Fallback direto ReceitaWS pública
      final directResp = await NetworkCaller()
          .getRequest('https://www.receitaws.com.br/v1/cnpj/$cnpj');
      if (directResp.isSuccess &&
          directResp.body != null &&
          directResp.body is Map) {
        final b = directResp.body as Map;
        if (b['status'] == 'OK' || b['nome'] != null) {
          return {
            'nome': b['nome'],
            'razaoSocial': b['nome'],
            'nomeFantasia': b['fantasia'],
            'logradouro': b['logradouro'],
            'rua': b['logradouro'],
            'numero': b['numero'],
            'complemento': b['complemento'],
            'bairro': b['bairro'],
            'municipio': b['municipio'],
            'cidade': b['municipio'],
            'uf': b['uf'],
            'estado': b['uf'],
            'cep': b['cep'],
            'telefone': b['telefone'],
            'email': b['email'],
            'situacao': b['situacao'],
          };
        }
      }
    } catch (_) {}
    return null;
  }
}
