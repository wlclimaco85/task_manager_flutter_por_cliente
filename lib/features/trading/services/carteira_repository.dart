import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../models/carteira_models.dart';

class CarteiraRepository {
  Future<CarteiraResumo> fetchCarteira() async {
    final url = TenantContext.applyToUrl(ApiLinks.tradingCarteira);
    final resp = await http.get(Uri.parse(url), headers: TenantContext.headers);
    if (resp.statusCode != 200) {
      throw Exception(_extractError(resp, 'Erro em /api/trading/carteira'));
    }
    return CarteiraResumo.fromJson(json.decode(resp.body));
  }

  Future<List<OperacaoAcao>> fetchOperacoes() async {
    final url = TenantContext.applyToUrl(ApiLinks.tradingCarteiraOperacoes);
    final resp = await http.get(Uri.parse(url), headers: TenantContext.headers);
    if (resp.statusCode != 200) {
      throw Exception(
          _extractError(resp, 'Erro em /api/trading/carteira/operacoes'));
    }
    final body = json.decode(resp.body);
    final list = body is List ? body : (body['data'] ?? []);
    return (list as List).map((e) => OperacaoAcao.fromJson(e)).toList();
  }

  Future<List<CorretoraInvestimento>> fetchCorretoras() async {
    final url = TenantContext.applyToUrl(ApiLinks.tradingCarteiraCorretoras);
    final resp = await http.get(Uri.parse(url), headers: TenantContext.headers);
    if (resp.statusCode != 200) {
      throw Exception(_extractError(resp, 'Erro ao buscar corretoras'));
    }
    final body = json.decode(resp.body);
    final list = body is List ? body : (body['data'] ?? []);
    return (list as List)
        .map((e) => CorretoraInvestimento.fromJson(e))
        .toList();
  }

  Future<OperacaoAcao> adicionarOperacao(Map<String, dynamic> data) async {
    final url =
        TenantContext.applyToUrl('${ApiLinks.tradingCarteira}/operacao');
    final resp = await http.post(
      Uri.parse(url),
      headers: {...TenantContext.headers, 'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(_extractError(resp, 'Erro ao adicionar operacao'));
    }
    return OperacaoAcao.fromJson(json.decode(resp.body));
  }

  Future<CorretoraInvestimento> salvarCorretora({
    required String nome,
    required double saldoInicial,
    String? observacao,
  }) async {
    final url = TenantContext.applyToUrl(ApiLinks.tradingCarteiraCorretoras);
    final resp = await http.post(
      Uri.parse(url),
      headers: {...TenantContext.headers, 'Content-Type': 'application/json'},
      body: json.encode({
        'nome': nome,
        'saldoInicial': saldoInicial,
        if (observacao != null && observacao.isNotEmpty)
          'observacao': observacao,
      }),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(_extractError(resp, 'Erro ao salvar corretora'));
    }
    return CorretoraInvestimento.fromJson(json.decode(resp.body));
  }

  Future<CorretoraInvestimento> movimentarCorretora({
    required int corretoraId,
    required String tipo,
    required double valor,
    String? descricao,
  }) async {
    final url =
        TenantContext.applyToUrl(ApiLinks.tradingCarteiraCorretoraMovimento);
    final resp = await http.post(
      Uri.parse(url),
      headers: {...TenantContext.headers, 'Content-Type': 'application/json'},
      body: json.encode({
        'corretoraId': corretoraId,
        'tipo': tipo,
        'valor': valor,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      }),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(_extractError(resp, 'Erro ao movimentar corretora'));
    }
    return CorretoraInvestimento.fromJson(json.decode(resp.body));
  }

  Future<void> removerOperacao(int id) async {
    final url = TenantContext.applyToUrl(
        ApiLinks.tradingCarteiraOperacao(id.toString()));
    final resp =
        await http.delete(Uri.parse(url), headers: TenantContext.headers);
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw Exception(_extractError(resp, 'Erro ao remover operacao'));
    }
  }

  String _extractError(http.Response resp, String fallback) {
    if (resp.body.isNotEmpty) {
      try {
        final body = json.decode(resp.body);
        if (body is Map) {
          final msg = body['message'] ?? body['error'] ?? body['mensagem'];
          if (msg != null && msg.toString().trim().isNotEmpty) {
            return msg.toString();
          }
        }
      } catch (_) {}
    }
    return '$fallback: ${resp.statusCode}';
  }
}
