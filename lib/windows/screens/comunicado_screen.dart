import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/network_response.dart';
import '../../../utils/api_links.dart';
import '../../services/network_caller.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
import '../../utils/grid_texts.dart';
class Comunicado {
  String id;
  String titulo;
  String conteudo;
  String categoria;
  String autor;
  DateTime? dhCreatedAt;

  Comunicado({
    required this.id,
    required this.titulo,
    required this.conteudo,
    required this.categoria,
    required this.autor,
    this.dhCreatedAt,
  });

  factory Comunicado.fromJson(Map<String, dynamic> json) {
    return Comunicado(
      id: json['_id'] ?? '',
      titulo: json['titulo'] ?? '',
      conteudo: json['conteudo'] ?? '',
      categoria: json['categoria'] ?? '',
      autor: json['autor'] ?? '',
      dhCreatedAt: json['dhCreatedAt'] != null
          ? DateTime.parse(json['dhCreatedAt']).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo': titulo,
      'conteudo': conteudo,
      'categoria': categoria,
      'autor': autor,
      'dhCreatedAt': dhCreatedAt?.toIso8601String(),
    };
  }
}

class WindowsComunicadoGridScreen extends StatefulWidget {
  const WindowsComunicadoGridScreen({super.key});

  @override
  State<WindowsComunicadoGridScreen> createState() => _WindowsComunicadoGridScreenState();
}

class _WindowsComunicadoGridScreenState extends State<WindowsComunicadoGridScreen> {
  List<Comunicado> comunicados = [];
  List<Comunicado> filtered = [];
  Set<String> selectedRows = {};
  int rowsPerPage = 25;
  bool filtrosAbertos = false;
  bool isLoading = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  // filtros
  final _tituloFilter = TextEditingController();
  final _conteudoFilter = TextEditingController();
  final _categoriaFilter = TextEditingController();
  final _autorFilter = TextEditingController();

  // ordenação
  int? sortColumnIndex;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadComunicados();
  }

  Future<void> _loadComunicados() async {
    setState(() {
      isLoading = true;
    });

    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allComunicados,
    );

    if (response.statusCode == 200 && response.body != null) {
      try {
        // Parse da resposta do servidor
        final List<dynamic> data = response.body!['data']['dados'] ?? [];
        setState(() {
          comunicados = data.map((json) => Comunicado.fromJson(json)).toList();
          filtered = List.from(comunicados);
        });
      } catch (e) {
        L.d('Erro no parse dos dados: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao processar os dados')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar comunicados: $response')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      filtered = comunicados.where((c) {
        final tituloOk = c.titulo.toLowerCase().contains(
              _tituloFilter.text.toLowerCase(),
            );
        final conteudoOk = c.conteudo.toLowerCase().contains(
              _conteudoFilter.text.toLowerCase(),
            );
        final categoriaOk = c.categoria.toLowerCase().contains(
              _categoriaFilter.text.toLowerCase(),
            );
        final autorOk = c.autor.toLowerCase().contains(
              _autorFilter.text.toLowerCase(),
            );
        return tituloOk && conteudoOk && categoriaOk && autorOk;
      }).toList();
    });
  }

  void _sort<T>(
    Comparable<T> Function(Comunicado c) getField,
    int columnIndex,
    bool asc,
  ) {
    setState(() {
      filtered.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return asc
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
      sortColumnIndex = columnIndex;
      sortAscending = asc;
    });
  }

  void _openForm({Comunicado? comunicado}) {
    final tituloController = TextEditingController(
      text: comunicado?.titulo ?? "",
    );
    final conteudoController = TextEditingController(
      text: comunicado?.conteudo ?? "",
    );
    final categoriaController = TextEditingController(
      text: comunicado?.categoria ?? "",
    );
    final autorController = TextEditingController(
      text: comunicado?.autor ?? "",
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho
                  Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Text(
                      comunicado == null
                          ? "Novo Comunicado"
                          : "Editar Comunicado",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Campo Título
                  TextFormField(
                    controller: tituloController,
                    decoration: const InputDecoration(
                      labelText: "Título",
                      labelStyle: TextStyle(color: Colors.grey),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      prefixIcon: Icon(Icons.title, color: Colors.green),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 16),

                  // Campo Conteúdo
                  TextFormField(
                    controller: conteudoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Conteúdo",
                      labelStyle: TextStyle(color: Colors.grey),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      prefixIcon: Icon(
                        Icons.description,
                        color: Colors.green,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 16),

                  // Campo Categoria
                  TextFormField(
                    controller: categoriaController,
                    decoration: const InputDecoration(
                      labelText: "Categoria",
                      labelStyle: TextStyle(color: Colors.grey),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      prefixIcon: Icon(
                        Icons.category,
                        color: Colors.green,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 16),

                  // Campo Autor
                  TextFormField(
                    controller: autorController,
                    decoration: const InputDecoration(
                      labelText: "Autor",
                      labelStyle: TextStyle(color: Colors.grey),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      prefixIcon: Icon(Icons.person, color: Colors.green),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  // Botões de ação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text("CANCELAR"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isUpdating
                            ? null
                            : () async {
                                // Salvar no servidor
                                final newComunicado = Comunicado(
                                  id: comunicado?.id ??
                                      DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString(),
                                  titulo: tituloController.text,
                                  conteudo: conteudoController.text,
                                  categoria: categoriaController.text,
                                  autor: autorController.text,
                                );

                                final success = comunicado == null
                                    ? await _createComunicado(newComunicado)
                                    : await _updateComunicado(newComunicado);

                                if (success) {
                                  Navigator.pop(ctx);
                                  _loadComunicados(); // Recarregar dados do servidor
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isUpdating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text("SALVAR"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _createComunicado(Comunicado comunicado) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await NetworkCaller().postRequest(
        ApiLinks.createComunicado,
        comunicado.toJson(),
      );

      setState(() {
        _isUpdating = false;
      });

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comunicado criado com sucesso')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao criar comunicado: $response')),
        );
        return false;
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar comunicado: $e')));
      return false;
    }
  }

  Future<bool> _updateComunicado(Comunicado comunicado) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await NetworkCaller().putRequest(
        ApiLinks.updateComunicado(comunicado.id),
        comunicado.toJson(),
      );

      setState(() {
        _isUpdating = false;
      });

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comunicado atualizado com sucesso')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao atualizar comunicado: $response')),
        );
        return false;
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar comunicado: $e')),
      );
      return false;
    }
  }

  Future<void> _deleteComunicado(String id) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final response = await NetworkCaller().getRequest(
        ApiLinks.deleteComunicado(id),
      );

      setState(() {
        _isDeleting = false;
      });

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comunicado excluído com sucesso')),
        );
        _loadComunicados(); // Recarregar dados do servidor
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao excluir comunicado: $response')),
        );
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir comunicado: $e')));
    }
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja excluir ${selectedRows.length} comunicado(s) selecionado(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in selectedRows) {
                await _deleteComunicado(id);
              }
              setState(() {
                selectedRows.clear();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (_isUpdating || _isDeleting) {
      return Container(
        color: Colors.black54,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text("Comunicados")),
          body: isLoading && comunicados.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Botões de ação
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Botão Novo com cor verde
                          ElevatedButton.icon(
                            onPressed: () => _openForm(),
                            icon: const Icon(Icons.add),
                            label: const Text("Novo"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Botão Deletar Selecionados
                          ElevatedButton.icon(
                            onPressed: selectedRows.isNotEmpty
                                ? _deleteSelected
                                : null,
                            icon: const Icon(Icons.delete),
                            label: const Text("Deletar Selecionados"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Botão para recarregar dados
                          IconButton(
                            onPressed: _loadComunicados,
                            icon: const Icon(Icons.refresh),
                            tooltip: "Recarregar",
                          ),
                          const SizedBox(width: 12),
                          // Botão para expandir/recolher filtros
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                filtrosAbertos = !filtrosAbertos;
                              });
                            },
                            icon: Icon(
                              filtrosAbertos
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            label: Text(
                              filtrosAbertos
                                  ? "Ocultar Filtros"
                                  : "Mostrar Filtros",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[50],
                              foregroundColor: Colors.blueGrey[800],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🔎 filtros - Painel com borda e cor diferenciada
                    if (filtrosAbertos)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              "Filtros",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Flexible(
                                  child: TextField(
                                    controller: _tituloFilter,
                                    decoration: const InputDecoration(
                                      labelText: "Filtrar Título",
                                      prefixIcon: Icon(Icons.search),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => _applyFilters(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: TextField(
                                    controller: _conteudoFilter,
                                    decoration: const InputDecoration(
                                      labelText: "Filtrar Conteúdo",
                                      prefixIcon: Icon(Icons.search),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => _applyFilters(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: TextField(
                                    controller: _categoriaFilter,
                                    decoration: const InputDecoration(
                                      labelText: "Filtrar Categoria",
                                      prefixIcon: Icon(Icons.search),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => _applyFilters(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: TextField(
                                    controller: _autorFilter,
                                    decoration: const InputDecoration(
                                      labelText: "Filtrar Autor",
                                      prefixIcon: Icon(Icons.search),
                                      isDense: true,
                                    ),
                                    onChanged: (_) => _applyFilters(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PaginatedDataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 800,
                          sortColumnIndex: sortColumnIndex,
                          sortAscending: sortAscending,
                          columns: [
                            DataColumn(
                              label: const Text("Título"),
                              onSort: (i, asc) =>
                                  _sort((c) => c.titulo, i, asc),
                            ),
                            DataColumn(
                              label: const Text("Conteúdo"),
                              onSort: (i, asc) =>
                                  _sort((c) => c.conteudo, i, asc),
                            ),
                            DataColumn(
                              label: const Text("Categoria"),
                              onSort: (i, asc) =>
                                  _sort((c) => c.categoria, i, asc),
                            ),
                            DataColumn(
                              label: const Text("Autor"),
                              onSort: (i, asc) => _sort((c) => c.autor, i, asc),
                            ),
                            const DataColumn(label: Text("Data")),
                            const DataColumn(label: Text("Ações")),
                          ],
                          source: _ComunicadoDataSource(
                            comunicados: filtered,
                            selectedRows: selectedRows,
                            onEdit: (index) =>
                                _openForm(comunicado: filtered[index]),
                            onDelete: (index) {
                              _deleteComunicado(filtered[index].id);
                            },
                            onSelect: (index, selected) {
                              setState(() {
                                final id = filtered[index].id;
                                if (selected) {
                                  selectedRows.add(id);
                                } else {
                                  selectedRows.remove(id);
                                }
                              });
                            },
                          ),
                          rowsPerPage: rowsPerPage,
                          availableRowsPerPage: const [25, 50, 75, 100],
                          onRowsPerPageChanged: (value) {
                            setState(() {
                              rowsPerPage = value ?? 25;
                            });
                          },
                          empty: Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              child: const Text(
                                "Nenhum comunicado encontrado",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        _buildLoadingOverlay(),
      ],
    );
  }
}

class _ComunicadoDataSource extends DataTableSource {
  final List<Comunicado> comunicados;
  final Set<String> selectedRows;
  final void Function(int index) onEdit;
  final void Function(int index) onDelete;
  final void Function(int index, bool selected) onSelect;

  _ComunicadoDataSource({
    required this.comunicados,
    required this.selectedRows,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= comunicados.length) return null;
    final comunicado = comunicados[index];
    final isSelected = selectedRows.contains(comunicado.id);

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        onSelect(index, selected ?? false);
      },
      cells: [
        DataCell(Text(comunicado.titulo)),
        DataCell(Text(comunicado.conteudo)),
        DataCell(Text(comunicado.categoria)),
        DataCell(Text(comunicado.autor)),
        DataCell(
          Text(
            comunicado.dhCreatedAt != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(comunicado.dhCreatedAt!)
                : 'N/A',
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => onEdit(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => onDelete(index),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => comunicados.length;

  @override
  int get selectedRowCount => selectedRows.length;
}
