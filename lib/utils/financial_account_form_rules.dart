const _financialScreens = {'contapagar', 'contareceber'};

const _recurrenceFields = {
  'recorrenciaativa',
  'tiporecorrencia',
  'quantidaderecorrencia',
  'diavencimento',
  'parcelaatual',
  'totalparcelas',
  'valorparcela',
};

const _settlementFields = {
  'databaixa',
  'valorbaixa',
  'valormulta',
  'valorjuros',
  'valordesconto',
  'formapagamento',
  'contabaixa',
};

String _normalizeFinancialName(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

int financialAccountFormOrder({
  required String screenName,
  required String fieldName,
  required int backendOrder,
  required bool isRequired,
}) {
  if (!_financialScreens.contains(_normalizeFinancialName(screenName))) {
    return backendOrder;
  }

  final normalizedField = _normalizeFinancialName(fieldName);
  if (isRequired) return backendOrder;
  if (_recurrenceFields.contains(normalizedField)) return 20000 + backendOrder;
  if (_settlementFields.contains(normalizedField)) return 30000 + backendOrder;
  return 10000 + backendOrder;
}
