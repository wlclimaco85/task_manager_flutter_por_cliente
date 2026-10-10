import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';
import '../utils/grid_texts.dart';

/// Escolha de conciliacao de produto pra UM item, feita pelo usuario antes
/// de confirmar a importacao. Serializado pro backend como
/// ConciliacaoItemDTO (POST .../importacao-xml/confirmar, campo
/// itensConciliacao).
class ConciliacaoEscolha {
  final String produtoCodigo;
  int? produtoId;
  bool criarNovoProduto;

  ConciliacaoEscolha({
    required this.produtoCodigo,
    this.produtoId,
    this.criarNovoProduto = false,
  });

  Map<String, dynamic> toJson() => {
        'produtoCodigo': produtoCodigo,
        if (produtoId != null) 'produtoId': produtoId,
        'criarNovoProduto': criarNovoProduto,
      };
}

class NfeXmlPreviewWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  // Bug de producao: pra cada item importado, o usuario precisa poder
  // escolher usar um produto ja cadastrado (a tela ja sugere quando o NCM
  // bate, so precisa aprovar) ou cadastrar um produto novo pre-preenchido
  // com os dados da nota -- antes disso, o item importava sem NENHUM
  // vinculo de produto, sem o usuario nem saber que essa opcao existia.
  final void Function(List<Map<String, dynamic>> conciliacoes) onConfirm;
  final VoidCallback onCancel;
  final bool confirming;

  const NfeXmlPreviewWidget({
    super.key,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
    this.confirming = false,
  });

  @override
  State<NfeXmlPreviewWidget> createState() => _NfeXmlPreviewWidgetState();
}

class _NfeXmlPreviewWidgetState extends State<NfeXmlPreviewWidget> {
  // Chave = produtoCodigo (cProd) do item -- unico identificador estavel
  // disponivel antes da nota ser confirmada (item ainda nao tem id).
  final Map<String, ConciliacaoEscolha> _escolhas = {};

  Map<String, dynamic> get data => widget.data;

  String? _get(String key) => data[key]?.toString();
  String? _getNested(String outer, String inner) {
    final o = data[outer];
    if (o is Map) return o[inner]?.toString();
    return null;
  }

  bool _chaveExiste() {
    final status = data['status'];
    if (status is String && status.toLowerCase() == 'existente') return true;
    if (data['chaveExistente'] == true) return true;
    if (data['duplicada'] == true) return true;
    return false;
  }

  List<dynamic> _getItens() {
    final itens = data['itens'];
    if (itens is List) return itens;
    if (itens is Map && itens['item'] is List) return itens['item'];
    return [];
  }

  // Bug encontrado no proprio desenvolvimento deste widget: usar
  // `escolha.produtoId ??= sugeridoId` dentro do build() reatribuia a
  // sugestao TODA VEZ que o widget reconstruia (ex.: apos o proprio
  // setState do checkbox), fazendo o "desmarcar" do usuario ser desfeito no
  // frame seguinte. O default so pode ser aplicado UMA VEZ, na criacao da
  // escolha (primeira vez que o item e visto), nunca em rebuilds
  // posteriores.
  ConciliacaoEscolha _escolhaDoItem(String cProd, {int? produtoSugeridoId}) {
    final jaExistia = _escolhas.containsKey(cProd);
    final escolha = _escolhas.putIfAbsent(
        cProd, () => ConciliacaoEscolha(produtoCodigo: cProd));
    if (!jaExistia && produtoSugeridoId != null) {
      escolha.produtoId = produtoSugeridoId;
    }
    return escolha;
  }

  @override
  Widget build(BuildContext context) {
    final chave = _get('chave') ?? '-';
    final numero = _get('numero') ?? _get('nNF') ?? '-';
    final serie = _get('serie') ?? '-';
    final chaveExiste = _chaveExiste();
    final emitente = _get('emitenteNome') ??
        _getNested('emitente', 'xNome') ??
        _getNested('emitente', 'nome') ??
        '-';
    final dhEmi = _get('dataEmissao') ?? _get('dhEmi') ?? '-';
    final vTotal = _get('valorTotal') ?? _get('vNF') ?? _get('total') ?? '-';
    final itens = _getItens();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview,
                    color: GridColors.secondary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Preview da NF-e',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        chaveExiste ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: chaveExiste ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        chaveExiste ? Icons.cancel : Icons.check_circle,
                        size: 16,
                        color: chaveExiste ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chaveExiste ? 'Chave já existe' : 'Chave nova',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: chaveExiste
                              ? Colors.red.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('Chave de Acesso', chave),
            _buildField('Número / Série', '$numero / $serie'),
            _buildField('Emitente', emitente),
            _buildField('Data de Emissão', dhEmi),
            _buildField('Valor Total', vTotal),
            if (itens.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Itens da Nota',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pra cada item, use o produto sugerido (quando o NCM já bate '
                'com algo do seu catálogo), escolha outro ou cadastre um '
                'produto novo já pré-preenchido com os dados da nota.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              _buildTabelaItens(itens),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                  onPressed: widget.confirming
                      ? null
                      : () => widget.onConfirm(
                          _escolhas.values.map((e) => e.toJson()).toList()),
                  icon: widget.confirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(widget.confirming
                      ? 'Importando...'
                      : 'Confirmar Importação'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: widget.confirming ? null : widget.onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text(GridTexts.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaItens(List<dynamic> itens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
            GridColors.secondary.withValues(alpha: 0.1)),
        columnSpacing: 16,
        columns: const [
          DataColumn(
              label: Text('#',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('Produto',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('NCM',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('CFOP',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('CST',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('Qtde',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('V. Unit.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('Conciliação de Produto',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        ],
        rows: itens.asMap().entries.map((entry) {
          final i = entry.value;
          final idx = entry.key + 1;
          // Bug de producao: essa tabela nunca mostrava o nome do produto
          // (coluna sempre "-") porque procurava por chaves de XML bruto
          // (xProd/produto/NCM maiusculo/etc.) em vez dos nomes reais que o
          // backend manda (NfeImportacaoItemDTO): produtoDescricao, ncm,
          // cfop, cst, quantidade, valorUnitario, total.
          return DataRow(cells: [
            DataCell(Text('$idx', style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'produtoDescricao') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'ncm') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'cfop') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'cst') ?? _itemGet(i, 'csosn') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'quantidade') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'valorUnitario') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'total') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(_buildConciliacaoCelula(i)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildConciliacaoCelula(dynamic item) {
    final cProd = _itemGet(item, 'produtoCodigo');
    if (cProd == null || cProd.isEmpty) {
      return const Text('-', style: TextStyle(fontSize: 12));
    }
    final sugeridoIdStr = _itemGet(item, 'produtoSugeridoId');
    final sugeridoNome = _itemGet(item, 'produtoSugeridoNome');
    final sugeridoId =
        sugeridoIdStr != null ? int.tryParse(sugeridoIdStr) : null;
    final escolha =
        _escolhaDoItem(cProd, produtoSugeridoId: sugeridoId);

    if (sugeridoId != null) {
      // Item tem sugestao automatica (NCM bateu com produto ja cadastrado
      // nesta empresa) -- pre-marcada, usuario so precisa aprovar ou
      // recusar (default aplicado uma unica vez em _escolhaDoItem, nunca
      // reaplicado em rebuilds -- ver comentario la).
      final usandoSugestao = escolha.produtoId == sugeridoId;
      return SizedBox(
        width: 220,
        child: CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: usandoSugestao,
          title: Text(
            'Usar produto já cadastrado:\n$sugeridoNome',
            style: const TextStyle(fontSize: 11),
          ),
          onChanged: (marcado) {
            setState(() {
              escolha.produtoId = marcado == true ? sugeridoId : null;
              escolha.criarNovoProduto = false;
            });
          },
        ),
      );
    }

    // Sem sugestao automatica: oferece cadastrar produto novo, pre-
    // preenchido com os dados do proprio item da nota (nome, codigo, ncm,
    // cfop, preco) -- o backend faz esse pre-preenchimento ao confirmar.
    return SizedBox(
      width: 220,
      child: CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: escolha.criarNovoProduto,
        title: const Text(
          'Cadastrar como produto novo',
          style: TextStyle(fontSize: 11),
        ),
        onChanged: (marcado) {
          setState(() {
            escolha.criarNovoProduto = marcado == true;
          });
        },
      ),
    );
  }

  String? _itemGet(dynamic item, String key) {
    if (item is Map) return item[key]?.toString();
    return null;
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
