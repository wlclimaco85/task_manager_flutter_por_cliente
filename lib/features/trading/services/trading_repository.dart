import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trading_models.dart';

class TradingRepository {
  final String baseUrl;
  final Map<String,String> headers;

  TradingRepository(this.baseUrl, {this.headers = const {}});

  Future<List<TradingSignal>> fetchSignals() async {
    final uri = Uri.parse('$baseUrl/api/trading/signals');
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) throw Exception('Erro HTTP ${resp.statusCode} em /api/trading/signals');
    final body = json.decode(resp.body);
    final list = (body['signals'] ?? body) as List;
    return list.map((e) => TradingSignal.fromJson(e)).toList();
  }

  Future<List<Opportunity>> fetchOpportunities() async {
    final uri = Uri.parse('$baseUrl/api/trading/opportunities');
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) throw Exception('Erro HTTP ${resp.statusCode} em /api/trading/opportunities');
    final body = json.decode(resp.body);
    final list = (body['opportunities'] ?? body) as List;
    return list.map((e) => Opportunity.fromJson(e)).toList();
  }
}
