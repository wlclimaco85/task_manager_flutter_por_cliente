class CrmDeal {
  final int? id;
  final String tenantId;
  final int? empresaId;
  final int? parceiroId;
  final String title;
  final String? customerName;
  final String source;
  final String? marketplace;
  final String? externalOrderId;
  final String stage;
  final double? amount;
  final DateTime? expectedCloseDate;
  final String status;
  final String? notes;

  const CrmDeal({
    this.id,
    required this.tenantId,
    this.empresaId,
    this.parceiroId,
    required this.title,
    this.customerName,
    required this.source,
    this.marketplace,
    this.externalOrderId,
    required this.stage,
    this.amount,
    this.expectedCloseDate,
    required this.status,
    this.notes,
  });

  factory CrmDeal.fromJson(Map<String, dynamic> json) {
    return CrmDeal(
      id: (json['id'] as num?)?.toInt(),
      tenantId: json['tenantId']?.toString() ?? '',
      empresaId: (json['empresaId'] as num?)?.toInt(),
      parceiroId: (json['parceiroId'] as num?)?.toInt(),
      title: json['title']?.toString() ?? '',
      customerName: json['customerName']?.toString(),
      source: json['source']?.toString() ?? 'MANUAL',
      marketplace: json['marketplace']?.toString(),
      externalOrderId: json['externalOrderId']?.toString(),
      stage: json['stage']?.toString() ?? 'LEAD',
      amount: (json['amount'] as num?)?.toDouble(),
      expectedCloseDate: _parseDate(json['expectedCloseDate']),
      status: json['status']?.toString() ?? 'OPEN',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tenantId': tenantId,
      if (empresaId != null) 'empresaId': empresaId,
      if (parceiroId != null) 'parceiroId': parceiroId,
      'title': title,
      if (customerName != null) 'customerName': customerName,
      'source': source,
      if (marketplace != null) 'marketplace': marketplace,
      if (externalOrderId != null) 'externalOrderId': externalOrderId,
      'stage': stage,
      if (amount != null) 'amount': amount,
      if (expectedCloseDate != null)
        'expectedCloseDate': expectedCloseDate!.toIso8601String().split('T').first,
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
