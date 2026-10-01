// Trading models — sinais, oportunidades, watchlist, alertas, operações assistidas
// e configuração de corretora.
// Campos alinhados com o JSON retornado pelo backend Spring Boot.

import 'dart:convert';

class TradingSignal {
  final String id;
  final String assetSymbol; // backend: assetSymbol
  final String signalType; // backend: signalType (ex: "BUY" | "SELL" | "HOLD")
  final String status; // backend: status
  final double score; // backend: score (BigDecimal → double)
  final double priceAtSignal; // backend: priceAtSignal
  final String triggeredAt; // backend: triggeredAt (Instant → String ISO-8601)
  final String? source;
  final double? confidence;
  final String? timeframe;

  const TradingSignal({
    required this.id,
    required this.assetSymbol,
    required this.signalType,
    required this.status,
    required this.score,
    required this.priceAtSignal,
    required this.triggeredAt,
    this.source,
    this.confidence,
    this.timeframe,
  });

  factory TradingSignal.fromJson(Map<String, dynamic> json) {
    return TradingSignal(
      id: json['id']?.toString() ?? '',
      // aceita 'assetSymbol' (backend) ou 'asset' (legado)
      assetSymbol:
          json['assetSymbol']?.toString() ?? json['asset']?.toString() ?? '',
      // aceita 'signalType' (backend) ou 'direction' (legado)
      signalType:
          json['signalType']?.toString() ?? json['direction']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      // aceita 'score' ou 'confidence' como fallback
      score: _toDouble(json['score'] ?? json['confidence']),
      // aceita 'priceAtSignal' (backend) ou 'price' (legado)
      priceAtSignal: _toDouble(json['priceAtSignal'] ?? json['price']),
      // aceita 'triggeredAt' (backend) ou 'createdAt' (legado)
      triggeredAt: json['triggeredAt']?.toString() ??
          json['createdAt']?.toString() ??
          '',
      source: json['source']?.toString(),
      confidence:
          json['confidence'] != null ? _toDouble(json['confidence']) : null,
      timeframe: json['timeframe']?.toString(),
    );
  }

  /// Direção de exibição: tenta signalType, fallback para 'HOLD'
  String get displayDirection {
    final t = signalType.toUpperCase();
    if (t.contains('BUY') || t == 'COMPRA') return 'BUY';
    if (t.contains('SELL') || t == 'VENDA') return 'SELL';
    return signalType.isEmpty ? 'HOLD' : signalType;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetSymbol': assetSymbol,
        'signalType': signalType,
        'status': status,
        'score': score,
        'priceAtSignal': priceAtSignal,
        'triggeredAt': triggeredAt,
        if (source != null) 'source': source,
        if (confidence != null) 'confidence': confidence,
        if (timeframe != null) 'timeframe': timeframe,
      };
}

class Opportunity {
  final String id;
  final String assetSymbol; // backend: assetSymbol
  final double scoreValue; // backend: scoreValue
  final String recommendation; // backend: recommendation
  final String? riskLevel; // backend: riskLevel
  final String? horizon; // backend: horizon
  final String? calculatedAt; // backend: calculatedAt
  final String? scoreComponents; // backend: scoreComponents

  const Opportunity({
    required this.id,
    required this.assetSymbol,
    required this.scoreValue,
    required this.recommendation,
    this.riskLevel,
    this.horizon,
    this.calculatedAt,
    this.scoreComponents,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id']?.toString() ?? '',
      // aceita 'assetSymbol' (backend) ou 'asset' (legado)
      assetSymbol:
          json['assetSymbol']?.toString() ?? json['asset']?.toString() ?? '',
      // aceita 'scoreValue' (backend) numérico
      scoreValue: _toDouble(json['scoreValue'] ?? json['score']),
      // aceita 'recommendation' (backend) ou 'description' (legado)
      recommendation: json['recommendation']?.toString() ??
          json['description']?.toString() ??
          '',
      riskLevel: json['riskLevel']?.toString(),
      horizon: json['horizon']?.toString(),
      calculatedAt:
          json['calculatedAt']?.toString() ?? json['detectedAt']?.toString(),
      scoreComponents: json['scoreComponents']?.toString(),
    );
  }

  String get scoreResumo {
    final raw = scoreComponents;
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final fonteCotacao = decoded['fonte_cotacao']?.toString();
        final fontesPlanejadas = decoded['fontes_planejadas'];
        final observacao = decoded['observacao']?.toString();
        final fontes = <String>[
          if (fonteCotacao != null && fonteCotacao.isNotEmpty) fonteCotacao,
          if (fontesPlanejadas is List)
            ...fontesPlanejadas.map((e) => e.toString()),
        ];
        if (fontes.isNotEmpty) {
          return 'Fontes: ${fontes.join(', ')}'
              '${observacao == null || observacao.isEmpty ? '' : ' - $observacao'}';
        }
      }
    } catch (_) {
      return raw;
    }
    return raw;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetSymbol': assetSymbol,
        'scoreValue': scoreValue,
        'recommendation': recommendation,
        if (riskLevel != null) 'riskLevel': riskLevel,
        if (horizon != null) 'horizon': horizon,
        if (calculatedAt != null) 'calculatedAt': calculatedAt,
        if (scoreComponents != null) 'scoreComponents': scoreComponents,
      };
}

// ── Watchlist ─────────────────────────────────────────────────────────────────

class WatchlistItem {
  final String id;
  final String assetSymbol;
  final String? notes;
  final String addedAt;

  const WatchlistItem({
    required this.id,
    required this.assetSymbol,
    this.notes,
    required this.addedAt,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id']?.toString() ?? '',
      assetSymbol: json['assetSymbol']?.toString() ?? '',
      notes: json['notes']?.toString(),
      addedAt: json['addedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetSymbol': assetSymbol,
        if (notes != null) 'notes': notes,
        'addedAt': addedAt,
      };
}

// ── Alertas ───────────────────────────────────────────────────────────────────

class TradingAlerta {
  final String id;
  final String assetSymbol;
  final double priceTarget;
  final String direction; // "ABOVE" | "BELOW"
  final String status; // "ATIVO" | "DISPARADO" | "CANCELADO"
  final String? triggeredAt;
  final String? message;

  const TradingAlerta({
    required this.id,
    required this.assetSymbol,
    required this.priceTarget,
    required this.direction,
    required this.status,
    this.triggeredAt,
    this.message,
  });

  bool get isDisparado => status == 'DISPARADO';
  bool get isAtivo => status == 'ATIVO';
  bool get isCancelado => status == 'CANCELADO';

  factory TradingAlerta.fromJson(Map<String, dynamic> json) {
    return TradingAlerta(
      id: json['id']?.toString() ?? '',
      assetSymbol: json['assetSymbol']?.toString() ?? '',
      priceTarget: _toDouble(json['priceTarget']),
      direction: json['direction']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ATIVO',
      triggeredAt: json['triggeredAt']?.toString(),
      message: json['message']?.toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetSymbol': assetSymbol,
        'priceTarget': priceTarget,
        'direction': direction,
        'status': status,
        if (triggeredAt != null) 'triggeredAt': triggeredAt,
        if (message != null) 'message': message,
      };
}

// ── Operações Assistidas ──────────────────────────────────────────────────────

class OperacaoAssistida {
  final String id;
  final String assetSymbol;
  final String direcao; // "BUY" | "SELL"
  final double quantidade;
  final double? stopLoss;
  final double? takeProfit;
  final String
      status; // "PENDENTE" | "ENVIADA" | "EXECUTADA" | "CANCELADA" | "ERRO"
  final String? externalOrderId;
  final String? errorMessage;
  final String createdAt;
  final String? signalId;

  const OperacaoAssistida({
    required this.id,
    required this.assetSymbol,
    required this.direcao,
    required this.quantidade,
    this.stopLoss,
    this.takeProfit,
    required this.status,
    this.externalOrderId,
    this.errorMessage,
    required this.createdAt,
    this.signalId,
  });

  bool get isPendente => status == 'PENDENTE';
  bool get isEnviada => status == 'ENVIADA';
  bool get isExecutada => status == 'EXECUTADA';
  bool get isCancelada => status == 'CANCELADA';
  bool get isErro => status == 'ERRO';
  bool get cancelavel => isPendente || isEnviada;

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory OperacaoAssistida.fromJson(Map<String, dynamic> json) {
    return OperacaoAssistida(
      id: json['id']?.toString() ?? '',
      assetSymbol: json['assetSymbol']?.toString() ?? '',
      direcao: json['direcao']?.toString() ?? '',
      quantidade: _toDouble(json['quantidade']),
      stopLoss: json['stopLoss'] != null ? _toDouble(json['stopLoss']) : null,
      takeProfit:
          json['takeProfit'] != null ? _toDouble(json['takeProfit']) : null,
      status: json['status']?.toString() ?? 'PENDENTE',
      externalOrderId: json['externalOrderId']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      signalId: json['signalId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetSymbol': assetSymbol,
        'direcao': direcao,
        'quantidade': quantidade,
        if (stopLoss != null) 'stopLoss': stopLoss,
        if (takeProfit != null) 'takeProfit': takeProfit,
        'status': status,
        if (externalOrderId != null) 'externalOrderId': externalOrderId,
        if (errorMessage != null) 'errorMessage': errorMessage,
        'createdAt': createdAt,
        if (signalId != null) 'signalId': signalId,
      };
}

// ── Configuração de Corretora ─────────────────────────────────────────────────

class TradingBrokerConfig {
  final String id;
  final String brokerLogin;
  final String accountId;
  final String ambientePadrao; // "TESTE" | "PRODUCAO"
  final bool ativo;
  final bool hasBrokerPassword;
  final String? updatedAt;

  const TradingBrokerConfig({
    required this.id,
    required this.brokerLogin,
    required this.accountId,
    required this.ambientePadrao,
    required this.ativo,
    this.hasBrokerPassword = false,
    this.updatedAt,
  });

  factory TradingBrokerConfig.fromJson(Map<String, dynamic> json) {
    return TradingBrokerConfig(
      id: json['id']?.toString() ?? '',
      brokerLogin: json['brokerLogin']?.toString() ?? '',
      accountId: json['accountId']?.toString() ?? '',
      ambientePadrao: json['ambientePadrao']?.toString() ?? 'TESTE',
      ativo: json['ativo'] == true || json['ativo'] == 'true',
      hasBrokerPassword: json['hasBrokerPassword'] == true,
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brokerLogin': brokerLogin,
        'accountId': accountId,
        'ambientePadrao': ambientePadrao,
        'ativo': ativo,
        'hasBrokerPassword': hasBrokerPassword,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
