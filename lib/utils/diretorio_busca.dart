import 'string_utils.dart';

String _nome(Map<String, dynamic> d, String campo) =>
    StringUtils.normalizeForSearch(d[campo]?.toString() ?? '');

/// Diretorios em ordem alfabetica, sem diferenciar acento nem caixa (nao altera a lista original).
/// [campo] e a chave do texto exibido ('nome' nas listas da API, 'label' nos itens de dropdown).
List<Map<String, dynamic>> ordenarDiretoriosPorNome(List<Map<String, dynamic>> lista,
        {String campo = 'nome'}) =>
    [...lista]..sort((a, b) => _nome(a, campo).compareTo(_nome(b, campo)));

/// Filtra pelo texto contendo [busca] (sem acento/caixa); busca vazia devolve tudo.
List<Map<String, dynamic>> filtrarDiretoriosPorNome(
    List<Map<String, dynamic>> lista, String? busca,
    {String campo = 'nome'}) {
  final termo = StringUtils.normalizeForSearch(busca ?? '');
  if (termo.isEmpty) return lista;
  return lista.where((d) => _nome(d, campo).contains(termo)).toList();
}
