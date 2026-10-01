import '../../models/categoria_financeira_model.dart';
import '../../models/centro_custo_model.dart';
import '../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';

class FinancialLookupLoader {
  FinancialLookupLoader._();

  static Future<List<Map<String, dynamic>>> loadCentrosCusto() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allCentrosCusto);
    final dados = _extractList(response);
    return dados
        .map((item) => CentroCusto.fromJson(item))
        .where((item) => item.id != null)
        .map((item) => {
              'value': item.id.toString(),
              'label': item.nome?.trim().isNotEmpty == true
                  ? item.nome!.trim()
                  : 'Centro de custo ${item.id}',
            })
        .toList();
  }

  static Future<List<Map<String, dynamic>>> loadCategoriasFinanceiras() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allClassificacoes);
    final dados = _extractList(response);
    return dados
        .map((item) => CategoriaFinanceira.fromJson(item))
        .where((item) => item.id != null)
        .map((item) => {
              'value': item.id.toString(),
              'label': _categoriaLabel(item),
            })
        .toList();
  }

  static List<Map<String, dynamic>> _extractList(NetworkResponse response) {
    if (!response.isSuccess || response.body == null) {
      return const [];
    }

    final data = response.body!['data'];
    final rawList = data is Map ? data['dados'] ?? data['account'] ?? [] : data;
    if (rawList is! List) {
      return const [];
    }

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String _categoriaLabel(CategoriaFinanceira item) {
    final descricao = item.descricao?.trim();
    if (descricao != null && descricao.isNotEmpty) {
      return descricao;
    }
    return 'Categoria ${item.id}';
  }
}
