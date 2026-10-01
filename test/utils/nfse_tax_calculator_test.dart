import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/nfse_tax_calculator.dart';

void main() {
  test('calcula ISS de 3% sobre servico de 1621 em 48,63', () {
    final result = NfseTaxCalculator.calculate(
      quantidade: 1,
      valorUnitario: 1621,
      aliquotaIss: 3,
    );

    expect(result.valorTotal, 1621.00);
    expect(result.valorIss, 48.63);
  });

  test('retencao nao altera o valor calculado do ISS', () {
    final result = NfseTaxCalculator.calculate(
      quantidade: 2,
      valorUnitario: 100,
      aliquotaIss: 3,
    );

    expect(result.valorIss, 6.00);
  });
}
