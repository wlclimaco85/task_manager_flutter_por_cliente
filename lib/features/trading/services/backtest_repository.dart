import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/tenant_context.dart';
import '../models/backtest_models.dart';

/// Repositório de backtest — run e listagem de simulações.
///
/// Os headers JWT são obtidos de TenantContext no momento de CADA chamada
/// (getter dinâmico), evitando o problema de headers capturados na
/// construção do widget quando o token ainda pode não estar disponível.
class BacktestRepository {
  final String baseUrl;

  /// Usa TenantContext.jsonHeaders dinamicamente a cada chamada.
  /// O parâmetro [headers] foi mantido para compatibilidade mas NÃO
  /// sobrescreve os headers de autenticação — é mesclado com eles.
  final Map<String, String> _extraHeaders;

  BacktestRepository(this.baseUrl,
      {Map<String, String> headers = const {}})
      : _extraHeaders = headers;

  /// Headers aplicados em cada requisição (dinâmicos).
  Map<String, String> get _headers => {
        ...TenantContext.jsonHeaders,
        ..._extraHeaders,
      };

  Uri _uri(String path) {
    final uri = Uri.parse('$baseUrl$path');
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'empId': (TenantContext.empresaId ?? 1).toString(),
    });
  }

  Future<BacktestRunResponse> runBacktest({
    required String assetSymbol,
    required String strategyName,
    String? ruleParams,
    String? periodStart,
    String? periodEnd,
  }) async {
    final body = {
      'assetSymbol': assetSymbol,
      'strategyName': strategyName,
      if (ruleParams != null && ruleParams.isNotEmpty) 'ruleParams': ruleParams,
      if (periodStart != null && periodStart.isNotEmpty)
        'periodStart': periodStart,
      if (periodEnd != null && periodEnd.isNotEmpty) 'periodEnd': periodEnd,
    };
    final uri = _uri('/api/trading/backtest/run');
    final resp = await http.post(
      uri,
      headers: _headers,
      body: json.encode(body),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
          'Erro HTTP ${resp.statusCode} em /api/trading/backtest/run: ${resp.body}');
    }
    return BacktestRunResponse.fromJson(json.decode(resp.body));
  }

  Future<List<BacktestRunResponse>> listRuns() async {
    final uri = _uri('/api/trading/backtest/runs');
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode != 200) {
      throw Exception(
          'Erro HTTP ${resp.statusCode} em /api/trading/backtest/runs: ${resp.body}');
    }
    final list = json.decode(resp.body) as List;
    return list.map((e) => BacktestRunResponse.fromJson(e)).toList();
  }
}
