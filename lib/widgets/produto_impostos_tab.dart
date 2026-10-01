import 'package:flutter/material.dart';

import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/dropdown_helpers.dart';
import '../utils/grid_colors.dart';

// ── Funcoes puras (testaveis sem rede/widget) ──────────────────────────────
//
// NetworkCaller usa as funcoes top-level de package:http diretamente (sem
// client injetavel), entao a logica de rede em si nao e testavel sem
// infraestrutura adicional (mesmo padrao ja documentado em
// test/utils/dropdown_helpers_busca_test.dart). Por isso a logica de
// classificacao/validacao/montagem de payload foi extraida em funcoes puras
// abaixo, testadas em produto_impostos_tab_test.dart.

/// Separa a lista de configs fiscais do produto em regra padrão (sem UF,
/// no máximo 1) e exceções por UF (ordenadas por sigla).
({Map<String, dynamic>? regraPadrao, List<Map<String, dynamic>> excecoesPorUf})
    separarRegraPadraoEExcecoes(List<Map<String, dynamic>> configs) {
  Map<String, dynamic>? regraPadrao;
  final excecoes = <Map<String, dynamic>>[];
  for (final c in configs) {
    if (c['estadoId'] == null) {
      regraPadrao ??= c;
    } else {
      excecoes.add(c);
    }
  }
  excecoes.sort(
      (a, b) => (a['uf']?.toString() ?? '').compareTo(b['uf']?.toString() ?? ''));
  return (regraPadrao: regraPadrao, excecoesPorUf: excecoes);
}

/// Converte o texto de um campo numérico fiscal (aceita vírgula ou ponto)
/// para double, ou nulo quando em branco.
double? parseNumeroFiscal(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return null;
  return double.tryParse(t.replaceAll(',', '.'));
}

/// Validador de campo numérico fiscal (alíquotas etc.): em branco é válido
/// (campo opcional), texto não numérico ou negativo é inválido.
String? validarNumeroFiscal(String? valor) {
  if (valor == null || valor.trim().isEmpty) return null;
  final v = double.tryParse(valor.trim().replaceAll(',', '.'));
  if (v == null) return 'Valor numérico inválido';
  if (v < 0) return 'Não pode ser negativo';
  return null;
}

/// Mensagem de erro exibida quando o backend responde 400 ao salvar —
/// distingue duplicidade de regra padrão de duplicidade de exceção por UF
/// (IMP-07: "erro esperado ao tentar duplicar regra padrão").
String mensagemErroSalvar(int statusCode, {required bool isRegraPadrao}) {
  if (statusCode == 400) {
    return isRegraPadrao
        ? 'Já existe uma regra padrão cadastrada para este produto.'
        : 'Já existe uma exceção cadastrada para esta UF neste produto.';
  }
  return 'Erro ao salvar ($statusCode)';
}

String montarUrlCopiarImpostos({
  required int origemProdutoId,
  required int destinoProdutoId,
}) {
  return '${ApiLinks.baseUrl}/api/produto-imposto-uf/copiar'
      '?origemProdutoId=$origemProdutoId&destinoProdutoId=$destinoProdutoId';
}

List<Map<String, dynamic>> filtrarProdutosDestinoImpostos(
  List<Map<String, dynamic>> produtos,
  int origemProdutoId,
) {
  return produtos
      .where((p) => p['id']?.toString() != origemProdutoId.toString())
      .toList();
}

String labelProdutoParaCopiarImpostos(Map<String, dynamic> produto) {
  final codigo = produto['codigo']?.toString().trim() ?? '';
  final nome = (produto['nome'] ?? produto['descricao'] ?? produto['id'])
          ?.toString()
          .trim() ??
      '';
  if (codigo.isNotEmpty && nome.isNotEmpty) return '$codigo - $nome';
  if (nome.isNotEmpty) return nome;
  return codigo.isNotEmpty ? codigo : 'Produto sem nome';
}

// ── Tabelas fiscais fechadas (Receita Federal / SEFAZ) ─────────────────────
// Bug de producao: campos que sao tabela fechada da Receita (CST/CSOSN, CST
// IBS/CBS) estavam como texto livre -- usuario podia digitar qualquer coisa,
// inclusive codigo invalido que a SEFAZ rejeita na emissao. Convertidos pra
// dropdown com os valores oficiais.
//
// CST (Convenio s/no de 1970, Anexo I Tabela B) -- regime normal (CRT=3).
const List<Map<String, String>> kOpcoesCst = [
  {'value': '00', 'label': '00 - Tributada integralmente'},
  {'value': '10', 'label': '10 - Tributada com ST'},
  {'value': '20', 'label': '20 - Com redução de base de cálculo'},
  {'value': '30', 'label': '30 - Isenta/não tributada com ST'},
  {'value': '40', 'label': '40 - Isenta'},
  {'value': '41', 'label': '41 - Não tributada'},
  {'value': '50', 'label': '50 - Suspensão'},
  {'value': '51', 'label': '51 - Diferimento'},
  {'value': '60', 'label': '60 - ICMS cobrado anteriormente por ST'},
  {'value': '70', 'label': '70 - Redução de BC com cobrança de ST'},
  {'value': '90', 'label': '90 - Outras'},
];

// CSOSN (Anexo III-A) -- Simples Nacional (CRT=1,2,4).
const List<Map<String, String>> kOpcoesCsosn = [
  {'value': '101', 'label': '101 - Tributada c/ permissão de crédito'},
  {'value': '102', 'label': '102 - Tributada s/ permissão de crédito'},
  {'value': '103', 'label': '103 - Isenção (faixa de receita bruta)'},
  {'value': '201', 'label': '201 - Tributada c/ crédito e com ST'},
  {'value': '202', 'label': '202 - Tributada s/ crédito e com ST'},
  {'value': '203', 'label': '203 - Isenção (faixa de receita) e com ST'},
  {'value': '300', 'label': '300 - Imune'},
  {'value': '400', 'label': '400 - Não tributada pelo Simples Nacional'},
  {'value': '500', 'label': '500 - ICMS cobrado anteriormente por ST'},
  {'value': '900', 'label': '900 - Outros'},
];

// CST IPI (Tabela do IPI -- Anexo do leiaute NF-e/Convenio ICMS 07/2000).
const List<Map<String, String>> kOpcoesCstIpi = [
  {'value': '00', 'label': '00 - Entrada com recuperação de crédito'},
  {'value': '01', 'label': '01 - Entrada tributada com alíquota zero'},
  {'value': '02', 'label': '02 - Entrada isenta'},
  {'value': '03', 'label': '03 - Entrada não-tributada'},
  {'value': '04', 'label': '04 - Entrada imune'},
  {'value': '05', 'label': '05 - Entrada com suspensão'},
  {'value': '49', 'label': '49 - Outras entradas'},
  {'value': '50', 'label': '50 - Saída tributada'},
  {'value': '51', 'label': '51 - Saída tributada com alíquota zero'},
  {'value': '52', 'label': '52 - Saída isenta'},
  {'value': '53', 'label': '53 - Saída não-tributada'},
  {'value': '54', 'label': '54 - Saída imune'},
  {'value': '55', 'label': '55 - Saída com suspensão'},
  {'value': '99', 'label': '99 - Outras saídas'},
];

// CST PIS e CST COFINS (Tabelas 4.3.4/4.3.5 do MOC NF-e, Nota Tecnica
// 2016.002) -- mesma tabela de codigos pras duas contribuicoes.
const List<Map<String, String>> kOpcoesCstPisCofins = [
  {'value': '01', 'label': '01 - Tributável (alíquota normal)'},
  {'value': '02', 'label': '02 - Tributável (alíquota diferenciada)'},
  {'value': '03', 'label': '03 - Tributável (qtd vendida x alíquota unidade)'},
  {'value': '04', 'label': '04 - Tributável (monofásica - alíquota zero)'},
  {'value': '05', 'label': '05 - Tributável (Substituição Tributária)'},
  {'value': '06', 'label': '06 - Tributável (alíquota zero)'},
  {'value': '07', 'label': '07 - Isenta da contribuição'},
  {'value': '08', 'label': '08 - Sem incidência da contribuição'},
  {'value': '09', 'label': '09 - Com suspensão da contribuição'},
  {'value': '49', 'label': '49 - Outras operações de saída'},
  {'value': '50', 'label': '50 - Direito a crédito - receita trib. interno'},
  {'value': '51', 'label': '51 - Direito a crédito - receita não trib. interno'},
  {'value': '52', 'label': '52 - Direito a crédito - receita de exportação'},
  {'value': '53', 'label': '53 - Direito a crédito - trib. e não trib. interno'},
  {'value': '54', 'label': '54 - Direito a crédito - trib. interno e exportação'},
  {'value': '55', 'label': '55 - Direito a crédito - não trib. interno e exportação'},
  {'value': '56', 'label': '56 - Direito a crédito - trib./não trib. interno e exportação'},
  {'value': '60', 'label': '60 - Crédito presumido - receita trib. interno'},
  {'value': '61', 'label': '61 - Crédito presumido - receita não trib. interno'},
  {'value': '62', 'label': '62 - Crédito presumido - receita de exportação'},
  {'value': '63', 'label': '63 - Crédito presumido - trib. e não trib. interno'},
  {'value': '64', 'label': '64 - Crédito presumido - trib. interno e exportação'},
  {'value': '65', 'label': '65 - Crédito presumido - não trib. interno e exportação'},
  {'value': '66', 'label': '66 - Crédito presumido - trib./não trib. interno e exportação'},
  {'value': '67', 'label': '67 - Crédito presumido - outras operações'},
  {'value': '70', 'label': '70 - Aquisição sem direito a crédito'},
  {'value': '71', 'label': '71 - Aquisição com isenção'},
  {'value': '72', 'label': '72 - Aquisição com suspensão'},
  {'value': '73', 'label': '73 - Aquisição a alíquota zero'},
  {'value': '74', 'label': '74 - Aquisição sem incidência da contribuição'},
  {'value': '75', 'label': '75 - Aquisição por Substituição Tributária'},
  {'value': '98', 'label': '98 - Outras operações de entrada'},
  {'value': '99', 'label': '99 - Outras operações'},
];

// CST IBS/CBS (Nota Técnica NF-e 2025.002, Reforma Tributária).
const List<Map<String, String>> kOpcoesCstIbsCbs = [
  {'value': '000', 'label': '000 - Tributação integral'},
  {'value': '200', 'label': '200 - Alíquota reduzida'},
  {'value': '400', 'label': '400 - Isenção'},
  {'value': '410', 'label': '410 - Imunidade e não incidência'},
  {'value': '510', 'label': '510 - Diferimento'},
  {'value': '550', 'label': '550 - Suspensão'},
  {'value': '620', 'label': '620 - Tributação monofásica'},
  {'value': '800', 'label': '800 - Transferência de crédito'},
  {'value': '810', 'label': '810 - Ajustes'},
  {'value': '900', 'label': '900 - Outros'},
];

/// Aba "Impostos" do cadastro de Produto (card
/// https://trello.com/c/YooO4mOb): configura a regra fiscal padrão do
/// produto (ICMS, IPI, ISS, PIS/COFINS, IBS/CBS) e exceções por UF de
/// destino, consumindo o CRUD `GET/POST/PUT/DELETE /api/produto-imposto-uf`.
class ProdutoImpostosTab extends StatefulWidget {
  final int produtoId;

  const ProdutoImpostosTab({super.key, required this.produtoId});

  @override
  State<ProdutoImpostosTab> createState() => _ProdutoImpostosTabState();
}

class _ProdutoImpostosTabState extends State<ProdutoImpostosTab> {
  bool _carregando = true;
  bool _copiando = false;
  String? _erro;
  List<Map<String, dynamic>> _configs = [];
  List<Map<String, dynamic>> _estados = [];

  Map<String, dynamic>? get _regraPadrao =>
      separarRegraPadraoEExcecoes(_configs).regraPadrao;

  List<Map<String, dynamic>> get _excecoesPorUf =>
      separarRegraPadraoEExcecoes(_configs).excecoesPorUf;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final estados = await DropdownHelpers.estados();
    final resp = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/produto-imposto-uf?produtoId=${widget.produtoId}');

    if (!mounted) return;

    if (!resp.isSuccess) {
      setState(() {
        _carregando = false;
        _erro = 'Erro ao carregar configuração fiscal (${resp.statusCode})';
      });
      return;
    }

    final lista = resp.body?['data'];
    setState(() {
      _estados = estados;
      _configs = lista is List
          ? lista.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
      _carregando = false;
    });
  }

  Future<void> _abrirFormulario({Map<String, dynamic>? existente}) async {
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _ProdutoImpostoUfFormDialog(
        produtoId: widget.produtoId,
        estados: _estados,
        existente: existente,
        // Regra padrao ja cadastrada nao pode ser reaberta em "novo" pra virar duplicata.
        regraPadraoJaExiste: _regraPadrao != null,
      ),
    );
    if (salvo == true) {
      _carregarTudo();
    }
  }

  Future<void> _remover(Map<String, dynamic> config) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover configuração fiscal'),
        content: Text(config['estadoId'] == null
            ? 'Remover a regra padrão deste produto?'
            : 'Remover a exceção fiscal da UF ${config['uf'] ?? ''}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (confirmou != true) return;

    final resp = await NetworkCaller()
        .deleteRequest('${ApiLinks.baseUrl}/api/produto-imposto-uf/${config['id']}');
    if (!mounted) return;
    if (resp.isSuccess) {
      _carregarTudo();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao remover (${resp.statusCode})'),
          backgroundColor: GridColors.error));
    }
  }

  Future<void> _abrirCopiarImpostos() async {
    if (_configs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Este produto ainda não tem configuração fiscal para copiar.'),
        backgroundColor: GridColors.warning,
      ));
      return;
    }

    setState(() => _copiando = true);
    final produtos = filtrarProdutosDestinoImpostos(
      await DropdownHelpers.load(
        '${ApiLinks.baseUrl}/api/produto-contabil?tamanho=500&isServico=false',
        displayField: 'nome',
      ),
      widget.produtoId,
    );
    if (!mounted) return;
    setState(() => _copiando = false);

    final destinoProdutoId = await showDialog<int>(
      context: context,
      builder: (_) => _CopiarProdutoImpostosDialog(produtos: produtos),
    );
    if (destinoProdutoId == null) return;

    await _copiarImpostosParaProduto(destinoProdutoId);
  }

  Future<void> _copiarImpostosParaProduto(int destinoProdutoId) async {
    setState(() => _copiando = true);
    final resp = await NetworkCaller().postRequest(
      montarUrlCopiarImpostos(
        origemProdutoId: widget.produtoId,
        destinoProdutoId: destinoProdutoId,
      ),
      {},
    );
    if (!mounted) return;
    setState(() => _copiando = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(resp.isSuccess
          ? 'Configuração fiscal copiada para o produto selecionado.'
          : 'Erro ao copiar configuração fiscal (${resp.statusCode}).'),
      backgroundColor: resp.isSuccess ? GridColors.success : GridColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.produtoId <= 0) {
      return const Center(child: Text('ID do produto não disponível'));
    }
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Text(_erro!, style: const TextStyle(color: GridColors.error)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRegraPadraoSection(),
          const SizedBox(height: 24),
          _buildExcecoesSection(),
        ],
      ),
    );
  }

  Widget _buildRegraPadraoSection() {
    final regra = _regraPadrao;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule, color: GridColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Regra padrão (sem UF)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton.icon(
                onPressed: () => _abrirFormulario(existente: regra),
                icon: Icon(regra == null ? Icons.add : Icons.edit),
                label: Text(regra == null ? 'Configurar' : 'Editar'),
              ),
              TextButton.icon(
                onPressed:
                    _configs.isEmpty || _copiando ? null : _abrirCopiarImpostos,
                icon: const Icon(Icons.copy_all_outlined),
                label: Text(_copiando ? 'Copiando...' : 'Copiar'),
              ),
              if (regra != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: GridColors.error),
                  onPressed: () => _remover(regra),
                  tooltip: 'Remover regra padrão',
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (regra == null)
            const Text(
              'Este produto ainda não tem uma configuração fiscal padrão. '
              'Sem ela, a NF-e de saída não aplica ICMS/IPI/ISS/PIS/COFINS/IBS/CBS '
              'automaticamente a partir do cadastro do produto.',
              style: TextStyle(color: GridColors.textMuted),
            )
          else
            _buildResumoConfig(regra),
        ],
      ),
    );
  }

  Widget _buildExcecoesSection() {
    final excecoes = _excecoesPorUf;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.map_outlined, color: GridColors.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Exceções por UF de destino',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            TextButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar exceção'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (excecoes.isEmpty)
          const Text('Nenhuma exceção por UF cadastrada.',
              style: TextStyle(color: GridColors.textMuted))
        else
          ...excecoes.map(_buildExcecaoCard),
      ],
    );
  }

  Widget _buildExcecaoCard(Map<String, dynamic> config) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GridColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(config['uf']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _abrirFormulario(existente: config),
                tooltip: 'Editar',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: GridColors.error),
                onPressed: () => _remover(config),
                tooltip: 'Remover',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildResumoConfig(config),
        ],
      ),
    );
  }

  Widget _buildResumoConfig(Map<String, dynamic> config) {
    final itens = <String>[
      if (_isPreenchido(config['aliquotaIcms']))
        'ICMS ${_fmt(config['aliquotaIcms'])}%',
      if (_isPreenchido(config['aliqIpi'])) 'IPI ${_fmt(config['aliqIpi'])}%',
      if (_isPreenchido(config['aliqIss'])) 'ISS ${_fmt(config['aliqIss'])}%',
      if (_isPreenchido(config['pPis'])) 'PIS ${_fmt(config['pPis'])}%',
      if (_isPreenchido(config['pCofins']))
        'COFINS ${_fmt(config['pCofins'])}%',
      if (_isPreenchido(config['pIbsUf']) || _isPreenchido(config['pCbs']))
        'IBS/CBS ${_fmt(config['pIbsUf'])}%/${_fmt(config['pCbs'])}%',
    ];
    if (itens.isEmpty) {
      return const Text('Nenhuma alíquota preenchida ainda.',
          style: TextStyle(color: GridColors.textMuted));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: itens
          .map((t) => Chip(
                label: Text(t, style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              ))
          .toList(),
    );
  }

  bool _isPreenchido(dynamic v) => v != null && v.toString().isNotEmpty;

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = double.tryParse(v.toString()) ?? 0.0;
    return n.toStringAsFixed(2);
  }
}

class _CopiarProdutoImpostosDialog extends StatefulWidget {
  final List<Map<String, dynamic>> produtos;

  const _CopiarProdutoImpostosDialog({required this.produtos});

  @override
  State<_CopiarProdutoImpostosDialog> createState() =>
      _CopiarProdutoImpostosDialogState();
}

class _CopiarProdutoImpostosDialogState
    extends State<_CopiarProdutoImpostosDialog> {
  int? _produtoDestinoId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Copiar configuração fiscal'),
      content: SizedBox(
        width: 520,
        child: widget.produtos.isEmpty
            ? const Text('Nenhum outro produto disponível para receber a configuração fiscal.')
            : DropdownButtonFormField<int>(
                initialValue: _produtoDestinoId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Produto destino',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: widget.produtos
                    .map((produto) => DropdownMenuItem<int>(
                          value: int.tryParse(produto['id']?.toString() ?? ''),
                          child: Text(
                            labelProdutoParaCopiarImpostos(produto),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .where((item) => item.value != null)
                    .toList(),
                onChanged: (value) => setState(() => _produtoDestinoId = value),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _produtoDestinoId == null
              ? null
              : () => Navigator.of(context).pop(_produtoDestinoId),
          icon: const Icon(Icons.copy_all_outlined),
          label: const Text('Copiar'),
        ),
      ],
    );
  }
}

/// Formulário de criação/edição da config fiscal (regra padrão ou exceção
/// por UF). `existente` nulo = criação; UF nula = regra padrão.
class _ProdutoImpostoUfFormDialog extends StatefulWidget {
  final int produtoId;
  final List<Map<String, dynamic>> estados;
  final Map<String, dynamic>? existente;
  final bool regraPadraoJaExiste;

  const _ProdutoImpostoUfFormDialog({
    required this.produtoId,
    required this.estados,
    required this.existente,
    required this.regraPadraoJaExiste,
  });

  @override
  State<_ProdutoImpostoUfFormDialog> createState() =>
      _ProdutoImpostoUfFormDialogState();
}

class _ProdutoImpostoUfFormDialogState
    extends State<_ProdutoImpostoUfFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late bool _isRegraPadrao;
  dynamic _estadoId;
  bool _salvando = false;
  String? _erroServidor;

  // Dropdowns de tabela fechada (Receita/SEFAZ) -- nao usam TextEditingController.
  String? _cstCsosn;
  String? _cstIbsCbs;
  String? _cstIpi;
  String? _cstPis;
  String? _cstCofins;

  final _aliquotaIcmsCtrl = TextEditingController();
  final _aliqIcmsRedCtrl = TextEditingController();
  final _pRedBcCtrl = TextEditingController();
  final _aliqStCtrl = TextEditingController();

  final _aliqIpiCtrl = TextEditingController();
  final _codEnqIpiCtrl = TextEditingController();

  final _codTribIssCtrl = TextEditingController();
  final _aliqIssCtrl = TextEditingController();

  final _pPisCtrl = TextEditingController();

  final _pCofinsCtrl = TextEditingController();

  final _cClassTribCtrl = TextEditingController();
  final _pIbsUfCtrl = TextEditingController();
  final _pIbsMunCtrl = TextEditingController();
  final _pCbsCtrl = TextEditingController();

  bool get _editando => widget.existente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    _isRegraPadrao = e != null ? e['estadoId'] == null : !widget.regraPadraoJaExiste;
    _estadoId = e?['estadoId'];

    _cstCsosn = _blankToNullStatic(e?['cstCsosn']?.toString());
    _aliquotaIcmsCtrl.text = _asText(e?['aliquotaIcms']);
    _aliqIcmsRedCtrl.text = _asText(e?['aliqIcmsRed']);
    _pRedBcCtrl.text = _asText(e?['pRedBc']);
    _aliqStCtrl.text = _asText(e?['aliqSt']);

    _cstIpi = _blankToNullStatic(e?['cstIpi']?.toString());
    _aliqIpiCtrl.text = _asText(e?['aliqIpi']);
    _codEnqIpiCtrl.text = e?['codEnqIpi']?.toString() ?? '';

    _codTribIssCtrl.text = e?['codTribIss']?.toString() ?? '';
    _aliqIssCtrl.text = _asText(e?['aliqIss']);

    _cstPis = _blankToNullStatic(e?['cstPis']?.toString());
    _pPisCtrl.text = _asText(e?['pPis']);

    _cstCofins = _blankToNullStatic(e?['cstCofins']?.toString());
    _pCofinsCtrl.text = _asText(e?['pCofins']);

    _cstIbsCbs = _blankToNullStatic(e?['cstIbsCbs']?.toString());
    _cClassTribCtrl.text = e?['cClassTrib']?.toString() ?? '';
    _pIbsUfCtrl.text = _asText(e?['pIbsUf']);
    _pIbsMunCtrl.text = _asText(e?['pIbsMun']);
    _pCbsCtrl.text = _asText(e?['pCbs']);
  }

  String _asText(dynamic v) => v == null ? '' : v.toString();

  String? _blankToNullStatic(String? texto) =>
      (texto == null || texto.trim().isEmpty) ? null : texto.trim();

  @override
  void dispose() {
    for (final c in [
      _aliquotaIcmsCtrl,
      _aliqIcmsRedCtrl,
      _pRedBcCtrl,
      _aliqStCtrl,
      _aliqIpiCtrl,
      _codEnqIpiCtrl,
      _codTribIssCtrl,
      _aliqIssCtrl,
      _pPisCtrl,
      _pCofinsCtrl,
      _cClassTribCtrl,
      _pIbsUfCtrl,
      _pIbsMunCtrl,
      _pCbsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isRegraPadrao && _estadoId == null) {
      setState(() => _erroServidor = 'Selecione a UF da exceção.');
      return;
    }

    setState(() {
      _salvando = true;
      _erroServidor = null;
    });

    final body = <String, dynamic>{
      'produtoId': widget.produtoId,
      'estadoId': _isRegraPadrao ? null : _estadoId,
      'cstCsosn': _cstCsosn,
      'aliquotaIcms': _parseNum(_aliquotaIcmsCtrl.text),
      'aliqIcmsRed': _parseNum(_aliqIcmsRedCtrl.text),
      'pRedBc': _parseNum(_pRedBcCtrl.text),
      'aliqSt': _parseNum(_aliqStCtrl.text),
      'cstIpi': _cstIpi,
      'aliqIpi': _parseNum(_aliqIpiCtrl.text),
      'codEnqIpi': _blankToNull(_codEnqIpiCtrl.text),
      'codTribIss': _blankToNull(_codTribIssCtrl.text),
      'aliqIss': _parseNum(_aliqIssCtrl.text),
      'cstPis': _cstPis,
      'pPis': _parseNum(_pPisCtrl.text),
      'cstCofins': _cstCofins,
      'pCofins': _parseNum(_pCofinsCtrl.text),
      'cstIbsCbs': _cstIbsCbs,
      'cClassTrib': _blankToNull(_cClassTribCtrl.text),
      'pIbsUf': _parseNum(_pIbsUfCtrl.text),
      'pIbsMun': _parseNum(_pIbsMunCtrl.text),
      'pCbs': _parseNum(_pCbsCtrl.text),
    };

    final caller = NetworkCaller();
    final resp = _editando
        ? await caller.putRequest(
            '${ApiLinks.baseUrl}/api/produto-imposto-uf/${widget.existente!['id']}',
            body)
        : await caller.postRequest(
            '${ApiLinks.baseUrl}/api/produto-imposto-uf', body);

    if (!mounted) return;

    if (resp.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _salvando = false;
      _erroServidor =
          mensagemErroSalvar(resp.statusCode, isRegraPadrao: _isRegraPadrao);
    });
  }

  dynamic _parseNum(String texto) => parseNumeroFiscal(texto);

  String? _blankToNull(String texto) => texto.trim().isEmpty ? null : texto.trim();

  String? _validarNumero(String? valor) => validarNumeroFiscal(valor);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando
          ? 'Editar configuração fiscal'
          : 'Nova configuração fiscal'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Regra padrão (sem UF)'),
                  value: _isRegraPadrao,
                  onChanged: _editando
                      ? null
                      : (v) => setState(() {
                            _isRegraPadrao = v;
                            if (v) _estadoId = null;
                          }),
                ),
                if (!_isRegraPadrao) ...[
                  DropdownButtonFormField<dynamic>(
                    initialValue: _estadoId,
                    decoration: const InputDecoration(labelText: 'UF de destino *'),
                    items: widget.estados
                        .map((e) => DropdownMenuItem(
                              value: e['id'],
                              child: Text(
                                  '${e['uf'] ?? ''} - ${e['nome'] ?? ''}'),
                            ))
                        .toList(),
                    onChanged: _editando
                        ? null
                        : (v) => setState(() => _estadoId = v),
                    validator: (v) =>
                        (!_isRegraPadrao && v == null) ? 'Selecione a UF' : null,
                  ),
                  const SizedBox(height: 8),
                ],
                _secaoTitulo('ICMS'),
                // Bug de producao: CST/CSOSN e' tabela fechada da Receita
                // (Convenio s/no de 1970) -- virou dropdown. Junta as duas
                // tabelas (CST regime normal + CSOSN Simples Nacional) numa
                // so lista: o backend ja discrimina automaticamente qual
                // grupo usar no XML (ProdutoImpostoEnrichmentServiceImpl.isCson()).
                _campoDropdown(
                  'CST/CSOSN',
                  _cstCsosn,
                  [...kOpcoesCst, ...kOpcoesCsosn],
                  (v) => setState(() => _cstCsosn = v),
                ),
                _campoNumero('Alíquota ICMS (%)', _aliquotaIcmsCtrl),
                _campoNumero('Alíquota ICMS reduzida (%)', _aliqIcmsRedCtrl),
                _campoNumero('% Redução BC', _pRedBcCtrl),
                _campoNumero('Alíquota ST / MVA (%)', _aliqStCtrl),
                _secaoTitulo('IPI'),
                // CST IPI: dropdown fechado (Anexo do leiaute NF-e).
                _campoDropdown(
                  'CST IPI',
                  _cstIpi,
                  kOpcoesCstIpi,
                  (v) => setState(() => _cstIpi = v),
                ),
                _campoNumero('Alíquota IPI (%)', _aliqIpiCtrl),
                // Codigo de enquadramento legal do IPI: tabela oficial com
                // centenas de entradas (TIPI/RFB), grande demais pra embutir
                // aqui sem fonte oficial baixada -- mantido texto livre.
                _campoTexto('Código enquadramento IPI', _codEnqIpiCtrl),
                _secaoTitulo('ISS'),
                // Codigo de tributacao do ISS varia por MUNICIPIO (nao ha
                // tabela nacional unica) -- mantido texto livre.
                _campoTexto('Código tributação ISS', _codTribIssCtrl),
                _campoNumero('Alíquota ISS (%)', _aliqIssCtrl),
                _secaoTitulo('PIS'),
                // CST PIS: dropdown fechado (Tabela 4.3.4 do MOC NF-e).
                _campoDropdown(
                  'CST PIS',
                  _cstPis,
                  kOpcoesCstPisCofins,
                  (v) => setState(() => _cstPis = v),
                ),
                _campoNumero('Alíquota PIS (%)', _pPisCtrl),
                _secaoTitulo('COFINS'),
                // CST COFINS: mesma tabela oficial do PIS (Tabela 4.3.5).
                _campoDropdown(
                  'CST COFINS',
                  _cstCofins,
                  kOpcoesCstPisCofins,
                  (v) => setState(() => _cstCofins = v),
                ),
                _campoNumero('Alíquota COFINS (%)', _pCofinsCtrl),
                _secaoTitulo('IBS/CBS (Reforma Tributária)'),
                // CST IBS/CBS: dropdown fechado (Nota Tecnica NF-e 2025.002).
                _campoDropdown(
                  'CST IBS/CBS',
                  _cstIbsCbs,
                  kOpcoesCstIbsCbs,
                  (v) => setState(() => _cstIbsCbs = v),
                ),
                // cClassTrib: mantido texto livre -- 6 digitos onde os 3
                // primeiros repetem o CST IBS/CBS e os 3 finais detalham a
                // hipotese de enquadramento; tabela completa (Anexo III da
                // NT 2025.002) ainda em transicao/ajuste ate 2033, nao fixar
                // enum rigido sem plano de atualizacao.
                _campoTexto('Código classificação tributária', _cClassTribCtrl),
                _campoNumero('Alíquota IBS estadual (%)', _pIbsUfCtrl),
                _campoNumero('Alíquota IBS municipal (%)', _pIbsMunCtrl),
                _campoNumero('Alíquota CBS (%)', _pCbsCtrl),
                if (_erroServidor != null) ...[
                  const SizedBox(height: 12),
                  Text(_erroServidor!,
                      style: const TextStyle(color: GridColors.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _secaoTitulo(String texto) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(texto,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: GridColors.primary)),
      );

  Widget _campoDropdown(
    String label,
    String? valor,
    List<Map<String, String>> opcoes,
    ValueChanged<String?> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: opcoes
              .map((o) => DropdownMenuItem(
                    value: o['value'],
                    child: Text(o['label'] ?? o['value'] ?? '',
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      );

  Widget _campoTexto(String label, TextEditingController controller) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Widget _campoNumero(String label, TextEditingController controller) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validarNumero,
        ),
      );
}
