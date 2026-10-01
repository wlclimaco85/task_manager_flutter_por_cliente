import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';
import '../models/network_response.dart';
import '../services/network_caller.dart';
import 'generic_grid_screen.dart'
    show FieldConfig, FieldType, PaginationConfig, ExportConfig, SecurityCheck;
import 'dart:convert';
import 'package:flutter/services.dart';

class GenericTreeScreen<T> extends StatefulWidget {
  final String title;
  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint;
  final String deleteEndpoint;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final SecurityCheck hasPermission;
  final List<FieldConfig> fieldConfigs;
  final String idFieldName;
  final String parentIdFieldName;
  final String displayFieldName;
  final String codeFieldName;

  const GenericTreeScreen({
    super.key,
    required this.title,
    required this.fetchEndpoint,
    required this.createEndpoint,
    required this.updateEndpoint,
    required this.deleteEndpoint,
    required this.fromJson,
    required this.toJson,
    required this.hasPermission,
    required this.fieldConfigs,
    this.idFieldName = 'id',
    this.parentIdFieldName = 'parent_id',
    this.displayFieldName = 'nome',
    this.codeFieldName = 'codigo',
  });

  @override
  State<GenericTreeScreen<T>> createState() => _GenericTreeScreenState<T>();
}

class _GenericTreeScreenState<T> extends State<GenericTreeScreen<T>> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allItems = [];
  Set<int> _expandedNodes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch sem paginaÃ§Ã£o forte para pegar arvore inteira
      final response = await NetworkCaller()
          .getRequest('${widget.fetchEndpoint}?tamanho=1000');
      if (response.isSuccess && response.body != null) {
        final responseData = response.body!['data'];
        final List<dynamic> data = responseData is Map
            ? responseData['dados'] ?? []
            : responseData ?? [];

        setState(() {
          _allItems = List<Map<String, dynamic>>.from(data);
        });
      } else {
        _showError('Erro ao carregar dados');
      }
    } catch (e) {
      _showError('ExceÃ§Ã£o ao carregar dados: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: GridColors.error));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: GridColors.success));
  }

  // MÃ©todo de delete
  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir item?'),
        content: const Text('Tem certeza que deseja excluir este item?'),
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

    setState(() => _isLoading = true);
    final response = await NetworkCaller().deleteRequest(
      widget.deleteEndpoint.replaceAll(':id', id),
    );
    if (response.isSuccess) {
      _showSuccess('ExcluÃ­do com sucesso');
      _loadData();
    } else {
      _showError('Erro ao excluir');
      setState(() => _isLoading = false);
    }
  }

  // --- Form Dialog simplificado (mesma base do Grid mas adaptado) ---
  void _openForm(
      {Map<String, dynamic>? item, Map<String, dynamic>? parentItem}) {
    showDialog(
        context: context,
        builder: (ctx) {
          return _TreeFormDialog(
            item: item,
            parentItem: parentItem,
            fieldConfigs: widget.fieldConfigs,
            idFieldName: widget.idFieldName,
            parentIdFieldName: widget.parentIdFieldName,
            onSave: (formData) async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              // Corrige relacionamentos
              final Map<String, dynamic> payload = Map.from(formData);
              if (payload['parent'] != null && payload['parent'] is int) {
                payload['parent'] = {'id': payload['parent']};
              }

              if (item == null) {
                final response = await NetworkCaller()
                    .postRequest(widget.createEndpoint, payload);
                if (response.isSuccess) {
                  _showSuccess('Criado com sucesso');
                } else {
                  _showError('Erro ao criar');
                }
              } else {
                payload[widget.idFieldName] = item[widget.idFieldName];
                final response = await NetworkCaller().putRequest(
                  widget.updateEndpoint
                      .replaceAll(':id', item[widget.idFieldName].toString()),
                  payload,
                );
                if (response.isSuccess) {
                  _showSuccess('Salvo com sucesso');
                } else {
                  _showError('Erro ao salvar');
                }
              }
              _loadData();
            },
          );
        });
  }

  List<Map<String, dynamic>> _getChildren(int? parentId) {
    return _allItems.where((item) {
      final p = item['parent'];
      final pId = p != null ? p['id'] : item[widget.parentIdFieldName];
      return pId == parentId;
    }).toList()
      ..sort((a, b) {
        final c1 = a[widget.codeFieldName]?.toString() ?? '';
        final c2 = b[widget.codeFieldName]?.toString() ?? '';
        return c1.compareTo(c2);
      });
  }

  Widget _buildNode(Map<String, dynamic> item, int depth) {
    final itemId = item[widget.idFieldName] as int;
    final children = _getChildren(itemId);
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expandedNodes.contains(itemId);

    final code = item[widget.codeFieldName]?.toString() ?? '';
    final name = item[widget.displayFieldName]?.toString() ?? '';
    final title = code.isNotEmpty ? '$code - $name' : name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: hasChildren
              ? () {
                  setState(() {
                    if (isExpanded)
                      _expandedNodes.remove(itemId);
                    else
                      _expandedNodes.add(itemId);
                  });
                }
              : null,
          child: Container(
            padding: EdgeInsets.only(
                left: 16.0 + (depth * 24.0), top: 8, bottom: 8, right: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: hasChildren
                      ? Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 20,
                          color: GridColors.primary)
                      : const SizedBox(),
                ),
                Icon(hasChildren ? Icons.folder : Icons.insert_drive_file,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                // Actions
                if (widget.hasPermission('create'))
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: 'Adicionar Sub-item',
                    onPressed: () => _openForm(parentItem: item),
                    splashRadius: 20,
                  ),
                if (widget.hasPermission('edit'))
                  IconButton(
                    icon: const Icon(Icons.edit,
                        size: 18, color: GridColors.primary),
                    tooltip: 'Editar',
                    onPressed: () => _openForm(item: item),
                    splashRadius: 20,
                  ),
                if (widget.hasPermission('delete'))
                  IconButton(
                    icon: const Icon(Icons.delete,
                        size: 18, color: GridColors.error),
                    tooltip: 'Excluir',
                    onPressed: () => _deleteItem(itemId.toString()),
                    splashRadius: 20,
                  ),
              ],
            ),
          ),
        ),
        if (isExpanded && hasChildren)
          ...children.map((c) => _buildNode(c, depth + 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rootNodes = _getChildren(null);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.hasPermission('create'))
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Raiz'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white),
                onPressed: () => _openForm(),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : rootNodes.isEmpty
              ? const Center(child: Text('Nenhum registro encontrado.'))
              : ListView(
                  children: rootNodes.map((c) => _buildNode(c, 0)).toList(),
                ),
    );
  }
}

class _TreeFormDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Map<String, dynamic>? parentItem;
  final List<FieldConfig> fieldConfigs;
  final String idFieldName;
  final String parentIdFieldName;
  final Function(Map<String, dynamic>) onSave;

  const _TreeFormDialog({
    this.item,
    this.parentItem,
    required this.fieldConfigs,
    required this.idFieldName,
    required this.parentIdFieldName,
    required this.onSave,
  });

  @override
  State<_TreeFormDialog> createState() => _TreeFormDialogState();
}

class _TreeFormDialogState extends State<_TreeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _boolValues = {};

  @override
  void initState() {
    super.initState();
    for (var config in widget.fieldConfigs.where((c) => c.isInForm)) {
      if (config.fieldType == FieldType.boolean) {
        _boolValues[config.fieldName] =
            widget.item?[config.fieldName] == true ||
                widget.item?[config.fieldName] == 'true';
      } else {
        _controllers[config.fieldName] = TextEditingController(
          text: widget.item?[config.fieldName]?.toString() ?? '',
        );
      }
    }

    // Auto-preencher parent_id se estamos criando sub-item
    if (widget.item == null && widget.parentItem != null) {
      // Inserimos silenciosamente no payload depois, nÃ£o precisa de field visÃ­vel pra ele
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Novo Item' : 'Editar Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                widget.fieldConfigs.where((c) => c.isInForm).map((config) {
              if (config.fieldType == FieldType.boolean) {
                return SwitchListTile(
                  title: Text(config.label),
                  value: _boolValues[config.fieldName] ?? false,
                  onChanged: (val) =>
                      setState(() => _boolValues[config.fieldName] = val),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _controllers[config.fieldName],
                  decoration: InputDecoration(
                    labelText: config.label,
                    border: const OutlineInputBorder(),
                  ),
                  validator: config.isRequired
                      ? (val) =>
                          (val == null || val.isEmpty) ? 'ObrigatÃ³rio' : null
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.primary,
              foregroundColor: Colors.white),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final formData = <String, dynamic>{};
              _controllers.forEach((k, v) => formData[k] = v.text);
              _boolValues.forEach((k, v) => formData[k] = v);

              if (widget.item == null && widget.parentItem != null) {
                formData['parent'] = widget.parentItem![widget.idFieldName];
              } else if (widget.item != null &&
                  widget.item!['parent'] != null) {
                formData['parent'] = widget.item!['parent']['id'];
              }

              widget.onSave(formData);
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
