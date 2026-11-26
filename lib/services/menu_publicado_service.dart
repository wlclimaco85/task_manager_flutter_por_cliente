import 'dart:convert';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/menu_config.dart';
import '../utils/tenant_context.dart';
import 'planilha_service.dart';

/// Item criado pela empresa (PLANILHA, RELATORIO ou TELA) publicado no menu. Permissao: telaNome "pub_{id}".
class ItemPublicado {
  final int id;
  final String tipo;
  final int refId;
  final String titulo;
  final String grupo;

  const ItemPublicado(
      {required this.id, required this.tipo, required this.refId, required this.titulo, required this.grupo});

  String get menuId => 'pub_$id';
  int get indice => MenuConfig.kIndicePublicado + id;

  factory ItemPublicado.fromJson(Map<String, dynamic> j) => ItemPublicado(
        id: (j['id'] as num).toInt(),
        tipo: '${j['tipo']}',
        refId: (j['refId'] as num).toInt(),
        titulo: '${j['titulo']}',
        grupo: '${j['grupo']}',
      );

  MenuItem get menuItem => MenuItem(
        id: menuId,
        label: titulo,
        icon: switch (tipo) {
          'RELATORIO' => FontAwesomeIcons.filePdf,
          'TELA' => FontAwesomeIcons.tableList,
          _ => FontAwesomeIcons.table,
        },
        screenIndex: indice,
      );
}

class FonteModelo {
  final String celula;
  final String sql;
  final bool cabecalho;
  final Map<String, String> rotulos;

  const FonteModelo({required this.celula, required this.sql, this.cabecalho = true, this.rotulos = const {}});

  factory FonteModelo.fromJson(Map<String, dynamic> j) => FonteModelo(
        celula: '${j['celula']}',
        sql: '${j['sql']}',
        cabecalho: j['cabecalho'] == true,
        rotulos: {for (final e in ((j['rotulos'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
      );

  Map<String, dynamic> toJson() => {'celula': celula, 'sql': sql, 'cabecalho': cabecalho, 'rotulos': rotulos};
}

class ModeloPlanilha {
  final int? id;
  final String titulo;
  final String? descricao;
  final Map<String, String> celulas;
  final List<FonteModelo> fontes;

  const ModeloPlanilha(
      {this.id, required this.titulo, this.descricao, this.celulas = const {}, this.fontes = const []});

  factory ModeloPlanilha.fromJson(Map<String, dynamic> j) => ModeloPlanilha(
        id: (j['id'] as num?)?.toInt(),
        titulo: '${j['titulo']}',
        descricao: j['descricao']?.toString(),
        celulas: {for (final e in ((j['celulas'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
        fontes: [for (final f in (j['fontes'] as List?) ?? const []) FonteModelo.fromJson(f as Map<String, dynamic>)],
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descricao': descricao,
        'celulas': celulas,
        'fontes': [for (final f in fontes) f.toJson()],
      };
}

class ModeloAberto {
  final String titulo;
  final Map<String, String> celulas;
  final bool truncado;
  const ModeloAberto(this.titulo, this.celulas, this.truncado);
}

class RoleResumo {
  final int id;
  final String nome;
  const RoleResumo(this.id, this.nome);
}

/// Modelos de planilha e menu dinamico.
class MenuPublicadoService {
  static List<ItemPublicado> _atuais = const [];

  static List<ItemPublicado> get atuais => _atuais;

  static ItemPublicado? porIndice(int indice) {
    for (final i in _atuais) {
      if (i.indice == indice) return i;
    }
    return null;
  }

  static void aplicarNoMenu(List<ItemPublicado> itens) {
    _atuais = itens;
    MenuConfig.definirPublicados([for (final i in itens) (i.grupo, i.menuItem)]);
  }

  /// Carrega os itens publicados no menu. Falha nunca derruba a tela: so registra no log.
  Future<void> carregarNoMenu() async {
    try {
      aplicarNoMenu(await publicados());
    } catch (e) {
      AppLogger.i.warn('Menu publicado: nao foi possivel carregar: $e');
      aplicarNoMenu(const []);
    }
  }

  Future<List<ItemPublicado>> publicados() async {
    final lista = _json(await TenantContext.get(ApiLinks.menuPublicado), 'listar o menu') as List;
    return [for (final i in lista) ItemPublicado.fromJson(i as Map<String, dynamic>)];
  }

  Future<ItemPublicado> publicar(String tipo, int refId, String titulo, String grupo) async {
    final r = await TenantContext.post(
        ApiLinks.menuPublicado, {'tipo': tipo, 'refId': refId, 'titulo': titulo, 'grupo': grupo});
    return ItemPublicado.fromJson(_json(r, 'publicar no menu') as Map<String, dynamic>);
  }

  Future<void> despublicar(int id) async {
    final r = await TenantContext.delete('${ApiLinks.menuPublicado}/$id');
    if (r.statusCode != 204) _json(r, 'tirar do menu');
  }

  Future<List<RoleResumo>> roles() async {
    final j = _json(await TenantContext.get('${ApiLinks.baseUrl}/api/role?tamanho=1000'), 'listar as roles');
    return [
      for (final r in (j['data']?['dados'] ?? const []) as List)
        RoleResumo((r['id'] as num).toInt(), '${r['description'] ?? r['key']}')
    ];
  }

  /// Ids das roles com "Ver" no item (mesma tabela do Controle de Acesso).
  Future<Set<int>> rolesComAcesso(String telaNome) async {
    final j = _json(
        await TenantContext.get('${ApiLinks.baseUrl}/api/role-permissao/all'), 'listar as permissões');
    return {
      for (final p in (j['data']?['dados'] ?? const []) as List)
        if (p['telaNome'] == telaNome && p['podeVer'] == true) (p['roleId'] as num).toInt()
    };
  }

  /// Grava somente o que mudou, pela API do Controle de Acesso.
  Future<void> gravarAcessos(String telaNome, Map<int, bool> alterados) async {
    if (alterados.isEmpty) return;
    final r = await http.post(
      Uri.parse('${ApiLinks.baseUrl}/api/role-permissao/batch'),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode([
        for (final e in alterados.entries)
          {'roleId': e.key, 'telaNome': telaNome, 'podeVer': e.value}
      ]),
    );
    _json(r, 'gravar as permissões');
  }

  Future<List<ModeloPlanilha>> modelos() async {
    final lista = _json(await TenantContext.get(ApiLinks.planilhaModelos), 'listar os modelos') as List;
    return [for (final m in lista) ModeloPlanilha.fromJson(m as Map<String, dynamic>)];
  }

  Future<ModeloPlanilha> modelo(int id) async => ModeloPlanilha.fromJson(
      _json(await TenantContext.get('${ApiLinks.planilhaModelos}/$id'), 'abrir o modelo') as Map<String, dynamic>);

  Future<ModeloPlanilha> salvarModelo(ModeloPlanilha m) async {
    final r = m.id == null
        ? await TenantContext.post(ApiLinks.planilhaModelos, m.toJson())
        : await TenantContext.put('${ApiLinks.planilhaModelos}/${m.id}', m.toJson());
    return ModeloPlanilha.fromJson(_json(r, 'salvar o modelo') as Map<String, dynamic>);
  }

  Future<void> excluirModelo(int id) async {
    final r = await TenantContext.delete('${ApiLinks.planilhaModelos}/$id');
    if (r.statusCode != 204) _json(r, 'excluir o modelo');
  }

  /// Abre o modelo com os dados atuais (o servidor executa as consultas; o SQL nao vem para o app).
  Future<ModeloAberto> abrirModelo(int id) async {
    final j = _json(await TenantContext.get('${ApiLinks.planilhaModelos}/$id/abrir'), 'abrir a planilha');
    return ModeloAberto('${j['titulo']}',
        {for (final e in (j['celulas'] as Map).entries) '${e.key}': '${e.value}'}, j['truncado'] == true);
  }

  static dynamic _json(http.Response r, String acao) {
    dynamic corpo;
    try {
      corpo = jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      corpo = null;
    }
    if (r.statusCode >= 200 && r.statusCode < 300 && corpo != null) return corpo;
    final msg = corpo is Map ? (corpo['message'] ?? corpo['error'])?.toString() : null;
    if (r.statusCode == 403) throw PlanilhaException(msg ?? 'Sem permissão para $acao.');
    throw PlanilhaException(msg ?? 'Não foi possível $acao (HTTP ${r.statusCode}).');
  }
}
