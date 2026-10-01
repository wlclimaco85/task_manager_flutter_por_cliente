import 'dart:convert';
import '../models/auth_utility.dart';
import 'package:http/http.dart' as http;
import '../services/session_expired_handler.dart';

/// Contexto de tenant do usuário logado.
/// Injeta empresa, parceiro e userId em TODAS as chamadas HTTP.
class TenantContext {
  TenantContext._();

  // ── Leitura dos dados do usuário logado ──────────────────────────────────
  // Tenta login direto primeiro, depois data.login como fallback
  static int? get empresaId =>
      AuthUtility.userInfo?.login?.empresa?.id ??
      AuthUtility.userInfo?.data?.login?.empresa?.id;

  static int? get parceiroId =>
      AuthUtility.userInfo?.login?.parceiro?.id ??
      AuthUtility.userInfo?.data?.login?.parceiro?.id;

  static int? get aplicativoId =>
      AuthUtility.userInfo?.login?.aplicativo?.id ??
      AuthUtility.userInfo?.data?.login?.aplicativo?.id;

  static int? get userId =>
      AuthUtility.userInfo?.login?.id ??
      AuthUtility.userInfo?.data?.login?.id ??
      AuthUtility.userInfo?.data?.id;

  static bool get hasEmpresa => empresaId != null;
  static bool get hasParceiro => parceiroId != null;
  static bool get hasUser => userId != null;
  static bool get isMaster =>
      AuthUtility.userInfo?.login?.tipoLogin?.name == 'MASTER' ||
      AuthUtility.userInfo?.data?.login?.tipoLogin?.name == 'MASTER';

  /// `true` se o email do login corresponde ao dono do sistema.
  /// O dono (wlclimaco@gmail.com) enxerga todas as empresas.
  static bool get isAdminEmail {
    final email = AuthUtility.userInfo?.login?.email ??
        AuthUtility.userInfo?.data?.email;
    return email != null && email.toLowerCase() == 'wlclimaco@gmail.com';
  }

  /// `true` se o usuário é admin (MASTER ou dono do sistema por email).
  static bool get isAdmin => isMaster || isAdminEmail;

  static bool _flag(String? value) {
    if (value == null) return false;
    final normalized = value.toLowerCase().trim();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'sim' ||
        normalized == 'yes';
  }

  // ── Headers ──────────────────────────────────────────────────────────────
  static Map<String, String> get headers {
    final token = AuthUtility.userInfo?.token;
    final tenantId = empresaId?.toString();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      if (tenantId != null) 'X-Tenant-ID': tenantId,
      'Accept-Encoding': 'gzip',
    };
  }

  static Map<String, String> get jsonHeaders {
    final token = AuthUtility.userInfo?.token;
    final tenantId = empresaId?.toString();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      if (tenantId != null) 'X-Tenant-ID': tenantId,
      'Content-Type': 'application/json',
    };
  }

  // ── Injeção de tenant na URL ─────────────────────────────────────────────
  /// Injeta empresa, parceiro e userId em TODOS os nomes que os controllers aceitam.
  /// Se não tem nenhum (admin puro) → não filtra.
  static String applyToUrl(String url) {
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);
    final skipEmpresaScope = _flag(params.remove('skipTenantEmpresa')) ||
        _flag(params.remove('semFiltroEmpresa'));
    final skipParceiroScope = _flag(params.remove('skipTenantParceiro')) ||
        _flag(params.remove('semFiltroParceiro'));

    final hasExplicitEmpresaScope = params.containsKey('empId') ||
        params.containsKey('empresaId') ||
        params.containsKey('empresa') ||
        params.containsKey('empresa_id') ||
        params.containsKey('empresaIds') ||
        params.containsKey('empIds');

    if (hasEmpresa && !hasExplicitEmpresaScope && !skipEmpresaScope) {
      params['empId'] = empresaId.toString();
    }

    final hasExplicitParceiroScope = params.containsKey('parceiro') ||
        params.containsKey('parceiroId') ||
        params.containsKey('parcId') ||
        params.containsKey('clienteId');

    // Parceiro/Cliente: mesmo princípio, evita misturar filtro de aba com
    // parceiro do login atual.
    if (hasParceiro && !hasExplicitParceiroScope && !skipParceiroScope) {
      params['parceiro'] = parceiroId.toString();
      params['parceiroId'] = parceiroId.toString();
      params['parcId'] = parceiroId.toString();
      params['clienteId'] = parceiroId.toString();
    }

    // UserId — para controllers que filtram por usuário logado
    if (hasUser) {
      params['userId'] = userId.toString();
      params['userLogadoId'] = userId.toString();
    }

    return uri.replace(queryParameters: params).toString();
  }

  // ── Injeção no body ──────────────────────────────────────────────────────
  static Map<String, dynamic> applyToBody(Map<String, dynamic> body) {
    final result = Map<String, dynamic>.from(body);
    if (hasEmpresa && result['empresa'] == null) {
      result['empresa'] = {'id': empresaId};
    }
    if (hasParceiro && result['parceiro'] == null) {
      result['parceiro'] = {'id': parceiroId};
    }
    if (aplicativoId != null && result['aplicativo'] == null) {
      result['aplicativo'] = {'id': aplicativoId};
    }
    return result;
  }

  // ── Helpers HTTP com tenant automático ──────────────────────────────────

  // Fix (card #467): mesmo mecanismo do NetworkCaller -- 401 em rota
  // autenticada dispara logout automatico + volta para LoginScreen.
  static const _publicRoutePatterns = [
    '/rest/auth/',
    '/api/solicitacao-acesso',
    '/api/public/',
  ];

  static void _handleUnauthorized(http.Response response) {
    if (response.statusCode != 401) return;
    final path = response.request?.url.path ?? '';
    if (_publicRoutePatterns.any((p) => path.contains(p))) return;
    SessionExpiredHandler.handle();
  }

  static Future<http.Response> get(String url) async {
    final response = await http.get(Uri.parse(applyToUrl(url)), headers: headers);
    _handleUnauthorized(response);
    return response;
  }

  static Future<http.Response> put(String url, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse(applyToUrl(url)),
      headers: jsonHeaders,
      body: jsonEncode(applyToBody(body)),
    );
    _handleUnauthorized(response);
    return response;
  }

  static Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(applyToUrl(url)),
      headers: jsonHeaders,
      body: jsonEncode(applyToBody(body)),
    );
    _handleUnauthorized(response);
    return response;
  }

  static Future<http.Response> delete(String url) async {
    final response = await http.delete(
      Uri.parse(applyToUrl(url)),
      headers: jsonHeaders,
    );
    _handleUnauthorized(response);
    return response;
  }

  /// Envia um arquivo via multipart/form-data com headers de autenticação.
  static Future<http.Response> postMultipart(
    String url, {
    required List<int> fileBytes,
    required String fileName,
    required String fileField,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(applyToUrl(url)));
    final token = AuthUtility.userInfo?.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    // Força charset UTF-8 para que o Spring interprete os campos corretamente
    request.headers['Accept-Charset'] = 'utf-8';
    if (fields != null) request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes(
      fileField,
      fileBytes,
      filename: fileName,
    ));
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ── Debug ────────────────────────────────────────────────────────────────
  static String get debugInfo =>
      'empresaId=$empresaId | parceiroId=$parceiroId | userId=$userId | admin=$isAdmin';
}
