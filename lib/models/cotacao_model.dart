class Cotacao {
  int? id;
  String? ativo;
  DateTime? dtCotacao;
  double? valor;
  double? variacao;
  double? volume;
  String? moeda;
  String? origem;

  Cotacao({
    this.id,
    this.ativo,
    this.dtCotacao,
    this.valor,
    this.variacao,
    this.volume,
    this.moeda,
    this.origem,
  });

  double? get preco => valor;
  double? get variacaoPercentual => variacao;
  DateTime? get dataColeta => dtCotacao;

  Map<String, dynamic> toJson() {
    return {
      'cotacaoDTO': {
        'id': id,
        'ativo': ativo,
        'dtCotacao': dtCotacao?.toIso8601String(),
        'valor': valor,
        if (variacao != null) 'variacao': variacao,
        if (volume != null) 'volume': volume,
        if (moeda != null) 'moeda': moeda,
        if (origem != null) 'origem': origem,
      },
    };
  }

  Cotacao.fromJson(Map<String, dynamic> json) {
    final source = _unwrapJson(json);

    id = _readInt(source, const ['id', 'cotacaoId']);
    ativo = _readString(source, const [
      'ativo',
      'asset',
      'ticker',
      'symbol',
      'codigo',
      'codigoAtivo',
      'nomeAtivo',
      'instrumento',
      'papel',
    ]);
    dtCotacao = _readDate(source, const [
      'dtCotacao',
      'dataColeta',
      'collectedAt',
      'updatedAt',
      'timestamp',
      'dataHoraColeta',
      'ultimaAtualizacao',
    ]);
    valor = _readDouble(source, const [
      'valor',
      'preco',
      'precoAtual',
      'price',
      'lastPrice',
      'ultimoPreco',
      'close',
    ]);
    variacao = _readDouble(source, const [
      'variacao',
      'variacaoPercentual',
      'changePercent',
      'percentChange',
      'priceChangePercent',
    ]);
    volume = _readDouble(source, const [
      'volume',
      'volumeNegociado',
      'tradedVolume',
      'financialVolume',
    ]);
    moeda = _readString(source, const ['moeda', 'currency']);
    origem = _readString(source, const ['origem', 'source']);
  }

  static List<Cotacao> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .whereType<Map>()
        .map((item) => Cotacao.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Cotacao.fromJson2(Map<String, dynamic> json) : this.fromJson(json);

  static List<Cotacao> fromJsonList2(List<Map<String, dynamic>> jsonList) {
    return jsonList.map(Cotacao.fromJson).toList();
  }
}

class CotacaoModel {
  String? status;
  String? token;
  List<Cotacao>? data;

  CotacaoModel({this.status, this.token, this.data});

  CotacaoModel.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
    token = json['token']?.toString();

    final rawData = json['data'] ?? json;
    final list = _extractQuoteList(rawData);
    data = list.isEmpty ? null : Cotacao.fromJsonList(list);
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'token': token,
      if (data != null)
        'data': {
          'cotacoesDTO': data!.map((item) => item.toJson()['cotacaoDTO']).toList(),
        },
    };
  }
}

Map<String, dynamic> _unwrapJson(Map<String, dynamic> json) {
  for (final key in const ['cotacaoDTO', 'quoteDTO', 'cotacao', 'quote']) {
    final nested = json[key];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
  }
  return json;
}

List<dynamic> _extractQuoteList(dynamic raw) {
  if (raw is List) return raw;
  if (raw is Map<String, dynamic>) {
    for (final key in const [
      'cotacoesDTO',
      'quotesDTO',
      'cotacoes',
      'quotes',
      'items',
      'data',
      'result',
    ]) {
      final value = raw[key];
      if (value is List) return value;
    }
  }
  if (raw is Map) return _extractQuoteList(Map<String, dynamic>.from(raw));
  return const [];
}

String? _readString(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

int? _readInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) continue;
    final parsed = int.tryParse(value.toString().trim());
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _readDate(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    final parsed = _toDateTime(value);
    if (parsed != null) return parsed;
  }
  return null;
}

double? _readDouble(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    final parsed = _toDouble(value);
    if (parsed != null) return parsed;
  }
  return null;
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

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  final normalized = text.contains(',')
      ? text.contains('.')
          ? text.replaceAll('.', '').replaceAll(',', '.')
          : text.replaceAll(',', '.')
      : text;

  return double.tryParse(normalized);
}
