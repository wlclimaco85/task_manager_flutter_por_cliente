import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class SolicitacaoAcessoItem {
  final int id;
  final String nome;
  final String email;
  final String cpfCnpj;
  final String cpfSolicitante;
  final String status;
  final int? parceiroIdResolvido;
  final String? parceiroNomeResolvido;
  final int? empresaIdResolvida;
  final String? empresaNomeResolvida;
  final DateTime? dataCriacao;

  SolicitacaoAcessoItem({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpfCnpj,
    required this.cpfSolicitante,
    required this.status,
    this.parceiroIdResolvido,
    this.parceiroNomeResolvido,
    this.empresaIdResolvida,
    this.empresaNomeResolvida,
    this.dataCriacao,
  });

  bool get destinoFilaEscritorio =>
      parceiroIdResolvido == null && empresaIdResolvida == null;

  String get destinoNome {
    final parceiro = parceiroNomeResolvido?.trim();
    if (parceiro != null && parceiro.isNotEmpty) return parceiro;
    final empresa = empresaNomeResolvida?.trim();
    if (empresa != null && empresa.isNotEmpty) return empresa;
    return 'Fila do escritorio';
  }

  factory SolicitacaoAcessoItem.fromJson(Map<String, dynamic> json) {
    return SolicitacaoAcessoItem(
      id: json['id'] as int,
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cpfCnpj: json['cpfCnpj']?.toString() ?? '',
      cpfSolicitante: json['cpfSolicitante']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDENTE',
      parceiroIdResolvido: json['parceiroIdResolvido'] as int?,
      parceiroNomeResolvido: json['parceiroNomeResolvido']?.toString(),
      empresaIdResolvida: json['empresaIdResolvida'] as int?,
      empresaNomeResolvida: json['empresaNomeResolvida']?.toString(),
      dataCriacao: DateTime.tryParse(json['dataCriacao']?.toString() ?? ''),
    );
  }
}

class SolicitacaoAcessoSetor {
  final int id;
  final String descricao;

  const SolicitacaoAcessoSetor({required this.id, required this.descricao});

  factory SolicitacaoAcessoSetor.fromJson(Map<String, dynamic> json) {
    return SolicitacaoAcessoSetor(
      id: json['id'] as int,
      descricao: json['descricao']?.toString() ?? '',
    );
  }
}

/// Resultado de uma acao (aprovar/rejeitar). [conflito] = true quando o
/// backend respondeu 404 (outra pessoa ja decidiu a solicitacao antes).
class SolicitacaoAcessoActionResult {
  final bool sucesso;
  final String? mensagemErro;
  final bool conflito;

  const SolicitacaoAcessoActionResult.ok()
      : sucesso = true,
        mensagemErro = null,
        conflito = false;

  const SolicitacaoAcessoActionResult.erro(this.mensagemErro,
      {this.conflito = false})
      : sucesso = false;
}

class SolicitacaoAcessoCaller {
  static Map<String, String> get _authHeaders {
    final headers = Map<String, String>.from(TenantContext.headers);
    final token = AuthUtility.userInfo?.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Retorna null quando a requisicao falhou (rede/parsing) — distinto de
  /// lista vazia (fila realmente sem pendencias).
  static Future<List<SolicitacaoAcessoItem>?> listarPendentes() async {
    try {
      final url = TenantContext.applyToUrl(ApiLinks.solicitacaoAcessoPendentes);
      final response = await http.get(Uri.parse(url), headers: _authHeaders);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is! List) return null;
      return data
          .whereType<Map>()
          .map((e) =>
              SolicitacaoAcessoItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<List<SolicitacaoAcessoSetor>?> listarSetores() async {
    try {
      final url =
          TenantContext.applyToUrl('${ApiLinks.allSetores}?tamanho=200');
      final response = await http.get(Uri.parse(url), headers: _authHeaders);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'];
      final dados = data is Map ? data['dados'] : null;
      if (dados is! List) return null;
      return dados
          .whereType<Map>()
          .map((e) =>
              SolicitacaoAcessoSetor.fromJson(Map<String, dynamic>.from(e)))
          .where((setor) => setor.descricao.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<SolicitacaoAcessoActionResult> aprovar(
      int id, List<int> setorIds) async {
    return _executarAcao(
      Uri.parse(
          TenantContext.applyToUrl(ApiLinks.solicitacaoAcessoAprovar(id))),
      acaoLabel: 'aprovar',
      body: {'setorIds': setorIds},
    );
  }

  static Future<SolicitacaoAcessoActionResult> rejeitar(int id) async {
    return _executarAcao(
      Uri.parse(
          TenantContext.applyToUrl(ApiLinks.solicitacaoAcessoRejeitar(id))),
      acaoLabel: 'rejeitar',
    );
  }

  static Future<SolicitacaoAcessoActionResult> _executarAcao(
    Uri url, {
    required String acaoLabel,
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = Map<String, String>.from(_authHeaders);
      if (body != null) headers['Content-Type'] = 'application/json';
      final response = await http.post(
        url,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      );
      if (response.statusCode == 200) {
        return const SolicitacaoAcessoActionResult.ok();
      }
      // 404: SolicitacaoAcessoController retorna NOT_FOUND quando o id nao
      // existe mais como PENDENTE — sinal de que outra pessoa ja decidiu.
      if (response.statusCode == 404) {
        return const SolicitacaoAcessoActionResult.erro(
          'Esta solicitação já foi processada por outro usuário.',
          conflito: true,
        );
      }
      return SolicitacaoAcessoActionResult.erro(
        _extrairMensagemErro(response.body) ??
            'Erro ao $acaoLabel solicitação. Tente novamente.',
      );
    } catch (_) {
      return SolicitacaoAcessoActionResult.erro(
        'Erro de conexão ao $acaoLabel solicitação.',
      );
    }
  }

  static String? _extrairMensagemErro(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg =
          (json['response'] as Map<String, dynamic>?)?['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    } catch (_) {}
    return null;
  }
}
