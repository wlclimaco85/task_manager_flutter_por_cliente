import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class PlanilhaResumo {
  final int id;
  final String nome;
  const PlanilhaResumo(this.id, this.nome);
}

class PlanilhaDados {
  final int? id;
  final String nome;
  final Map<String, String> celulas;
  const PlanilhaDados({this.id, required this.nome, required this.celulas});
}

class ConsultaPlanilha {
  final List<String> colunas;
  final List<List<Object?>> linhas;
  final bool truncado;
  const ConsultaPlanilha(this.colunas, this.linhas, this.truncado);
}

class PlanilhaException implements Exception {
  final String mensagem;
  const PlanilhaException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Planilhas: cadastro, importacao/exportacao Excel (feitas no servidor) e consulta aos dados do sistema.
class PlanilhaService {
  String get _raiz => ApiLinks.planilhas;

  Future<List<PlanilhaResumo>> listar() async {
    final dados = _json(await TenantContext.get(_raiz), 'listar as planilhas') as List;
    return [for (final p in dados) PlanilhaResumo((p['id'] as num).toInt(), '${p['nome']}')];
  }

  Future<PlanilhaDados> abrir(int id) async =>
      _planilha(_json(await TenantContext.get('$_raiz/$id'), 'abrir a planilha'));

  Future<PlanilhaDados> salvar(PlanilhaDados p) async {
    final corpo = {'nome': p.nome, 'celulas': p.celulas};
    final r = p.id == null
        ? await TenantContext.post(_raiz, corpo)
        : await TenantContext.put('$_raiz/${p.id}', corpo);
    return _planilha(_json(r, 'salvar a planilha'));
  }

  Future<void> excluir(int id) async {
    final r = await TenantContext.delete('$_raiz/$id');
    if (r.statusCode != 204) _json(r, 'excluir a planilha');
  }

  Future<Map<String, String>> importar(List<int> bytes, String nomeArquivo) async {
    final r = await TenantContext.postMultipart('$_raiz/importar',
        fileBytes: bytes, fileName: nomeArquivo, fileField: 'file');
    return _celulas(_json(r, 'importar o Excel')['celulas']);
  }

  Future<List<int>> exportar(PlanilhaDados p) async {
    final r = await TenantContext.post('$_raiz/exportar', {'nome': p.nome, 'celulas': p.celulas});
    if (r.statusCode != 200) _json(r, 'exportar para Excel');
    return r.bodyBytes;
  }

  /// SELECT somente leitura (so MASTER; o servidor exige o filtro :empresaId).
  Future<ConsultaPlanilha> consultar(String sql) async {
    final j = _json(await TenantContext.post('$_raiz/consultar', {'sql': sql}), 'executar a consulta');
    return ConsultaPlanilha(
      [for (final c in j['colunas'] as List) '$c'],
      [for (final l in j['linhas'] as List) List<Object?>.from(l as List)],
      j['truncado'] == true,
    );
  }

  Future<List<String>> tabelas() async {
    final j = _json(await TenantContext.get(ApiLinks.queryBuilderTabelas), 'listar as tabelas');
    final lista = j['data']['data'] as List;
    return [for (final t in lista) '${t['schema']}.${t['nome']}']..sort();
  }

  Future<List<String>> colunas(String tabelaComSchema) async {
    final partes = tabelaComSchema.split('.');
    final j = _json(
        await TenantContext.get(ApiLinks.queryBuilderColunas(partes.first, partes.last)), 'listar as colunas');
    return [for (final c in j['data']['data'] as List) '${c['nome']}'];
  }

  static PlanilhaDados _planilha(dynamic j) => PlanilhaDados(
      id: (j['id'] as num?)?.toInt(), nome: '${j['nome']}', celulas: _celulas(j['celulas']));

  static Map<String, String> _celulas(dynamic j) =>
      {for (final e in (j as Map).entries) '${e.key}': '${e.value}'};

  static dynamic _json(http.Response r, String acao) {
    dynamic corpo;
    try {
      corpo = jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      corpo = null;
    }
    if (r.statusCode >= 200 && r.statusCode < 300 && corpo != null) return corpo;
    if (r.statusCode == 403) {
      throw PlanilhaException('Sem permissão para $acao.');
    }
    final msg = corpo is Map ? (corpo['message'] ?? corpo['error'])?.toString() : null;
    throw PlanilhaException(msg ?? 'Não foi possível $acao (HTTP ${r.statusCode}).');
  }
}
