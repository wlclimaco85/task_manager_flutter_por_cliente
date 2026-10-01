class BankImportResult {
  final String importId;
  final String status;
  final String message;
  final int entryCount;

  const BankImportResult({
    required this.importId,
    required this.status,
    required this.message,
    required this.entryCount,
  });

  factory BankImportResult.fromJson(Map<String, dynamic> json) {
    return BankImportResult(
      importId: _pick(json, ['importId', 'import_id']) ?? '',
      status: _pick(json, ['status']) ?? 'PENDING',
      message: _pick(json, ['message']) ?? '',
      entryCount: _pickInt(json, ['entryCount', 'entry_count']) ?? 0,
    );
  }
}

class BankReconciliationResult {
  final String importId;
  final String status;
  final String message;
  final int matchedCount;
  final int pendingCount;

  const BankReconciliationResult({
    required this.importId,
    required this.status,
    required this.message,
    required this.matchedCount,
    required this.pendingCount,
  });

  factory BankReconciliationResult.fromJson(Map<String, dynamic> json) {
    return BankReconciliationResult(
      importId: _pick(json, ['importId', 'import_id']) ?? '',
      status: _pick(json, ['status']) ?? 'PENDING',
      message: _pick(json, ['message']) ?? '',
      matchedCount: _pickInt(json, ['matchedCount', 'matched_count']) ?? 0,
      pendingCount: _pickInt(json, ['pendingCount', 'pending_count']) ?? 0,
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
