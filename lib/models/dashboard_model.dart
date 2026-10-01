// lib/dashboard/models.dart
class FinancePoint {
  final String month; // ex: '2025-06'
  final double receivable;
  final double payable;

  FinancePoint(this.month, this.receivable, this.payable);

  factory FinancePoint.fromJson(Map<String, dynamic> json) {
    return FinancePoint(
      (json['month'] ?? '').toString(),
      _toDouble(json['receivable']),
      _toDouble(json['payable']),
    );
  }
}

class FinanceFluxoPoint {
  final DateTime day;
  final double payable;
  final double receivable;

  FinanceFluxoPoint(this.day, this.payable, this.receivable);

  double get net => receivable - payable;

  factory FinanceFluxoPoint.fromJson(Map<String, dynamic> json) {
    return FinanceFluxoPoint(
      _toDate(json['day']),
      _toDouble(json['payableTotal'] ?? json['payable']),
      _toDouble(json['receivableTotal'] ?? json['receivable']),
    );
  }
}

class TicketStatusCounts {
  final int open;
  final int inProgress;
  final int closed;

  TicketStatusCounts({
    required this.open,
    required this.inProgress,
    required this.closed,
  });

  factory TicketStatusCounts.fromJson(Map<String, dynamic> json) {
    return TicketStatusCounts(
      open: _toInt(json['open']),
      inProgress: _toInt(json['inProgress']),
      closed: _toInt(json['closed']),
    );
  }
}

class ChatsDailyPoint {
  final DateTime date;
  final int openChats;

  ChatsDailyPoint(this.date, this.openChats);

  factory ChatsDailyPoint.fromJson(Map<String, dynamic> json) {
    return ChatsDailyPoint(
      _toDate(json['date']),
      _toInt(json['openChats']),
    );
  }
}

/// ---------- Helpers de parsing seguros ----------
double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String && v.trim().isNotEmpty) {
    return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
  }
  return 0.0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String && v.trim().isNotEmpty) {
    return int.tryParse(v) ?? 0;
  }
  return 0;
}

DateTime _toDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  final s = v.toString();
  return DateTime.tryParse(s) ?? DateTime.now();
}
