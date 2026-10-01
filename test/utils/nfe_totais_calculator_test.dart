import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';
import 'package:task_manager_flutter/utils/nfe_totais_calculator.dart';

NfeItemModel _item({
  double precoTotal = 0,
  double vlIcms = 0,
  double vlPis = 0,
  double vlCofins = 0,
}) {
  return NfeItemModel(
    sequencial: 1,
    codigoProduto: 'P1',
    descricao: 'Produto',
    ncm: '12345678',
    cfop: '5102',
    cstIcms: '00',
    quantidade: 1,
    unidade: 'UN',
    precoUnitario: precoTotal,
    precoTotal: precoTotal,
    aliqIcms: 0.18,
    vlIcms: vlIcms,
    aliqPis: 0.0165,
    vlPis: vlPis,
    aliqCofins: 0.076,
    vlCofins: vlCofins,
  );
}

void main() {
  group('NfeTotaisCalculator', () {
    test('retorna zero para lista vazia', () {
      final totais = NfeTotaisCalculator.calcular([]);
      expect(totais.subtotal, 0);
      expect(totais.icms, 0);
      expect(totais.total, 0);
    });

    test('soma subtotal, impostos e total de múltiplos itens', () {
      final itens = [
        _item(precoTotal: 100, vlIcms: 18, vlPis: 1.65, vlCofins: 7.6),
        _item(precoTotal: 50, vlIcms: 9, vlPis: 0.825, vlCofins: 3.8),
      ];

      final totais = NfeTotaisCalculator.calcular(itens);

      expect(totais.subtotal, 150);
      expect(totais.icms, closeTo(27, 0.001));
      expect(totais.pis, closeTo(2.475, 0.001));
      expect(totais.cofins, closeTo(11.4, 0.001));
      expect(totais.desconto, 0);
      expect(totais.total, closeTo(150 + 27 + 2.475 + 11.4, 0.001));
    });
  });
}
