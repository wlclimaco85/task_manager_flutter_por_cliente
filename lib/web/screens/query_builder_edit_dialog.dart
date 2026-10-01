import 'package:flutter/material.dart';
import '../../services/query_builder_caller.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

/// Exibe um diálogo dinâmico para editar uma linha de resultado.
///
/// Constrói campos baseados nas colunas retornadas:
/// - TextField para texto/número
/// - Checkbox para booleanos
/// - DatePicker para datas
/// - Read-only para PKs
/// - Dropdown para FKs (opcional)
Future<bool?> showEditRowDialog(
  BuildContext context, {
  required String schema,
  required List<Map<String, dynamic>> colunas,
  required Map<String, dynamic> rowData,
}) {
  // Identifica a PK (primeira coluna que for PK ou 'id')
  String? pkColumn;
  dynamic pkValue;

  for (final col in colunas) {
    final nome = col['nome']?.toString() ?? '';
    final isPk = col['pk'] == true ||
        col['primaryKey'] == true ||
        col['isPrimaryKey'] == true ||
        nome.toLowerCase() == 'id';
    if (isPk && pkColumn == null) {
      pkColumn = nome;
      pkValue = rowData[nome];
    }
  }

  // Fallback: usa primeira coluna
  pkColumn ??= colunas.isNotEmpty ? colunas.first['nome']?.toString() : null;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => _EditRowDialog(
      schema: schema,
      colunas: colunas,
      rowData: Map<String, dynamic>.from(rowData),
      pkColumn: pkColumn,
      pkValue: pkValue,
    ),
  );
}

class _EditRowDialog extends StatefulWidget {
  final String schema;
  final List<Map<String, dynamic>> colunas;
  final Map<String, dynamic> rowData;
  final String? pkColumn;
  final dynamic pkValue;

  const _EditRowDialog({
    required this.schema,
    required this.colunas,
    required this.rowData,
    this.pkColumn,
    this.pkValue,
  });

  @override
  State<_EditRowDialog> createState() => _EditRowDialogState();
}

class _EditRowDialogState extends State<_EditRowDialog> {
  final Map<String, dynamic> _valoresEditados = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    // Inicializa controladores e valores editados
    for (final col in widget.colunas) {
      final nome = col['nome']?.toString() ?? '';
      final valorOriginal = widget.rowData[nome];
      _valoresEditados[nome] = valorOriginal;

      final tipo = _inferirTipo(col, valorOriginal);
      if (tipo != 'bool' && tipo != 'date') {
        _controllers[nome] = TextEditingController(
          text: valorOriginal?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String _inferirTipo(Map<String, dynamic> colMeta, dynamic valor) {
    final tipo = colMeta['tipo']?.toString().toLowerCase() ?? '';
    if (tipo.contains('bool') ||
        tipo.contains('bit') ||
        tipo.contains('boolean')) {
      return 'bool';
    }
    if (tipo.contains('date') ||
        tipo.contains('timestamp') ||
        tipo.contains('time')) {
      return 'date';
    }
    if (tipo.contains('int') ||
        tipo.contains('numeric') ||
        tipo.contains('decimal') ||
        tipo.contains('float') ||
        tipo.contains('double')) {
      return 'number';
    }
    // Tenta inferir pelo valor
    if (valor is bool) return 'bool';
    return 'text';
  }

  bool _isPk(String nomeCol) {
    return nomeCol == widget.pkColumn;
  }

  Future<void> _salvar() async {
    if (widget.pkColumn == null) {
      _mostrarErro('Coluna PK não identificada. Não é possível editar.');
      return;
    }

    // Monta mapa só com colunas alteradas
    final alteradas = <String, dynamic>{};
    for (final col in widget.colunas) {
      final nome = col['nome']?.toString() ?? '';
      if (_isPk(nome)) continue;

      dynamic valorNovo = _valoresEditados[nome];
      dynamic valorOriginal = widget.rowData[nome];

      if (_controllers.containsKey(nome)) {
        valorNovo = _controllers[nome]!.text;
      }

      // Converte tipos
      final tipo = _inferirTipo(col, valorOriginal);
      if (tipo == 'number' && valorNovo is String && valorNovo.isNotEmpty) {
        if (valorNovo.contains('.')) {
          valorNovo = double.tryParse(valorNovo) ?? valorNovo;
        } else {
          valorNovo = int.tryParse(valorNovo) ?? valorNovo;
        }
      } else if (tipo == 'bool' && valorNovo is bool) {
        valorNovo = valorNovo;
      }

      if (valorNovo != valorOriginal) {
        alteradas[nome] = valorNovo;
      }
    }

    if (alteradas.isEmpty) {
      _mostrarSnackBar('Nenhuma alteração detectada.');
      Navigator.pop(context, true);
      return;
    }

    setState(() => _salvando = true);

    final tabela = _inferirTabela();
    if (tabela.isEmpty) {
      _mostrarErro('Nome da tabela não encontrado nos metadados. Não é possível editar.');
      return;
    }
    final resultado = await QueryBuilderCaller.atualizarRegistro(
      tabela,
      widget.schema,
      widget.pkColumn!,
      widget.pkValue,
      alteradas,
    );

    if (!mounted) return;
    setState(() => _salvando = false);

    if (resultado.containsKey('erro') || resultado.containsKey('error')) {
      final msg = resultado['erro'] ?? resultado['error'] ?? 'Erro ao atualizar';
      _mostrarErro(msg.toString());
    } else {
      _mostrarSnackBar('Registro atualizado com sucesso.');
      Navigator.pop(context, true);
    }
  }

  String _inferirTabela() {
    for (final col in widget.colunas) {
      if (col.containsKey('tabela')) {
        return col['tabela'].toString();
      }
    }
    return '';
  }

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: GridColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
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
                  Icon(Icons.edit, color: GridColors.textPrimary, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Editar Registro',
                    style: TextStyle(
                      color: GridColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Formulário
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.colunas.map((col) {
                      final nome = col['nome']?.toString() ?? '';
                      final tipo = _inferirTipo(col, widget.rowData[nome]);
                      final isPk = _isPk(nome);
                      final valor = widget.rowData[nome];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildField(nome, tipo, isPk, valor, col),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            // Ações
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _salvando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.primary,
                      foregroundColor: GridColors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: GridColors.textPrimary,
                            ),
                          )
                        : const Text('Salvar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String nome,
    String tipo,
    bool isPk,
    dynamic valor,
    Map<String, dynamic> colMeta,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isPk)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.vpn_key,
                    size: 12, color: GridColors.warning),
              ),
            Text(
              nome,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GridColors.textSecondary,
              ),
            ),
            if (isPk)
              const Text(
                ' (PK)',
                style: TextStyle(
                  fontSize: 11,
                  color: GridColors.warning,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (colMeta.containsKey('tipo'))
              Text(
                '  — ${colMeta['tipo']}',
                style: const TextStyle(
                  fontSize: 10,
                  color: GridColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (isPk)
          _buildReadOnlyField(valor)
        else
          _buildEditableField(nome, tipo, valor),
      ],
    );
  }

  Widget _buildReadOnlyField(dynamic valor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GridColors.disabledBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GridColors.divider),
      ),
      child: Text(
        valor?.toString() ?? GridTexts.noRecords,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: GridColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildEditableField(String nome, String tipo, dynamic valor) {
    switch (tipo) {
      case 'bool':
        return _buildBoolField(nome, valor);
      case 'date':
        return _buildDateField(nome, valor);
      case 'number':
        return _buildTextField(nome, tipo, valor);
      default:
        return _buildTextField(nome, tipo, valor);
    }
  }

  Widget _buildTextField(String nome, String tipo, dynamic valor) {
    final controller = _controllers[nome]!;
    final isNumber = tipo == 'number';

    return TextField(
      controller: controller,
      onChanged: (v) => _valoresEditados[nome] = v,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: GridColors.textSecondary,
      ),
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintText: isNumber ? '0' : '',
      ),
    );
  }

  Widget _buildBoolField(String nome, dynamic valor) {
    final boolValue = valor == true ||
        valor == 1 ||
        valor == 'true' ||
        valor == 'TRUE' ||
        valor == 't';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: GridColors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Checkbox(
            value: boolValue,
            onChanged: (v) {
              setState(() {
                _valoresEditados[nome] = v == true;
              });
            },
            activeColor: GridColors.primary,
          ),
          Text(
            boolValue ? 'true' : 'false',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: boolValue ? GridColors.success : GridColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String nome, dynamic valor) {
    DateTime? data;
    if (valor is String && valor.isNotEmpty) {
      data = DateTime.tryParse(valor);
    } else if (valor is DateTime) {
      data = valor;
    }

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: data ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            _valoresEditados[nome] = picked.toIso8601String().split('T').first;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: GridColors.divider),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 16, color: GridColors.primary),
            const SizedBox(width: 8),
            Text(
              _valoresEditados[nome]?.toString() ??
                  (data?.toIso8601String().split('T').first ??
                      'Selecionar data...'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: GridColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
