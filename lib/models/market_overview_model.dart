import 'cotacao_model.dart';
import 'order_model.dart';

class MarketOverviewResponse {
  final String? status;
  final String? token;
  final MarketOverviewData data;

  MarketOverviewResponse({this.status, this.token, required this.data});

  factory MarketOverviewResponse.fromJson(dynamic json) {
    final map = _asMap(json);
    final rawData = _firstValue(map, const [
      'data',
      'mercado',
      'market',
      'payload',
      'resultado',
    ]);

    return MarketOverviewResponse(
      status: map['status']?.toString(),
      token: map['token']?.toString(),
      data: MarketOverviewData.fromJson(rawData ?? json),
    );
  }
}

class MarketOverviewData {
  final List<MarketOverviewMetric> summaryMetrics;
  final List<Cotacao> latestQuotes;
  final List<OrderItem> openOrders;
  final List<OrderItem> monitoredOrders;
  final DateTime? updatedAt;
  final Map<String, dynamic> rawSummary;

  MarketOverviewData({
    required this.summaryMetrics,
    required this.latestQuotes,
    required this.openOrders,
    required this.monitoredOrders,
    required this.updatedAt,
    required this.rawSummary,
  });

  factory MarketOverviewData.fromJson(dynamic raw) {
    if (raw is List) {
      return MarketOverviewData(
        summaryMetrics: const [],
        latestQuotes: _parseCotacoes(raw),
        openOrders: const [],
        monitoredOrders: const [],
        updatedAt: null,
        rawSummary: const {},
      );
    }

    final map = _asMap(raw);
    final summaryRaw = _firstValue(map, const [
          'summary',
          'resumo',
          'marketSummary',
          'mercadoResumo',
          'summaryCards',
          'cards',
          'indicadores',
        ]) ??
        const <String, dynamic>{};

    final summaryMetrics = _parseSummaryMetrics(summaryRaw);

    return MarketOverviewData(
      summaryMetrics: summaryMetrics,
      latestQuotes: _parseCotacoes(
        _firstValue(map, const [
              'latestQuotes',
              'ultimasCotacoes',
              'cotacoes',
              'quotes',
              'quotesDTO',
              'cotacoesDTO',
              'marketData',
              'collectedQuotes',
              'ativosMonitorados',
              'assets',
              'assetSnapshots',
            ]) ??
            map,
      ),
      openOrders: _parseOrders(
        _firstValue(map, const [
              'openOrders',
              'ordensAbertas',
              'orders',
              'orderDTOs',
              'ordensDTO',
            ]) ??
            map,
      ),
      monitoredOrders: _parseOrders(
        _firstValue(map, const [
              'monitoredOrders',
              'ordensMonitoradas',
              'trackedOrders',
              'ordensAcompanhadas',
              'ordersMonitored',
              'watchlistOrders',
            ]) ??
            map,
      ),
      updatedAt: _firstDate(map, const [
        'updatedAt',
        'lastUpdated',
        'dtAtualizacao',
        'atualizadoEm',
        'dataAtualizacao',
        'collectedAt',
      ]),
      rawSummary: _asMap(summaryRaw),
    );
  }

  bool get hasContent =>
      displaySummaryMetrics.isNotEmpty ||
      latestQuotes.isNotEmpty ||
      openOrders.isNotEmpty ||
      monitoredOrders.isNotEmpty;

  List<MarketOverviewMetric> get displaySummaryMetrics {
    if (summaryMetrics.isNotEmpty) {
      return summaryMetrics;
    }

    final monitoredAssetsCount = monitoredAssets.length;
    final derived = <MarketOverviewMetric>[
      MarketOverviewMetric(
        label: 'Ativos monitorados',
        value: monitoredAssetsCount.toString(),
        subtitle: 'Últimos preços consolidados',
      ),
      MarketOverviewMetric(
        label: 'Cotações',
        value: latestQuotes.length.toString(),
        subtitle: 'Últimas capturas',
      ),
      MarketOverviewMetric(
        label: 'Ordens abertas',
        value: openOrders.length.toString(),
        subtitle: 'Em acompanhamento',
      ),
      MarketOverviewMetric(
        label: 'Ordens monitoradas',
        value: monitoredOrders.length.toString(),
        subtitle: 'Em observação',
      ),
    ];

    if (updatedAt != null) {
      derived.add(
        MarketOverviewMetric(
          label: 'Atualização',
          value: _formatDateTime(updatedAt!),
          subtitle: 'Última sincronização',
        ),
      );
    }

    return derived;
  }

  List<MarketAssetSnapshot> get monitoredAssets {
    final assets = <String, _MarketAssetAccumulator>{};

    void ensureAsset(String? rawName) {
      final name = _normalizeAssetName(rawName);
      if (name == null) return;
      assets.putIfAbsent(name, () => _MarketAssetAccumulator(ativo: name));
    }

    for (final quote in latestQuotes) {
      final name = _normalizeAssetName(quote.ativo);
      if (name == null) continue;
      final asset = assets.putIfAbsent(name, () => _MarketAssetAccumulator(ativo: name));
      asset.applyQuote(quote);
    }

    for (final order in openOrders) {
      ensureAsset(order.acao);
      final name = _normalizeAssetName(order.acao);
      if (name == null) continue;
      assets[name]!.applyOrder(order, isMonitored: false);
    }

    for (final order in monitoredOrders) {
      ensureAsset(order.acao);
      final name = _normalizeAssetName(order.acao);
      if (name == null) continue;
      assets[name]!.applyOrder(order, isMonitored: true);
    }

    final snapshots = assets.values
        .map((asset) => asset.build())
        .where((asset) => asset.hasAnyData)
        .toList();

    snapshots.sort((a, b) {
      final dateA = a.dataColeta;
      final dateB = b.dataColeta;
      if (dateA != null && dateB != null) {
        final compareDate = dateB.compareTo(dateA);
        if (compareDate != 0) return compareDate;
      } else if (dateA != null) {
        return -1;
      } else if (dateB != null) {
        return 1;
      }

      final monitoredCompare =
          (b.isMonitored ? 1 : 0) - (a.isMonitored ? 1 : 0);
      if (monitoredCompare != 0) return monitoredCompare;

      return a.ativo.compareTo(b.ativo);
    });

    return snapshots;
  }
}

class MarketOverviewMetric {
  final String label;
  final String value;
  final String? subtitle;

  const MarketOverviewMetric({
    required this.label,
    required this.value,
    this.subtitle,
  });

  factory MarketOverviewMetric.fromJson(Map<String, dynamic> json) {
    final label = _stringFrom(json, const ['label', 'title', 'name', 'descricao']);
    final value = _stringFrom(json, const ['value', 'amount', 'count', 'texto']);
    final subtitle =
        _stringFromOrNull(json, const ['subtitle', 'hint', 'description', 'detalhe']);

    return MarketOverviewMetric(
      label: label.isEmpty ? 'Indicador' : label,
      value: value.isEmpty ? '—' : value,
      subtitle: subtitle,
    );
  }
}

class MarketAssetSnapshot {
  final String ativo;
  final double? preco;
  final double? variacao;
  final double? volume;
  final DateTime? dataColeta;
  final bool isMonitored;
  final bool hasOpenOrder;
  final int openOrdersCount;
  final int monitoredOrdersCount;
  final String? origem;
  final String? status;

  const MarketAssetSnapshot({
    required this.ativo,
    required this.preco,
    required this.variacao,
    required this.volume,
    required this.dataColeta,
    required this.isMonitored,
    required this.hasOpenOrder,
    required this.openOrdersCount,
    required this.monitoredOrdersCount,
    required this.origem,
    required this.status,
  });

  bool get hasAnyData =>
      preco != null ||
      variacao != null ||
      volume != null ||
      dataColeta != null ||
      hasOpenOrder ||
      isMonitored;

  String get acompanhamentoLabel {
    if (isMonitored && hasOpenOrder) return 'Monitorado e em aberto';
    if (isMonitored) return 'Monitorado';
    if (hasOpenOrder) return 'Em aberto';
    return 'Cotado';
  }
}

class _MarketAssetAccumulator {
  final String ativo;

  double? preco;
  double? variacao;
  double? volume;
  DateTime? dataColeta;
  bool isMonitored = false;
  bool hasOpenOrder = false;
  int openOrdersCount = 0;
  int monitoredOrdersCount = 0;
  String? origem;
  String? status;

  _MarketAssetAccumulator({required this.ativo});

  void applyQuote(Cotacao quote) {
    preco ??= quote.preco ?? quote.valor;
    variacao ??= quote.variacaoPercentual ?? quote.variacao;
    volume ??= quote.volume;
    dataColeta = _pickLatestDate(dataColeta, quote.dataColeta ?? quote.dtCotacao);
    origem ??= quote.origem ?? 'cotação';
  }

  void applyOrder(OrderItem order, {required bool isMonitored}) {
    final orderPrice = order.cotacaoAtual ?? order.valorCompra;
    preco ??= orderPrice;
    if (isMonitored) {
      this.isMonitored = true;
      monitoredOrdersCount += 1;
    } else {
      hasOpenOrder = true;
      openOrdersCount += 1;
    }
    status ??= order.status;
    origem ??= 'ordem';
  }

  MarketAssetSnapshot build() {
    return MarketAssetSnapshot(
      ativo: ativo,
      preco: preco,
      variacao: variacao,
      volume: volume,
      dataColeta: dataColeta,
      isMonitored: isMonitored,
      hasOpenOrder: hasOpenOrder,
      openOrdersCount: openOrdersCount,
      monitoredOrdersCount: monitoredOrdersCount,
      origem: origem,
      status: status,
    );
  }
}

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key) && map[key] != null) {
      return map[key];
    }
  }
  return null;
}

DateTime? _firstDate(Map<String, dynamic> map, List<String> keys) {
  final value = _firstValue(map, keys);
  return _toDateTime(value);
}

String _stringFrom(Map<String, dynamic> map, List<String> keys) {
  final value = _firstValue(map, keys);
  return _formatScalar(value);
}

String? _stringFromOrNull(Map<String, dynamic> map, List<String> keys) {
  final value = _firstValue(map, keys);
  final text = _formatScalar(value);
  return text.isEmpty ? null : text;
}

List<MarketOverviewMetric> _parseSummaryMetrics(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((item) => MarketOverviewMetric.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  final map = _asMap(raw);
  if (map.isEmpty) return const [];

  final nested = _firstValue(map, const ['cards', 'items', 'metrics']);
  if (nested is List) {
    return nested
        .whereType<Map>()
        .map((item) => MarketOverviewMetric.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  final metrics = <MarketOverviewMetric>[];
  map.forEach((key, value) {
    if (value == null) return;
    if (value is Map || value is List) return;
    if (_isInternalSummaryKey(key)) return;

    metrics.add(
      MarketOverviewMetric(
        label: _beautifyLabel(key),
        value: _formatScalar(value),
        subtitle: null,
      ),
    );
  });

  return metrics;
}

List<Cotacao> _parseCotacoes(dynamic raw) {
  final list = _asList(raw);
  return list
      .map(_asMap)
      .map((item) => _unwrapNestedMap(item, const ['cotacaoDTO', 'quoteDTO', 'cotacao', 'quote']))
      .where((item) => item.isNotEmpty)
      .map(Cotacao.fromJson)
      .where((item) => item.ativo != null || item.valor != null || item.preco != null)
      .toList();
}

List<OrderItem> _parseOrders(dynamic raw) {
  final list = _asList(raw);
  return list
      .map(_asMap)
      .map((item) => _unwrapNestedMap(item, const ['orderDTO', 'order', 'ordemDTO', 'ordem']))
      .where((item) => item.isNotEmpty)
      .map(OrderItem.fromJson)
      .where((item) => item.acao != null || item.cotacaoAtual != null || item.valorCompra != null)
      .toList();
}

List<dynamic> _asList(dynamic raw) {
  if (raw is List) return raw;
  final map = _asMap(raw);
  if (map.isEmpty) return const [];

  final candidates = [
    _firstValue(map, const ['data']),
    _firstValue(map, const ['items']),
    _firstValue(map, const ['list']),
    _firstValue(map, const ['results']),
    _firstValue(map, const ['cotacoesDTO']),
    _firstValue(map, const ['quotesDTO']),
    _firstValue(map, const ['quotes']),
    _firstValue(map, const ['cotacoes']),
    _firstValue(map, const ['orders']),
    _firstValue(map, const ['orderDTOs']),
  ];

  for (final candidate in candidates) {
    if (candidate is List) return candidate;
  }

  return const [];
}

Map<String, dynamic> _unwrapNestedMap(Map<String, dynamic> item, List<String> nestedKeys) {
  for (final key in nestedKeys) {
    final nested = item[key];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
  }
  return item;
}

bool _isInternalSummaryKey(String key) {
  final normalized = key.toLowerCase();
  return normalized.contains('updated') ||
      normalized.contains('update') ||
      normalized.contains('datahora') ||
      normalized.contains('timestamp') ||
      normalized.contains('status') ||
      normalized == 'token' ||
      normalized == 'id';
}

String _beautifyLabel(String raw) {
  final withSpaces = raw
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (match) => ' ${match.group(1)}')
      .trim();
  if (withSpaces.isEmpty) return 'Indicador';
  return withSpaces[0].toUpperCase() + withSpaces.substring(1);
}

String _formatScalar(dynamic value) {
  if (value == null) return '—';
  if (value is bool) return value ? 'Sim' : 'Não';
  if (value is num) {
    if (value is int) return value.toString();
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  }
  final text = value.toString().trim();
  return text.isEmpty ? '—' : text;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {
      return null;
    }
  }
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month ${hour}h$minute';
}

String? _normalizeAssetName(String? raw) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return null;
  return text.toUpperCase();
}

DateTime? _pickLatestDate(DateTime? current, DateTime? candidate) {
  if (candidate == null) return current;
  if (current == null) return candidate;
  return candidate.isAfter(current) ? candidate : current;
}
