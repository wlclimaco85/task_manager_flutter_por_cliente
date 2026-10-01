import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

/// Formulário de inserção/edição de item/serviço da nota fiscal.
///
/// Desktop: Dialog com largura 520dp.
/// Mobile: BottomSheet rolável.
class ItemFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> produtos;
  final Map<String, dynamic>? itemExistente;
  final Function(Map<String, dynamic>) onSalvar;

  const ItemFormSheet({
    super.key,
    required this.produtos,
    required this.onSalvar,
    this.itemExistente,
  });

  /// Abre como Dialog em desktop ou BottomSheet em mobile.
  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> produtos,
    required Function(Map<String, dynamic>) onSalvar,
    Map<String, dynamic>? itemExistente,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => ItemFormSheet(
          produtos: produtos,
          onSalvar: onSalvar,
          itemExistente: itemExistente,
        ),
      );
    }
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          width: 520,
          child: ItemFormSheet(
            produtos: produtos,
            onSalvar: onSalvar,
            itemExistente: itemExistente,
          ),
        ),
      ),
    );
  }

  @override
  State<ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _produtoId;
  String? _produtoNome;
  final _qtdCtrl = TextEditingController();
  final _vlrUnitCtrl = TextEditingController();
  double _total = 0;

  @override
  void initState() {
    super.initState();
    final e = widget.itemExistente;
    if (e != null) {
      final prod = e['produto'];
      if (prod is Map) {
        _produtoId = prod['id']?.toString();
        _produtoNome = prod['nome']?.toString();
      }
      _qtdCtrl.text = e['quantidade']?.toString() ?? '';
      _vlrUnitCtrl.text =
          (e['valorUnitario'] ?? e['valor_unitario'])?.toString() ?? '';
      _recalcular();
    }
    _qtdCtrl.addListener(_recalcular);
    _vlrUnitCtrl.addListener(_recalcular);
  }

  @override
  void dispose() {
    _qtdCtrl.dispose();
    _vlrUnitCtrl.dispose();
    super.dispose();
  }

  void _recalcular() {
    final qtd = double.tryParse(_qtdCtrl.text) ?? 0;
    final unit = double.tryParse(_vlrUnitCtrl.text) ?? 0;
    if (mounted) setState(() => _total = qtd * unit);
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    final qtd = double.tryParse(_qtdCtrl.text) ?? 0;
    final unit = double.tryParse(_vlrUnitCtrl.text) ?? 0;
    final total = qtd * unit;
    final item = <String, dynamic>{
      if (widget.itemExistente?['id'] != null) 'id': widget.itemExistente!['id'],
      if (widget.itemExistente?['nfse_id'] != null)
        'nfse_id': widget.itemExistente!['nfse_id'],
      if (_produtoId != null)
        'produto': {'id': int.tryParse(_produtoId!) ?? _produtoId, 'nome': _produtoNome},
      'descricao': _produtoNome ?? '',
      'quantidade': qtd,
      'valorUnitario': unit,
      'valorTotal': total,
    };
    widget.onSalvar(item);
    Navigator.of(context).pop();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: GridColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: GridColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: GridColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    final isEditar = widget.itemExistente?['id'] != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.build_outlined, color: GridColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  isEditar ? 'Editar Serviço' : 'Adicionar Serviço',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: GridColors.textSecondary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 20),
            // Dropdown de produto
            DropdownButtonFormField<String>(
              value: _produtoId,
              decoration: _dec('Produto/Serviço'),
              items: widget.produtos
                  .map((p) => DropdownMenuItem<String>(
                        value: p['id']?.toString(),
                        child: Text(
                          p['nome']?.toString() ?? p['id']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _produtoId = v;
                  _produtoNome = widget.produtos
                      .firstWhere(
                        (p) => p['id']?.toString() == v,
                        orElse: () => {},
                      )['nome']
                      ?.toString();
                });
              },
              validator: (v) => v == null ? 'Selecione o produto/serviço' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtdCtrl,
                    decoration: _dec('Quantidade'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        (double.tryParse(v ?? '') == null || double.parse(v!) <= 0)
                            ? 'Informe a quantidade'
                            : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _vlrUnitCtrl,
                    decoration: _dec('Valor Unitário'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        (double.tryParse(v ?? '') == null || double.parse(v!) <= 0)
                            ? 'Informe o valor'
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GridColors.primarySoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: GridColors.primary,
                    ),
                  ),
                  Text(
                    'R\$ ${_total.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: GridColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(isEditar ? 'Salvar Alterações' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}
