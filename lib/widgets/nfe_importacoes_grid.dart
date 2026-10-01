import 'package:flutter/material.dart';

import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/grid_colors.dart';

/// Pedido explicito do usuario: a tela de Importar XML precisa ter uma grid
/// padrao do sistema mostrando o que ja foi importado, com status, e um
/// delete que funciona nos dois status.
///
/// Backend: GET /api/nfe-import/importacao-xml lista as Nfe importadas
/// (TipoOperacao.ENTRADA), cada uma com status RASCUNHO_IMPORTACAO (ainda
/// nao virou Entrada oficial) ou AUTORIZADA (Entrada ja confirmada). BUG
/// produção corrigido: excluir uma Entrada ja confirmada (AUTORIZADA)
/// tambem e permitido -- NfeServiceImpl.validarPodeDeletar nunca bloqueia
/// TipoOperacao.ENTRADA (so bloqueia SAIDA, documento que a propria empresa
/// emitiu). O DELETE reverte estoque e remove a(s) conta(s) a pagar geradas
/// (NfeImportService.reverterEntrada, chamado por NfeController.deletar()).
typedef ListarImportacoesFn = Future<List<Map<String, dynamic>>?> Function();

class NfeImportacoesGrid extends StatefulWidget {
  // Injetavel apenas para teste (flutter_test) -- evita bater em rede real
  // ao montar o widget. Em producao usa sempre NfeXmlImportacoesCaller.listar.
  final ListarImportacoesFn? listarOverride;

  const NfeImportacoesGrid({super.key, this.listarOverride});

  @override
  State<NfeImportacoesGrid> createState() => NfeImportacoesGridState();
}

class NfeImportacoesGridState extends State<NfeImportacoesGrid> {
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _itens = [];
  final Set<int> _emAcao = {};

  @override
  void initState() {
    super.initState();
    recarregar();
  }

  /// Exposto para a tela pai chamar depois de uma importação bem-sucedida.
  Future<void> recarregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final listarFn = widget.listarOverride ?? NfeXmlImportacoesCaller.listar;
    final lista = await listarFn();
    if (!mounted) return;

    setState(() {
      _carregando = false;
      if (lista == null) {
        _erro = 'Não foi possível carregar as importações.';
        _itens = [];
      } else {
        _itens = lista;
      }
    });
  }

  bool _isRascunho(Map<String, dynamic> item) =>
      item['status']?.toString() == 'RASCUNHO_IMPORTACAO';

  Future<void> _confirmarEntrada(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id == null) return;
    setState(() => _emAcao.add(id as int));

    final ok = await NfeXmlImportacoesCaller.confirmarEntrada(id.toString());

    if (!mounted) return;
    setState(() => _emAcao.remove(id));

    _mostrarSnack(ok
        ? 'NF-e Entrada confirmada com sucesso.'
        : 'Erro ao confirmar a NF-e Entrada.');
    if (ok) await recarregar();
  }

  Future<void> _excluir(Map<String, dynamic> item) async {
    final id = item['id'];
    if (id == null) return;
    final rascunho = _isRascunho(item);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir importação'),
        content: Text(
            'Excluir o XML importado ${item['numero'] ?? ''}/${item['serie'] ?? ''}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _emAcao.add(id as int));

    final sucesso = await NfeXmlImportacoesCaller.excluir(id.toString());

    if (!mounted) return;
    setState(() => _emAcao.remove(id));

    if (sucesso) {
      _mostrarSnack(rascunho
          ? 'Importação excluída.'
          : 'Entrada excluída. Estoque e contas a pagar gerados foram revertidos.');
      await recarregar();
    } else {
      // BUG produção corrigido: o backend NAO bloqueia mais excluir uma NFe
      // de ENTRADA por estar AUTORIZADA (Entrada ja confirmada) -- essa
      // mensagem so aparece agora por outro motivo real (rede, tenant,
      // NFe ja excluida por outra sessao etc.), entao nao deve mais
      // orientar erroneamente para um fluxo alternativo que nem sempre
      // exibe o registro (bug relacionado, filtro da grid "NF-e Entrada").
      _mostrarSnack('Não foi possível excluir a importação. Tente novamente.');
    }
  }

  void _mostrarSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, color: GridColors.secondary),
                const SizedBox(width: 8),
                const Text(
                  'XML já importados',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _carregando ? null : recarregar,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Atualizar',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erro != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_erro!, style: const TextStyle(color: Colors.red)),
              )
            else if (_itens.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Nenhum XML importado ainda.',
                    style: TextStyle(color: Colors.black54)),
              )
            else
              _buildTabela(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabela() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor:
            WidgetStateProperty.all(GridColors.secondary.withValues(alpha: 0.1)),
        columns: const [
          DataColumn(label: Text('Número/Série')),
          DataColumn(label: Text('Chave')),
          DataColumn(label: Text('Valor Total')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Ações')),
        ],
        rows: _itens.map((item) {
          final id = item['id'] as int?;
          final rascunho = _isRascunho(item);
          final emAcao = id != null && _emAcao.contains(id);
          return DataRow(cells: [
            DataCell(Text('${item['numero'] ?? '-'}/${item['serie'] ?? '-'}')),
            DataCell(Text(
              (item['chave']?.toString() ?? '-'),
              style: const TextStyle(fontSize: 11),
            )),
            DataCell(Text(item['valorTotal']?.toString() ?? '-')),
            DataCell(_buildStatusBadge(rascunho)),
            DataCell(emAcao
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rascunho)
                        TextButton.icon(
                          onPressed: () => _confirmarEntrada(item),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Confirmar Entrada'),
                        ),
                      IconButton(
                        onPressed: () => _excluir(item),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: rascunho
                            ? 'Excluir'
                            : 'Excluir (reverte estoque e contas a pagar geradas)',
                      ),
                    ],
                  )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(bool rascunho) {
    final cor = rascunho ? Colors.orange : Colors.green;
    final texto = rascunho ? 'Rascunho' : 'Entrada Criada';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor),
      ),
      child: Text(
        texto,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: cor.shade800),
      ),
    );
  }
}

/// Chamadas de rede da grid de importações -- separado de NfeXmlImportCaller
/// (upload/preview/confirmar do XML em si) porque aqui é JSON puro (GET
/// listar, POST confirmar-entrada, DELETE excluir), sem multipart.
class NfeXmlImportacoesCaller {
  static Future<List<Map<String, dynamic>>?> listar() async {
    try {
      final resp = await NetworkCaller().getRequest(ApiLinks.nfeImportacaoListar);
      if (!resp.isSuccess || resp.body == null) return null;
      // Page<Nfe> do backend serializa como objeto com "content"; a
      // conversao em NetworkResponse (_toMap) envolve qualquer resposta que
      // nao seja Map em {"data": [...]}, entao os dois formatos precisam ser
      // aceitos aqui.
      final body = resp.body!;
      final bruto = body['content'] ?? body['data'] ?? [];
      if (bruto is! List) return [];
      return bruto
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> confirmarEntrada(String id) async {
    final resp = await NetworkCaller()
        .postRequest(ApiLinks.nfeImportacaoConfirmarEntrada(id), {});
    return resp.isSuccess;
  }

  // NetworkCaller.deleteRequest nunca popula body em caso de erro (so
  // statusCode) -- por isso a mensagem de bloqueio (NFe AUTORIZADA nao pode
  // ser deletada) fica a cargo do fallback fixo no widget, nao de parsing de
  // resposta que nunca viria preenchida.
  static Future<bool> excluir(String id) async {
    final resp = await NetworkCaller().deleteRequest(ApiLinks.nfeById(id));
    return resp.isSuccess;
  }
}
