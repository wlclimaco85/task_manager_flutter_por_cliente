import 'string_utils.dart';

String _nome(Map<String, dynamic> d) =>
    StringUtils.normalizeForSearch(d['nome']?.toString() ?? '');

/// Diretorios em ordem alfabetica, sem diferenciar acento nem caixa (nao altera a lista original).
List<Map<String, dynamic>> ordenarDiretoriosPorNome(List<Map<String, dynamic>> lista) =>
    [...lista]..sort((a, b) => _nome(a).compareTo(_nome(b)));

/// Filtra pelo nome contendo [busca] (sem acento/caixa); busca vazia devolve tudo.
List<Map<String, dynamic>> filtrarDiretoriosPorNome(
    List<Map<String, dynamic>> lista, String? busca) {
  final termo = StringUtils.normalizeForSearch(busca ?? '');
  if (termo.isEmpty) return lista;
  return lista.where((d) => _nome(d).contains(termo)).toList();
}
