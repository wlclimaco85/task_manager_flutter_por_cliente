import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../services/query_builder_caller.dart';

/// Exibe diálogo para salvar a query atual com um nome.
///
/// Retorna o nome informado, ou `null` se o usuário cancelar.
Future<String?> showSaveQueryDialog(
  BuildContext context, {
  String? nomeAtual,
}) {
  final controller = TextEditingController(text: nomeAtual ?? '');
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.save, size: 20, color: GridColors.primary),
          SizedBox(width: 10),
          Text(
            'Salvar Query',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: 400,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome da Query',
              hintText: 'Ex: Listar logins ativos',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe um nome para a query' : null,
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx, controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.primary,
            foregroundColor: GridColors.textPrimary,
          ),
          child: const Text(GridTexts.save),
        ),
      ],
    ),
  ).then((result) {
    controller.dispose();
    return result;
  });
}

/// Exibe diálogo para carregar uma query salva.
///
/// Retorna os dados da query selecionada, ou `null` se o usuário cancelar.
Future<Map<String, dynamic>?> showLoadQueryDialog(
  BuildContext context,
  List<dynamic> queries,
) {
  if (queries.isEmpty) {
    // Mostra mensagem de vazio e retorna null
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Carregar Query'),
        content: const Text('Nenhuma query salva encontrada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return Future.value(null);
  }

  // Converte para lista de mapas
  final List<Map<String, dynamic>> queryList = queries.map((q) {
    if (q is Map<String, dynamic>) return q;
    return <String, dynamic>{};
  }).toList();

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _LoadQueryDialog(queryList: queryList),
  );
}

class _LoadQueryDialog extends StatefulWidget {
  final List<Map<String, dynamic>> queryList;

  const _LoadQueryDialog({required this.queryList});

  @override
  State<_LoadQueryDialog> createState() => _LoadQueryDialogState();
}

class _LoadQueryDialogState extends State<_LoadQueryDialog> {
  String _busca = '';
  int? _querySelecionada;
  bool _deletando = false;

  List<Map<String, dynamic>> get _queriesFiltradas {
    if (_busca.isEmpty) return widget.queryList;
    final q = _busca.toLowerCase();
    return widget.queryList.where((item) {
      final nome = (item['nome']?.toString() ?? '').toLowerCase();
      final sql = (item['sqlTexto']?.toString() ?? '').toLowerCase();
      return nome.contains(q) || sql.contains(q);
    }).toList();
  }

  Future<void> _deletarQuery(Map<String, dynamic> query) async {
    final id = query['id'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Excluir a query "${query['nome']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: GridColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deletando = true);
    final ok = await QueryBuilderCaller.deletarQuery(id is int ? id : int.parse(id.toString()));
    if (!mounted) return;

    if (ok) {
      setState(() {
        widget.queryList.removeWhere((q) => q['id'] == id);
        _deletando = false;
      });
    } else {
      setState(() => _deletando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao excluir query'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: GridColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.folder_open,
                      color: GridColors.textPrimary, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Carregar Query',
                    style: TextStyle(
                      color: GridColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Busca
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _busca = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar queries...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // Lista
            Expanded(
              child: _deletando
                  ? const Center(child: CircularProgressIndicator())
                  : _queriesFiltradas.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma query encontrada.',
                            style: TextStyle(color: GridColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: _queriesFiltradas.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: GridColors.divider),
                          itemBuilder: (_, i) {
                            final query = _queriesFiltradas[i];
                            final nome =
                                query['nome']?.toString() ?? 'Sem nome';
                            final sql = query['sqlTexto']?.toString() ?? '';
                            final selecionado =
                                i == _querySelecionada;

                            return InkWell(
                              onTap: () {
                                setState(() => _querySelecionada = i);
                              },
                              onDoubleTap: () =>
                                  Navigator.pop(context, query),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selecionado
                                      ? GridColors.selectedRow
                                      : null,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: GridColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            sql.length > 80
                                                ? '${sql.substring(0, 80)}...'
                                                : sql,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              color: GridColors.textMuted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: GridColors.error),
                                      onPressed: () => _deletarQuery(query),
                                      tooltip: 'Excluir',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            // Ações
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _querySelecionada != null
                        ? () =>
                            Navigator.pop(context, _queriesFiltradas[_querySelecionada!])
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.primary,
                      foregroundColor: GridColors.textPrimary,
                    ),
                    child: const Text('Carregar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
