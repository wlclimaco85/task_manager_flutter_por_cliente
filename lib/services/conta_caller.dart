import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../models/conta_model.dart';
import '../utils/api_links.dart';
import '../utils/utils.dart';

class ContaApi {
  /// Retorna o token no momento da chamada (nao em nivel de arquivo)
  /// para garantir que o token pos-login seja sempre usado.
  String? get _token => AuthUtility.userInfo?.token;

  Map<String, String> _companyQuery() {
    final empresaId = pegarEmpresaLogada() ?? 0;
    final parceiroId = pegarParceiroLogada();
    return {
      'empresaId': empresaId.toString(),
      if (parceiroId != null) 'parceiroId': parceiroId.toString(),
    };
  }

  Future<List<ContaBancariaModel>> listarSaldos() async {
    final uri = Uri.parse(ApiLinks.financeFluxoDiarioSaldo)
        .replace(queryParameters: _companyQuery());
    final currentToken = _token;
    final headers = <String, String>{'Accept': 'application/json'};
    if (currentToken != null && currentToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $currentToken';
    }
    final r = await http.get(uri, headers: headers);
    if (r.statusCode == 204) return [];
    if (r.statusCode != 200) throw Exception('Saldos HTTP ${r.statusCode}');
    final arr = jsonDecode(r.body) as List;
    return arr
        .map((e) => ContaBancariaModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ContaSaldoDia>> evolucao({
    required int contaId,
    int days = 30,
  }) async {
    final uri = Uri.parse(ApiLinks.financeFluxoEvolucao(contaId)).replace(
      queryParameters: {
        ..._companyQuery(),
        'days': days.toString(),
      },
    );
    final currentToken = _token;
    final headers2 = <String, String>{'Accept': 'application/json'};
    if (currentToken != null && currentToken.isNotEmpty) {
      headers2['Authorization'] = 'Bearer $currentToken';
    }
    final r = await http.get(uri, headers: headers2);
    if (r.statusCode == 204) return [];
    if (r.statusCode != 200) throw Exception('Evolução HTTP ${r.statusCode}');
    final arr = jsonDecode(r.body) as List;
    return arr
        .map((e) => ContaSaldoDia.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
  }

  Future<ContaExtratoOperacional> extratoOperacional({
    required int contaId,
    required DateTime dataInicio,
    required DateTime dataFim,
    String? status,
    int? categoriaFinanceiraId,
    String visao = 'CAIXA',
  }) async {
    final uri = Uri.parse(ApiLinks.financeExtratoOperacional).replace(
      queryParameters: {
        ..._companyQuery(),
        'contaId': contaId.toString(),
        'dataInicio': _formatDate(dataInicio),
        'dataFim': _formatDate(dataFim),
        'visao': visao,
        if (status != null && status.trim().isNotEmpty) 'status': status,
        if (categoriaFinanceiraId != null)
          'categoriaFinanceiraId': categoriaFinanceiraId.toString(),
      },
    );
    final currentToken3 = _token;
    final headers3 = <String, String>{'Accept': 'application/json'};
    if (currentToken3 != null && currentToken3.isNotEmpty) {
      headers3['Authorization'] = 'Bearer $currentToken3';
    }
    final r = await http.get(uri, headers: headers3);
    if (r.statusCode == 204) {
      return ContaExtratoOperacional.empty(
        visao: visao,
        contaId: contaId,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
    }
    if (r.statusCode != 200) {
      throw Exception('Extrato operacional HTTP ${r.statusCode}');
    }
    return ContaExtratoOperacional.fromJson(
      Map<String, dynamic>.from(jsonDecode(r.body)),
    );
  }

  Future<Uri> extratoPdfLink({
    required int contaId,
    required DateTime de,
    required DateTime ate,
  }) async {
    final uri = Uri.parse(ApiLinks.financeFluxoDiarioPdf).replace(
      queryParameters: {
        ..._companyQuery(),
        'contaId': contaId.toString(),
        'de': de.toIso8601String().substring(0, 10),
        'ate': ate.toIso8601String().substring(0, 10),
      },
    );
    return uri;
  }

  String _formatDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}
