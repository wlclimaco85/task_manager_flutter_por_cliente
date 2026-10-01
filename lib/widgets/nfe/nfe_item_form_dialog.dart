import 'package:flutter/material.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';

/// Dialog reutilizável para adicionar/editar um item de NFe.
///
/// Usado tanto pela tela mobile ([NfeFormScreen]) quanto pelas telas
/// Web/Windows ([NfeSaidaCreateScreen]), garantindo o mesmo conjunto de
/// campos e a mesma validação em todas as plataformas.
///
/// Retorna o [NfeItemModel] preenchido via `Navigator.pop`, ou `null` se o
/// usuário cancelar.
class NfeItemFormDialog extends StatefulWidget {
  /// Item existente para edição. Quando `null`, o dialog abre em modo de
  /// criação de um novo item.
  final NfeItemModel? item;

  /// Próximo número sequencial sugerido (usado apenas na criação).
  final int proximoSequencial;

  const NfeItemFormDialog({
    super.key,
    this.item,
    required this.proximoSequencial,
  });

  /// Abre o dialog e retorna o item preenchido, ou `null` se cancelado.
  static Future<NfeItemModel?> show(
    BuildContext context, {
    NfeItemModel? item,
    required int proximoSequencial,
  }) {
    return showDialog<NfeItemModel>(
      context: context,
      builder: (_) => NfeItemFormDialog(
        item: item,
        proximoSequencial: proximoSequencial,
      ),
    );
  }

  @override
  State<NfeItemFormDialog> createState() => _NfeItemFormDialogState();
}

class _NfeItemFormDialogState extends State<NfeItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigoCtrl;
  late final TextEditingController _descricaoCtrl;
  late final TextEditingController _ncmCtrl;
  late final TextEditingController _cfopCtrl;
  late final TextEditingController _unidadeCtrl;
  late final TextEditingController _quantidadeCtrl;
  late final TextEditingController _precoUnitarioCtrl;

  bool get _editando => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _codigoCtrl = TextEditingController(text: item?.codigoProduto ?? '');
    _descricaoCtrl = TextEditingController(text: item?.descricao ?? '');
    _ncmCtrl = TextEditingController(text: item?.ncm ?? '');
    _cfopCtrl = TextEditingController(text: item?.cfop ?? '5102');
    _unidadeCtrl = TextEditingController(text: item?.unidade ?? 'UN');
    _quantidadeCtrl = TextEditingController(
        text: item != null ? item.quantidade.toStringAsFixed(2) : '1.00');
    _precoUnitarioCtrl = TextEditingController(
        text: item != null ? item.precoUnitario.toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _descricaoCtrl.dispose();
    _ncmCtrl.dispose();
    _cfopCtrl.dispose();
    _unidadeCtrl.dispose();
    _quantidadeCtrl.dispose();
    _precoUnitarioCtrl.dispose();
    super.dispose();
  }

  double _parseDecimal(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;

    final quantidade = _parseDecimal(_quantidadeCtrl.text);
    final precoUnitario = _parseDecimal(_precoUnitarioCtrl.text);
    final precoTotal = quantidade * precoUnitario;

    // Mantém alíquotas/valores de impostos já calculados quando editando;
    // ao criar, usa os defaults do regime padrão (mesmo comportamento
    // anterior do formulário mobile).
    final anterior = widget.item;
    final item = NfeItemModel(
      sequencial: anterior?.sequencial ?? widget.proximoSequencial,
      codigoProduto: _codigoCtrl.text.trim(),
      descricao: _descricaoCtrl.text.trim(),
      ncm: _ncmCtrl.text.trim(),
      quantidade: quantidade,
      unidade: _unidadeCtrl.text.trim(),
      precoUnitario: precoUnitario,
      precoTotal: precoTotal,
      cfop: _cfopCtrl.text.trim(),
      cstIcms: anterior?.cstIcms ?? '00',
      aliqIcms: anterior?.aliqIcms ?? 0.18,
      vlIcms: precoTotal * (anterior?.aliqIcms ?? 0.18),
      aliqPis: anterior?.aliqPis ?? 0.0165,
      vlPis: precoTotal * (anterior?.aliqPis ?? 0.0165),
      aliqCofins: anterior?.aliqCofins ?? 0.076,
      vlCofins: precoTotal * (anterior?.aliqCofins ?? 0.076),
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar Item' : 'Adicionar Item'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _descricaoCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Descrição obrigatória' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codigoCtrl,
                        decoration: const InputDecoration(labelText: 'Código *'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ncmCtrl,
                        decoration: const InputDecoration(labelText: 'NCM *'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cfopCtrl,
                        decoration: const InputDecoration(labelText: 'CFOP *'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unidadeCtrl,
                        decoration: const InputDecoration(labelText: 'Unidade *'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantidadeCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Quantidade *'),
                        validator: (v) {
                          final n = _parseDecimal(v ?? '');
                          return n <= 0 ? 'Deve ser maior que 0' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _precoUnitarioCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Preço Unitário (R\$) *'),
                        validator: (v) {
                          final n = _parseDecimal(v ?? '');
                          return n <= 0 ? 'Deve ser maior que 0' : null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          child: Text(_editando ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}
