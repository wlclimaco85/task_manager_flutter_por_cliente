import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../utils/diretorio_busca.dart';

class DiretorioCaller {
  Future<List<Map<String, dynamic>>> fetchDiretoriosDropdown() async {
    // tamanho alto: sem ele o backend devolve so 25 e diretorios ficavam de fora do seletor
    final response =
        await NetworkCaller().getRequest('${ApiLinks.allDiretorios}?tamanho=1000');
    if (response.isSuccess && response.body != null) {
      final data = response.body!['data']['dados'] ?? [];
      final itens = (data as List)
          .map<Map<String, dynamic>>((item) => {
                'value': item['id'],
                'label': item['nome'],
              })
          .toList();
      return ordenarDiretoriosPorNome(itens, campo: 'label');
    }
    return [];
  }
}
