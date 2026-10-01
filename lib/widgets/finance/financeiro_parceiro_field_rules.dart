class FinanceiroParceiroFieldRules {
  const FinanceiroParceiroFieldRules._();

  static int? normalizarParceiroId(Object? parceiroId) {
    if (parceiroId == null) return null;
    if (parceiroId is num) {
      final id = parceiroId.toInt();
      return id > 0 ? id : null;
    }
    final id = int.tryParse(parceiroId.toString().trim());
    return id != null && id > 0 ? id : null;
  }

  static bool parceiroHabilitado({Object? parceiroId, Object? parcId}) =>
      normalizarParceiroId(parceiroId) == null &&
      normalizarParceiroId(parcId) == null;

  /// Fornecedor (quem recebe o pagamento em contas a pagar ou quem deve em contas a receber)
  /// deve ficar SEMPRE habilitado para seleção em cadastros e edições financeiras.
  static bool fornecedorHabilitado({Object? parceiroId, Object? parcId}) => true;
}
