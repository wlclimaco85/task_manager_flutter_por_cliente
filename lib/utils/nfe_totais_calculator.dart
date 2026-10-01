import '../models/nfe/nfe_item_model.dart';

/// Resultado do cálculo de totais de uma NFe a partir dos seus itens.
///
/// Cálculo somente para exibição no formulário (preview client-side); o
/// valor definitivo é sempre recalculado pelo backend (calculadoras
/// fiscais em `NfeIcmsCalculatorService` e afins).
class NfeTotais {
  final double subtotal;
  final double icms;
  final double pis;
  final double cofins;
  final double desconto;
  final double total;

  const NfeTotais({
    required this.subtotal,
    required this.icms,
    required this.pis,
    required this.cofins,
    this.desconto = 0.0,
    required this.total,
  });

  static const zero = NfeTotais(subtotal: 0, icms: 0, pis: 0, cofins: 0, total: 0);
}

/// Calcula os totais de uma NFe a partir da lista de itens.
///
/// Centraliza a lógica que antes estava duplicada entre as telas de
/// criação Mobile, Web e Windows.
class NfeTotaisCalculator {
  const NfeTotaisCalculator._();

  static NfeTotais calcular(List<NfeItemModel> items) {
    if (items.isEmpty) return NfeTotais.zero;

    var subtotal = 0.0;
    var icms = 0.0;
    var pis = 0.0;
    var cofins = 0.0;

    for (final item in items) {
      subtotal += item.precoTotal;
      icms += item.vlIcms;
      pis += item.vlPis;
      cofins += item.vlCofins;
    }

    const desconto = 0.0; // sem desconto por enquanto
    final total = subtotal + icms + pis + cofins - desconto;

    return NfeTotais(
      subtotal: subtotal,
      icms: icms,
      pis: pis,
      cofins: cofins,
      desconto: desconto,
      total: total,
    );
  }
}
