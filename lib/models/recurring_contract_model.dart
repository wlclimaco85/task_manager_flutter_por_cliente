class RecurringContract {
  final String contractId;
  final int? empresaId;
  final int? parceiroId;
  final String customerName;
  final String? customerDocument;
  final String planName;
  final String? serviceDescription;
  final String? municipalityCode;
  final double monthlyValue;
  final DateTime nextDueDate;
  final String status;

  const RecurringContract({
    required this.contractId,
    this.empresaId,
    this.parceiroId,
    required this.customerName,
    this.customerDocument,
    required this.planName,
    this.serviceDescription,
    this.municipalityCode,
    required this.monthlyValue,
    required this.nextDueDate,
    required this.status,
  });

  factory RecurringContract.fromJson(Map<String, dynamic> json) {
    return RecurringContract(
      contractId: _pick(json, ['contractId', 'contract_id']) ?? '',
      empresaId: _pickInt(json, ['empresaId', 'empresa_id']),
      parceiroId: _pickInt(json, ['parceiroId', 'parceiro_id']),
      customerName: _pick(json, ['customerName', 'customer_name']) ?? '',
      customerDocument: _pick(json, ['customerDocument', 'customer_document']),
      planName: _pick(json, ['planName', 'plan_name']) ?? '',
      serviceDescription:
          _pick(json, ['serviceDescription', 'service_description']),
      municipalityCode: _pick(json, ['municipalityCode', 'municipality_code']),
      monthlyValue: _pickDouble(json, ['monthlyValue', 'monthly_value']) ?? 0,
      nextDueDate: DateTime.tryParse(
              _pick(json, ['nextDueDate', 'next_due_date']) ?? '') ??
          DateTime.now(),
      status: _pick(json, ['status']) ?? 'ACTIVE',
    );
  }
}

class RecurringInvoice {
  final String invoiceId;
  final String contractId;
  final String status;
  final String? message;
  final int? contaReceberId;
  final String? nfseNumber;
  final String? nfseStatus;
  final DateTime? nextDueDate;

  const RecurringInvoice({
    required this.invoiceId,
    required this.contractId,
    required this.status,
    this.message,
    this.contaReceberId,
    this.nfseNumber,
    this.nfseStatus,
    this.nextDueDate,
  });

  factory RecurringInvoice.fromJson(Map<String, dynamic> json) {
    return RecurringInvoice(
      invoiceId: _pick(json, ['invoiceId', 'invoice_id']) ?? '',
      contractId: _pick(json, ['contractId', 'contract_id']) ?? '',
      status: _pick(json, ['status']) ?? 'OPEN',
      message: _pick(json, ['message']),
      contaReceberId: _pickInt(json, ['contaReceberId', 'conta_receber_id']),
      nfseNumber: _pick(json, ['nfseNumber', 'nfse_number']),
      nfseStatus: _pick(json, ['nfseStatus', 'nfse_status']),
      nextDueDate: DateTime.tryParse(
        _pick(json, ['nextDueDate', 'next_due_date']) ?? '',
      ),
    );
  }
}

String? _pick(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) {
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
  }
  return null;
}

int? _pickInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value != null) {
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

double? _pickDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value != null) {
      final parsed = double.tryParse(value.toString().replaceAll(',', '.'));
      if (parsed != null) return parsed;
    }
  }
  return null;
}
