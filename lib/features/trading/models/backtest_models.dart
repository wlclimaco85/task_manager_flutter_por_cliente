class BacktestRunResponse {
  final String id;
  final String assetSymbol;
  final String strategyName;
  final String status;
  final String? periodStart;
  final String? periodEnd;
  final String? createdAt;
  final int numTrades;
  final int numWins;
  final int numLosses;
  final double totalProfit;
  final double totalLoss;
  final double netResult;
  final double maxDrawdown;
  final double winRate;

  BacktestRunResponse({
    required this.id,
    required this.assetSymbol,
    required this.strategyName,
    required this.status,
    this.periodStart,
    this.periodEnd,
    this.createdAt,
    required this.numTrades,
    required this.numWins,
    required this.numLosses,
    required this.totalProfit,
    required this.totalLoss,
    required this.netResult,
    required this.maxDrawdown,
    required this.winRate,
  });

  factory BacktestRunResponse.fromJson(Map<String, dynamic> json) => BacktestRunResponse(
        id: json['id'].toString(),
        assetSymbol: json['assetSymbol'] ?? '',
        strategyName: json['strategyName'] ?? '',
        status: json['status'] ?? '',
        periodStart: json['periodStart']?.toString(),
        periodEnd: json['periodEnd']?.toString(),
        createdAt: json['createdAt']?.toString(),
        numTrades: (json['numTrades'] ?? 0) as int,
        numWins: (json['numWins'] ?? 0) as int,
        numLosses: (json['numLosses'] ?? 0) as int,
        totalProfit: (json['totalProfit'] ?? 0).toDouble(),
        totalLoss: (json['totalLoss'] ?? 0).toDouble(),
        netResult: (json['netResult'] ?? 0).toDouble(),
        maxDrawdown: (json['maxDrawdown'] ?? 0).toDouble(),
        winRate: (json['winRate'] ?? 0).toDouble(),
      );
}
