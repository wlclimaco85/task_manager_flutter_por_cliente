import '../../models/network_response.dart';
import '../utils/api_links.dart';
import 'network_caller.dart';

class RegraFiscalCaller {
  static Future<NetworkResponse> listar() async {
    return NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/fiscal/regras');
  }

  static Future<NetworkResponse> salvar(Map<String, dynamic> body) async {
    return NetworkCaller().postRequest(
      '${ApiLinks.baseUrl}/api/fiscal/regras',
      body,
    );
  }

  static Future<NetworkResponse> atualizar(
      int id, Map<String, dynamic> body) async {
    return NetworkCaller().putRequest(
      '${ApiLinks.baseUrl}/api/fiscal/regras/$id',
      body,
    );
  }

  static Future<NetworkResponse> excluir(int id) async {
    return NetworkCaller().deleteRequest(
      '${ApiLinks.baseUrl}/api/fiscal/regras/$id',
    );
  }

  static Future<NetworkResponse> validar(Map<String, dynamic> body) async {
    return NetworkCaller().postRequest(
      '${ApiLinks.baseUrl}/api/fiscal/regras/validar',
      body,
    );
  }
}
