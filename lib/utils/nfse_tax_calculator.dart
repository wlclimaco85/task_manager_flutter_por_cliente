class NfseTaxResult {
  final double valorTotal;
  final double valorIss;

  const NfseTaxResult({required this.valorTotal, required this.valorIss});
}

class NfseTaxCalculator {
  static NfseTaxResult calculate({
    required double quantidade,
    required double valorUnitario,
    required double aliquotaIss,
  }) {
    final valorTotal = quantidade * valorUnitario;
    final valorIss = valorTotal * aliquotaIss / 100;
    return NfseTaxResult(
      valorTotal: _roundCurrency(valorTotal),
      valorIss: _roundCurrency(valorIss),
    );
  }

  static double _roundCurrency(double value) =>
      (value * 100).roundToDouble() / 100;
}
