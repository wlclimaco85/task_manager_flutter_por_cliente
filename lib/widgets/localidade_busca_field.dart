import 'package:flutter/material.dart';

import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import 'mdfe_emissao_view.dart' show listaMdfeDe;
import 'searchable_dropdown.dart';

/// Busca municipios na tabela `cidade` (ja cadastrada, com IBGE e estado) pelo nome digitado.
/// Cada item volta como `{id: <ibge>, nome: 'Uberaba - MG', cidade: 'Uberaba', uf: 'MG'}`.
Future<List<Map<String, dynamic>>> buscarMunicipiosCadastrados(String termo) async {
  try {
    final r = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/cidade?nome=${Uri.encodeQueryComponent(termo.trim())}&tamanho=50');
    if (!r.isSuccess) {
      AppLogger.i.warn('buscarMunicipiosCadastrados: HTTP ${r.statusCode}');
      return [];
    }
    final saida = <Map<String, dynamic>>[];
    for (final c in listaMdfeDe(r.body)) {
      final ibge = '${c['ibge'] ?? ''}'.trim();
      final nome = '${c['nome'] ?? ''}'.trim();
      final estado = c['estado'];
      final uf = estado is Map ? '${estado['uf'] ?? ''}'.trim() : '';
      if (ibge.length != 7 || nome.isEmpty || uf.isEmpty) continue; // sem IBGE valido nao serve para documento fiscal
      saida.add({
        'id': ibge,
        'nome': uf.isEmpty ? nome : '$nome - $uf',
        'cidade': nome,
        'uf': uf,
      });
    }
    return saida;
  } catch (e, st) {
    AppLogger.i.error('buscarMunicipiosCadastrados: erro: $e', st);
    return [];
  }
}

List<Map<String, dynamic>>? _estadosCache;

/// Estados (UF + nome) da tabela `estado` do Brasil. Em falha de rede devolve vazio
/// (quem chama usa [ufsFallback]) e nao guarda cache.
Future<List<Map<String, dynamic>>> carregarEstadosCadastrados() async {
  final cache = _estadosCache;
  if (cache != null) return cache;
  try {
    final net = NetworkCaller();
    final paises = await net.getRequest(ApiLinks.buscarPaises);
    if (!paises.isSuccess) return [];
    final lista = listaMdfeDe(paises.body);
    if (lista.isEmpty) return [];
    final brasil = lista.firstWhere(
      (p) => '${p['nome']}'.toLowerCase().startsWith('brasil'),
      orElse: () => lista.first,
    );
    final r = await net.getRequest(ApiLinks.fecthEstadoByPais + '${brasil['id']}');
    if (!r.isSuccess) return [];
    final estados = <Map<String, dynamic>>[
      for (final e in listaMdfeDe(r.body))
        if ('${e['uf'] ?? ''}'.trim().isNotEmpty)
          {
            'id': '${e['uf']}'.trim(),
            'nome': '${e['uf']}'.trim() == '${e['nome']}'.trim()
                ? '${e['uf']}'.trim()
                : '${e['uf']} - ${e['nome']}',
          }
    ]..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
    if (estados.isNotEmpty) _estadosCache = estados;
    return estados;
  } catch (e, st) {
    AppLogger.i.error('carregarEstadosCadastrados: erro: $e', st);
    return [];
  }
}

/// Municipio por busca remota na tabela `cidade`: grava o IBGE e o nome nos controllers
/// do formulario e avisa a UF escolhida. Substitui os campos soltos IBGE + municipio (+ UF).
class MunicipioBuscaField extends StatefulWidget {
  final String label;
  final TextEditingController ibge;
  final TextEditingController nome;
  final ValueChanged<String?>? onUf;
  final bool obrigatorio;
  final bool enabled;

  const MunicipioBuscaField({
    super.key,
    required this.label,
    required this.ibge,
    required this.nome,
    this.onUf,
    this.obrigatorio = true,
    this.enabled = true,
  });

  @override
  State<MunicipioBuscaField> createState() => _MunicipioBuscaFieldState();
}

class _MunicipioBuscaFieldState extends State<MunicipioBuscaField> {
  final List<Map<String, dynamic>> _itens = [];
  String? _rotulo;

  @override
  Widget build(BuildContext context) {
    final atual = widget.ibge.text.trim();
    return SearchableDropdownField(
      label: widget.label,
      enabled: widget.enabled,
      value: atual.isEmpty ? null : atual,
      items: _itens,
      valueField: 'id',
      displayField: 'nome',
      nullable: false,
      hintText: _rotulo ?? (atual.isEmpty ? 'Buscar município' : '${widget.nome.text} ($atual)'),
      onSearch: buscarMunicipiosCadastrados,
      validator: (_) => (widget.obrigatorio && widget.ibge.text.trim().length != 7)
          ? 'Selecione o município'
          : null,
      onChanged: (_) {},
      onItemSelected: (item) {
        if (item == null) return;
        widget.ibge.text = '${item['id']}';
        widget.nome.text = '${item['cidade']}';
        widget.onUf?.call('${item['uf']}'.isEmpty ? null : '${item['uf']}');
        setState(() {
          _rotulo = '${item['nome']}';
          if (!_itens.any((e) => e['id'] == item['id'])) _itens.insert(0, item);
        });
      },
    );
  }
}

/// UF por busca na tabela `estado`. Se o cadastro nao carregar, cai na lista fixa [ufsFallback].
class UfBuscaField extends StatefulWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final List<String> ufsFallback;
  final String? Function(String?)? validator;

  const UfBuscaField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.ufsFallback,
    this.validator,
  });

  @override
  State<UfBuscaField> createState() => _UfBuscaFieldState();
}

class _UfBuscaFieldState extends State<UfBuscaField> {
  List<Map<String, dynamic>> _estados = [];

  @override
  void initState() {
    super.initState();
    carregarEstadosCadastrados().then((l) {
      if (mounted) setState(() => _estados = l);
    });
  }

  List<Map<String, dynamic>> get _itens => _estados.isNotEmpty
      ? _estados
      : [for (final uf in widget.ufsFallback) {'id': uf, 'nome': uf}];

  @override
  Widget build(BuildContext context) {
    final itens = _itens;
    return SearchableDropdownField(
      label: widget.label,
      value: itens.any((e) => e['id'] == widget.value) ? widget.value : null,
      items: itens,
      valueField: 'id',
      displayField: 'nome',
      nullable: false,
      validator: widget.validator,
      onChanged: widget.onChanged,
    );
  }
}
