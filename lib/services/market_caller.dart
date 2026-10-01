import 'dart:developer';

import '../models/market_overview_model.dart';
import '../models/network_response.dart';
import '../utils/api_links.dart';
import 'network_caller.dart';

class MarketCaller {
  Future<MarketOverviewData> fetchMarketOverview() async {
    final errors = <String>[];

    for (final endpoint in ApiLinks.marketOverviewCandidates) {
      try {
        final NetworkResponse response = await NetworkCaller().getRequest(endpoint);

        if (response.isSuccess && response.body != null) {
          final market = MarketOverviewResponse.fromJson(response.body).data;
          if (market.hasContent) {
            return market;
          }
          errors.add('Sem dados úteis em $endpoint');
          continue;
        }

        errors.add('Falha em $endpoint (${response.statusCode})');
      } catch (e, stack) {
        log('Erro ao carregar mercado em $endpoint: $e\n$stack');
        errors.add('Erro em $endpoint: $e');
      }
    }

    throw Exception(
      errors.isEmpty
          ? 'Falha ao carregar mercado.'
          : 'Falha ao carregar mercado. ${errors.join(' | ')}',
    );
  }
}
