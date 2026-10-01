// lib/dashboard/api_client.dart (atualizado)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/auth_utility.dart';
import '../models/dashboard_model.dart';
import '../utils/api_links.dart';
import '../utils/utils.dart';

class DashboardApiClient {
  DashboardApiClient();

  final token = AuthUtility.userInfo?.token;
  final int empresaId = pegarEmpresaLogada() ?? 0;
  final int? parceiroId = pegarParceiroLogada();

  Map<String, String> _qp([Map<String, String>? extra]) {
    final m = {
      'empresaId': empresaId.toString(),
      if (parceiroId != null) 'parceiroId': parceiroId.toString(),
    };
    if (extra != null) m.addAll(extra);
    return m;
  }

  Future<List<FinancePoint>> fetchFinanceSeries({int months = 6}) async {
    final uri = Uri.parse(ApiLinks.getFinance)
        .replace(queryParameters: _qp({'months': '$months'}));

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    debugPrint('[fetchFinanceSeries] status=${res.statusCode}');
    debugPrint('[fetchFinanceSeries] body=${res.body}');

    if (res.statusCode == 204) return [];
    if (res.statusCode != 200) {
      throw Exception('Finance series error ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw StateError(
        '[fetchFinanceSeries] payload não é uma lista: ${decoded.runtimeType}',
      );
    }

    return decoded.map((e) {
      if (e is! Map) {
        debugPrint('[fetchFinanceSeries] item não é Map: ${e.runtimeType} -> $e');
        return FinancePoint('', 0, 0);
      }
      return FinancePoint.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }

  Future<List<FinanceFluxoPoint>> fetchFinanceFluxoDiario({
    int daysBack = 10,
    int daysForward = 30,
  }) async {
    final uri = Uri.parse(ApiLinks.financeFluxoDiario).replace(
      queryParameters: _qp({
        'daysBack': '$daysBack',
        'daysForward': '$daysForward',
      }),
    );

    final res = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    debugPrint('[fetchFinanceFluxoDiario] status=${res.statusCode}');
    debugPrint('[fetchFinanceFluxoDiario] body=${res.body}');

    if (res.statusCode == 204) return [];
    if (res.statusCode != 200) {
      throw Exception('Finance fluxo diário error ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw StateError(
        '[fetchFinanceFluxoDiario] payload não é uma lista: ${decoded.runtimeType}',
      );
    }

    return decoded.map((e) {
      if (e is! Map) {
        debugPrint(
          '[fetchFinanceFluxoDiario] item não é Map: ${e.runtimeType} -> $e',
        );
        return FinanceFluxoPoint(DateTime.now(), 0, 0);
      }
      return FinanceFluxoPoint.fromJson(Map<String, dynamic>.from(e));
    }).toList()
      ..sort((a, b) => a.day.compareTo(b.day));
  }

  Future<List<ChatsDailyPoint>> fetchChatsDaily({int days = 7}) async {
    final res = await http.get(
      Uri.parse(ApiLinks.chatDailys)
          .replace(queryParameters: _qp({'days': '$days'})),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    debugPrint('[fetchChatsDaily] status=${res.statusCode}');
    debugPrint('[fetchChatsDaily] body=${res.body}');

    if (res.statusCode == 204) return [];
    if (res.statusCode != 200) {
      throw Exception('Chats daily error ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw StateError(
        '[fetchChatsDaily] payload não é lista: ${decoded.runtimeType}',
      );
    }

    return decoded.map((e) {
      if (e is! Map) {
        debugPrint('[fetchChatsDaily] item não é Map: ${e.runtimeType} -> $e');
        return ChatsDailyPoint(DateTime.now(), 0);
      }
      return ChatsDailyPoint.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }
}
