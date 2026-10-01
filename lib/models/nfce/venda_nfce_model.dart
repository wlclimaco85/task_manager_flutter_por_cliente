import 'item_venda_model.dart';

class VendaNfceModel {
  final int empresaId;
  final List<ItemVendaModel> itens;
  final List<PagamentoModel> pagamentos;
  final String? clienteCpfCnpj;
  final double desconto;

  const VendaNfceModel({
    required this.empresaId,
    required this.itens,
    required this.pagamentos,
    this.clienteCpfCnpj,
    this.desconto = 0,
  });

  double get subtotal =>
      itens.fold(0, (sum, item) => sum + (item.precoUnitario * item.quantidade));

  double get total => subtotal - desconto;

  Map<String, dynamic> toJson() => {
        'empresaId': empresaId,
        'itens': itens.map((i) => i.toJson()).toList(),
        'pagamentos': pagamentos.map((p) => p.toJson()).toList(),
        if (clienteCpfCnpj != null && clienteCpfCnpj!.isNotEmpty)
          'clienteCpfCnpj': clienteCpfCnpj,
        'desconto': desconto,
      };
}
