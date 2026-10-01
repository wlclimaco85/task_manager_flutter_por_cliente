import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';
import 'trading_models.dart';

String _extractErrorMessage(http.Response response, String fallback) {
  if (response.body.isNotEmpty) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] ?? decoded['error'] ?? decoded['mensagem'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {}
  }
  return '$fallback: ${response.statusCode}';
}

List<dynamic> _decodeListBody(String body, {List<String> keys = const []}) {
  final decoded = jsonDecode(body);
  final list = _findList(decoded, [
    ...keys,
    'data',
    'dados',
    'content',
    'items',
    'results',
    'sinais',
  ]);
  if (list != null) return list;
  throw const FormatException('Resposta da API não está no formato esperado.');
}

/// Repositório de trading — sinais, oportunidades, watchlist e alertas.
List<dynamic>? _findList(dynamic value, List<String> keys) {
  if (value is List<dynamic>) return value;
  if (value is Map<String, dynamic>) {
    for (final key in keys) {
      final found = _findList(value[key], keys);
      if (found != null) return found;
    }
  }
  return null;
}

class TradingRepository {
  Map<String, String> get headers => TenantContext.jsonHeaders;

  // ── Configuração da Corretora ─────────────────────────────────────────────

  Future<TradingBrokerConfig?> fetchBrokerConfig() async {
    final response = await http.get(
      Uri.parse(ApiLinks.tradingBrokerConfig),
      headers: headers,
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(
          response, 'Erro ao buscar configuração da corretora'));
    }
    return TradingBrokerConfig.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<TradingBrokerConfig> saveBrokerConfig({
    required String brokerLogin,
    required String accountId,
    required String ambientePadrao,
    required bool ativo,
    String? brokerPassword,
  }) async {
    final body = <String, dynamic>{
      'brokerLogin': brokerLogin,
      'accountId': int.parse(accountId),
      'ambientePadrao': ambientePadrao,
      'ativo': ativo,
      if (brokerPassword != null && brokerPassword.isNotEmpty)
        'brokerPassword': brokerPassword,
    };

    final response = await http.put(
      Uri.parse(ApiLinks.tradingBrokerConfig),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(
          response, 'Erro ao salvar configuração da corretora'));
    }
    return TradingBrokerConfig.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ── Sinais ────────────────────────────────────────────────────────────────

  Future<List<TradingSignal>> fetchSignals() async {
    final response = await http.get(
      Uri.parse(
          TenantContext.applyToUrl('${ApiLinks.baseUrl}/api/trading/signals')),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar sinais: ${response.statusCode}');
    }
    final data =
        _decodeListBody(response.body, keys: const ['signals', 'data']);
    return data
        .map((e) => TradingSignal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Oportunidades ─────────────────────────────────────────────────────────

  Future<List<Opportunity>> fetchOpportunities() async {
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/trading/opportunities')),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar oportunidades: ${response.statusCode}');
    }
    final data =
        _decodeListBody(response.body, keys: const ['opportunities', 'data']);
    return data
        .map((e) => Opportunity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Watchlist ─────────────────────────────────────────────────────────────

  Future<List<TradingSignal>> analyzeWatchlist() async {
    final response = await http.post(
      Uri.parse(
          TenantContext.applyToUrl('${ApiLinks.baseUrl}/api/trading/analyze')),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao analisar watchlist: ${response.statusCode}');
    }
    final data =
        _decodeListBody(response.body, keys: const ['signals', 'data']);
    return data
        .map((e) => TradingSignal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WatchlistItem>> fetchWatchlist() async {
    final response = await http.get(
      Uri.parse(ApiLinks.tradingWatchlist),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar watchlist: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WatchlistItem> addToWatchlist(String symbol, {String? notes}) async {
    final body = <String, dynamic>{'assetSymbol': symbol};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await http.post(
      Uri.parse(ApiLinks.tradingWatchlist),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao adicionar à watchlist: ${response.statusCode}');
    }
    return WatchlistItem.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> removeFromWatchlist(String id) async {
    final response = await http.delete(
      Uri.parse(ApiLinks.tradingWatchlistItem(id)),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao remover da watchlist: ${response.statusCode}');
    }
  }

  // ── Alertas ───────────────────────────────────────────────────────────────

  Future<List<TradingAlerta>> fetchAlertas() async {
    final response = await http.get(
      Uri.parse(ApiLinks.tradingAlertas),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar alertas: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => TradingAlerta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TradingAlerta> createAlerta({
    required String symbol,
    required double priceTarget,
    required String direction,
    String? message,
  }) async {
    final body = <String, dynamic>{
      'assetSymbol': symbol,
      'priceTarget': priceTarget,
      'direction': direction,
      if (message != null && message.isNotEmpty) 'message': message,
    };

    final response = await http.post(
      Uri.parse(ApiLinks.tradingAlertas),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao criar alerta: ${response.statusCode}');
    }
    return TradingAlerta.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> cancelarAlerta(String id) async {
    final response = await http.delete(
      Uri.parse(ApiLinks.tradingAlerta(id)),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao cancelar alerta: ${response.statusCode}');
    }
  }

  // ── Operações Assistidas ──────────────────────────────────────────────────

  Future<List<OperacaoAssistida>> fetchOperacoes() async {
    final response = await http.get(
      Uri.parse(ApiLinks.tradingOperacoes),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar operações: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => OperacaoAssistida.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OperacaoAssistida> enviarOperacao({
    required String assetSymbol,
    required String direcao,
    required double quantidade,
    required int accountId,
    double? stopLoss,
    double? takeProfit,
    String ambiente = 'TESTE',
    String? signalId,
    String? brokerLogin,
    String? brokerPassword,
  }) async {
    final body = <String, dynamic>{
      'assetSymbol': assetSymbol,
      'direcao': direcao,
      'quantidade': quantidade,
      'accountId': accountId,
      'ambiente': ambiente,
      if (stopLoss != null) 'stopLoss': stopLoss,
      if (takeProfit != null) 'takeProfit': takeProfit,
      if (signalId != null) 'signalId': signalId,
      if (brokerLogin != null && brokerLogin.isNotEmpty)
        'brokerLogin': brokerLogin,
      if (brokerPassword != null && brokerPassword.isNotEmpty)
        'brokerPassword': brokerPassword,
    };

    final response = await http.post(
      Uri.parse(ApiLinks.tradingOperacoes),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          _extractErrorMessage(response, 'Erro ao enviar operação'));
    }
    return OperacaoAssistida.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<OperacaoAssistida> consultarStatusOperacao(String id) async {
    final response = await http.get(
      Uri.parse(ApiLinks.tradingOperacaoStatus(id)),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Erro ao consultar status da operação: ${response.statusCode}');
    }
    return OperacaoAssistida.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> cancelarOperacao(String id) async {
    final response = await http.delete(
      Uri.parse(ApiLinks.tradingOperacao(id)),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao cancelar operação: ${response.statusCode}');
    }
  }
}
