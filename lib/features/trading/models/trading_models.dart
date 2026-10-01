class TradingSignal {
  final String id;
  final String assetSymbol;
  final String signalType;
  final String status;
  final double score;

  TradingSignal({required this.id, required this.assetSymbol, required this.signalType, required this.status, required this.score});

  factory TradingSignal.fromJson(Map<String, dynamic> json) => TradingSignal(
    id: json['id'].toString(),
    assetSymbol: json['assetSymbol'] ?? json['symbol'] ?? '',
    signalType: json['signalType'] ?? '',
    status: json['status'] ?? '',
    score: (json['score'] ?? 0).toDouble(),
  );
}

class Opportunity {
  final String id;
  final String assetSymbol;
  final double scoreValue;
  final String recommendation;

  Opportunity({required this.id, required this.assetSymbol, required this.scoreValue, required this.recommendation});

  factory Opportunity.fromJson(Map<String, dynamic> json) => Opportunity(
    id: json['id'].toString(),
    assetSymbol: json['assetSymbol'] ?? '',
    scoreValue: (json['scoreValue'] ?? 0).toDouble(),
    recommendation: json['recommendation'] ?? '',
  );
}
