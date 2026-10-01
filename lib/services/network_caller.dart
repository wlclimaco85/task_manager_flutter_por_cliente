import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../models/network_response.dart';
import '../../mobile/screens/LoginPopup_screens.dart';
import '../../../utils/api_links.dart';
import '../../utils/tenant_helper.dart';
import '../../../models/login_model.dart';
import '../../../utils/app_logger.dart';
import 'session_expired_handler.dart';

class NetworkCaller {
  String _previewResponseBody(String body) {
    if (body.length <= 1200) return body;
    return '${body.substring(0, 1200)}... [truncated ${body.length} chars]';
  }

  // Fix (card #467): dispara logout automatico + volta para LoginScreen em
  // qualquer 401 de rota autenticada. Exclui rotas publicas (login,
  // solicitacao de acesso, noticias publicas) para nao deslogar quem ainda
  // nem esta logado.
  static const _publicRoutePatterns = [
    '/rest/auth/',
    '/api/solicitacao-acesso',
    '/api/public/',
  ];

  static void _handleUnauthorized(int statusCode, String url) {
    if (statusCode != 401) return;
    final path = Uri.tryParse(url)?.path ?? url;
    if (_publicRoutePatterns.any((p) => path.contains(p))) return;
    SessionExpiredHandler.handle();
  }

  Future<NetworkResponse> getRequest(String url) async {
    try {
      final enrichedUrl = TenantHelper.applyToUrl(url) ?? url;
      final uri = Uri.parse(enrichedUrl);

      AppLogger.i.info(
          '[GET] tenant=${TenantHelper.debugInfo} | url=${uri.toString()}');

      Response response = await get(
        uri,
        headers: {
          if (AuthUtility.userInfo?.token != null)
            'Authorization': 'Bearer ${AuthUtility.userInfo!.token}',
          'Accept-Encoding': 'gzip',
          ...TenantHelper.tenantHeaders,
        },
      );

      final statusMsg =
          '[GET] url : ${uri.toString()} | statusCode: ${response.statusCode}';
      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.i.success(statusMsg);
      } else if (response.statusCode >= 400) {
        AppLogger.i.warn(statusMsg);
      } else {
        AppLogger.i.info(statusMsg);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        SessionExpiredHandler.resetForbiddenCount();
        return NetworkResponse(
          true,
          response.statusCode,
          response.bodyBytes.isNotEmpty
              ? jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true))
              : null,
        );
      }
      if (response.statusCode == 403) {
        SessionExpiredHandler.handleForbidden();
      }
      _handleUnauthorized(response.statusCode, enrichedUrl);
      return NetworkResponse(false, response.statusCode, null);
    } catch (e, st) {
      AppLogger.i.error('[GET] erro: $e', st);
      log(e.toString());
    }
    return NetworkResponse(false, -1, null);
  }

  Future<NetworkResponse> getRequests(String url, BuildContext context) async {
    try {
      final enrichedUrl = TenantHelper.applyToUrl(url) ?? url;
      Uri uri = Uri.parse(enrichedUrl);

      if (AuthUtility.userInfo?.data?.id != 1) {
        Response response = await get(
          uri,
          headers: {
            'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
            ...TenantHelper.tenantHeaders,
          },
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return NetworkResponse(
            true,
            response.statusCode,
            jsonDecode(response.body),
          );
        } else if (response.statusCode == 403) {
          // Mostrar LoginPopup
          final result = await showDialog(
            context: context,
            builder: (BuildContext context) => const LoginPopup(),
          );

          if (result == true) {
            // Tenta novamente após login bem-sucedido
            if (AuthUtility.userInfo?.data?.id != 1) {
              Response response = await get(
                uri,
                headers: {
                  'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
                  ...TenantHelper.tenantHeaders,
                },
              );
              if (response.statusCode >= 200 && response.statusCode < 300) {
                return NetworkResponse(
                  true,
                  response.statusCode,
                  jsonDecode(response.body),
                );
              } else {
                _handleUnauthorized(response.statusCode, enrichedUrl);
                return NetworkResponse(false, response.statusCode, null);
              }
            }
          }
        } else {
          _handleUnauthorized(response.statusCode, enrichedUrl);
          return NetworkResponse(false, response.statusCode, null);
        }
      } else {
        // Mostrar LoginPopup
        final result = await showDialog(
          context: context,
          builder: (BuildContext context) => const LoginPopup(),
        );

        if (result == true) {
          // Tenta novamente após login bem-sucedido
          if (AuthUtility.userInfo?.data?.id != 1) {
            Response response = await get(
              uri,
              headers: {
                'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
                ...TenantHelper.tenantHeaders,
              },
            );
            if (response.statusCode == 200) {
              return NetworkResponse(
                true,
                response.statusCode,
                jsonDecode(response.body),
              );
            } else {
              _handleUnauthorized(response.statusCode, enrichedUrl);
              return NetworkResponse(false, response.statusCode, null);
            }
          }
        }
      }
    } catch (e) {
      log(e.toString());
    }
    return NetworkResponse(false, -1, null);
  }

  Future<void> loginPadrao() async {
    Map<String, dynamic> requestBody = {
      "email": 'wlclimaco@gmail.com',
      "password": '123456',
    };
    final NetworkResponse response = await NetworkCaller().postRequest(
      ApiLinks.login,
      requestBody,
    );

    if (response.isSuccess) {
      LoginModel model = LoginModel.fromJson(response.body!);
      await AuthUtility.setUserInfo(model);
    } else {
      if (response.statusCode == 400) {
        L.d('Senha ou usuário inválido');
      } else {
        L.d('Erro: ${response.statusCode}');
      }
    }
  }

  Future<NetworkResponse> putRequest(String url, dynamic body) async {
    try {
      final enrichedUrl = TenantHelper.applyToUrl(url) ?? url;
      final response = await put(
        Uri.parse(enrichedUrl),
        headers: {
          'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
          ...TenantHelper.tenantHeaders,
          'Accept-Encoding': 'gzip',
          'Content-Type': 'application/json;charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return NetworkResponse(
          true,
          response.statusCode,
          response.bodyBytes.isNotEmpty
              ? jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true))
              : null,
        );
      } else {
        _handleUnauthorized(response.statusCode, enrichedUrl);
        return NetworkResponse(false, response.statusCode, null);
      }
    } catch (e) {
      debugPrint('Error in PUT request: $e');
      return NetworkResponse(false, 500, {'error': 'Network error: $e'});
    }
  }

  Future<NetworkResponse> patchRequest(String url, dynamic body) async {
    try {
      final enrichedUrl = TenantHelper.applyToUrl(url) ?? url;
      final response = await patch(
        Uri.parse(enrichedUrl),
        headers: {
          'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
          ...TenantHelper.tenantHeaders,
          'Accept-Encoding': 'gzip',
          'Content-Type': 'application/json;charset=UTF-8',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseBody = response.bodyBytes.isNotEmpty
            ? jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true))
            : null;
        return NetworkResponse(
          true,
          response.statusCode,
          responseBody,
        );
      } else {
        _handleUnauthorized(response.statusCode, enrichedUrl);
        return NetworkResponse(false, response.statusCode, null);
      }
    } catch (e) {
      debugPrint('Error in PATCH request: $e');
      return NetworkResponse(false, 500, {'error': 'Network error: $e'});
    }
  }

  Future<NetworkResponse> postRequest(
    String url,
    Map<String, dynamic>? body,
  ) async {
    try {
      final user = AuthUtility.userInfo?.login;

      // Não adiciona campos extras para login/auth endpoints.
      // Usa verificação por path específico para evitar falso-positivo
      // em URLs que contenham a palavra 'login' como prefixo de base URL.
      //
      // Fix: uriPath.endsWith('/login') tambem casava com /api/login (CRUD de
      // criacao de Login, tela.createEndpoint), nao so /rest/auth/login (auth
      // real). Isso fazia POST /api/login (criar Login a partir de
      // Empresa/Parceiro>Logins) ser tratado como requisicao de auth: header
      // Authorization era sobrescrito com um valor fixo ('c2Fua2h5YTpzdXA=',
      // resquicio de outro projeto) em vez do Bearer token real, causando 401
      // sempre. /rest/auth/ ja cobre o endpoint real de autenticacao.
      final uri = Uri.tryParse(url);
      final String uriPath = uri?.path ?? '';
      final bool isAuthRequest = uriPath.contains('/rest/auth/') ||
          uriPath.contains('inserirAluno');

      if (!isAuthRequest && body != null) {
        // Usa TenantHelper para injetar empresa/parceiro/aplicativo no body
        final enrichedBody = TenantHelper.applyToBody(body);
        enrichedBody['audit'] ??= {};
        enrichedBody['audit']['empresaId'] = user?.empresa?.id;
        enrichedBody['audit']['appId'] = user?.aplicativo?.id;
        enrichedBody['audit']['userLogadoId'] = user?.id;
        if (user?.parceiro?.id != null) {
          enrichedBody['audit']['parceiroId'] = user!.parceiro!.id;
        }
        body = enrichedBody;
      }

      // Injeta tenant params na URL também (para controllers que lêem da query)
      final enrichedUrl =
          isAuthRequest ? url : TenantHelper.applyToUrl(url) ?? url;

      AppLogger.i.info('📤 [POST] url=$enrichedUrl | body=${jsonEncode(body)}');

      final token = AuthUtility.userInfo?.token;
      if (!isAuthRequest && (token == null || token.isEmpty)) {
        AppLogger.i.warn(
            '[POST] AVISO: token ausente para requisição protegida. url=$enrichedUrl');
      }
      final Map<String, String> headers = {
        'Content-Type': 'application/json;charset=UTF-8',
        ...TenantHelper.tenantHeaders,
      };
      if (isAuthRequest) {
        headers['Authorization'] = 'c2Fua2h5YTpzdXA=';
      } else if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      Response response = await post(
        Uri.parse(enrichedUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      AppLogger.i.info(
          '📥 [POST] status=${response.statusCode} | body=${_previewResponseBody(response.body)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return NetworkResponse(
          true,
          response.statusCode,
          jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true)),
        );
      } else {
        if (!isAuthRequest) _handleUnauthorized(response.statusCode, enrichedUrl);
        return NetworkResponse(false, response.statusCode, null);
      }
    } catch (e, stack) {
      log('💥 [POST] Erro: $e\n$stack');
    }
    return NetworkResponse(false, -1, null);
  }

  Future<NetworkResponse> deleteRequest(
    String url, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      // Injeta tenant params via TenantHelper
      final enrichedUrl = TenantHelper.applyToUrl(url) ?? url;
      Uri uri = Uri.parse(enrichedUrl);

      // Adiciona queryParams extras se fornecidos
      if (queryParams != null && queryParams.isNotEmpty) {
        final merged = Map<String, String>.from(uri.queryParameters);
        queryParams.forEach((k, v) {
          if (v != null) merged[k] = v.toString();
        });
        uri = uri.replace(queryParameters: merged);
      }

      final response = await delete(
        uri,
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
          ...TenantHelper.tenantHeaders,
        },
      );

      AppLogger.i.info('🗑️ [DELETE] $uri | status=${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        final body = response.bodyBytes.isNotEmpty
            ? jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true))
            : null;
        return NetworkResponse(true, response.statusCode, body);
      } else {
        _handleUnauthorized(response.statusCode, enrichedUrl);
        return NetworkResponse(false, response.statusCode, null);
      }
    } catch (e) {
      log(e.toString());
      return NetworkResponse(false, -1, null);
    }
  }
}
