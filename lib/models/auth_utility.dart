// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/login_model.dart';
import 'empresa_acesso_model.dart';
import 'empresa_model.dart';
import 'parceiro_model.dart';
import 'package:task_manager_flutter/services/permission_service.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

import 'package:task_manager_flutter/utils/app_logger.dart';

// ---------------------------------------------------------------------------
// Utilitário para decodificar e verificar expiração do JWT sem biblioteca extra
// ---------------------------------------------------------------------------
bool _isJwtExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    // Adiciona padding base64 se necessário
    String payload = parts[1];
    final rem = payload.length % 4;
    if (rem != 0) payload += '=' * (4 - rem);
    final decoded = utf8.decode(base64Url.decode(payload));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    final exp = json['exp'];
    if (exp == null) return false; // sem expiração = não expira
    final expDate = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
    return DateTime.now().isAfter(expDate);
  } catch (_) {
    return true; // se não conseguir decodificar, considera expirado
  }
}

class AuthUtility {
  static LoginModel? userInfo;

  /// Empresas de acesso do login (troca de empresa ativa) — populado por
  /// `LoginEmpresaAcessoService.listarMeusAcessos()`.
  static List<EmpresaAcesso> empresasAcesso = [];

  static Map<String, dynamic> _persistableSessionJson(LoginModel model) {
    final json = model.toJson();

    void stripLargeMedia(dynamic value) {
      if (value is Map) {
        for (final key in List<dynamic>.from(value.keys)) {
          final normalized = key.toString().toLowerCase();
          if (normalized == 'foto' ||
              normalized == 'photo' ||
              normalized == 'imagembytes') {
            value.remove(key);
          } else {
            stripLargeMedia(value[key]);
          }
        }
      } else if (value is List) {
        for (final item in value) {
          stripLargeMedia(item);
        }
      }
    }

    stripLargeMedia(json);
    return json;
  }

  static Map<String, dynamic> _minimalSessionJson(LoginModel model) => {
        'status': model.status,
        'token': model.token,
        if (model.login != null)
          'login': {
            'id': model.login!.id,
            'email': model.login!.email,
            'nome': model.login!.nome,
            'tipoLogin': model.login!.tipoLogin?.name,
            'trocarSenhaProximoLogin': model.login!.trocarSenhaProximoLogin,
            if (model.login!.aplicativo != null)
              'aplicativo': model.login!.aplicativo!.toJson(),
            if (model.login!.empresa != null)
              'empresa': model.login!.empresa!.toJson(),
            if (model.login!.parceiro != null)
              'parceiro': model.login!.parceiro!.toJson(),
            if (model.login!.roles != null)
              'roles':
                  model.login!.roles!.map((role) => role.toJson()).toList(),
          },
      };

  /// Considera o usuário autenticado quando há sessão com token OU identidade.
  ///
  /// O backend nem sempre popula `data.id` no login (popula `login`), então
  /// checar apenas `data.id` escondia indevidamente os botões de alerta/logout
  /// do header. Aceita token, `login.id` ou `data.id` como prova de sessão.
  static bool get isLoggedIn {
    final u = userInfo;
    if (u == null) return false;
    final hasToken = u.token != null && u.token!.isNotEmpty;
    final hasLoginId = (u.login?.id ?? 0) > 0;
    final hasDataId = (u.data?.id ?? 0) > 0;
    return hasToken || hasLoginId || hasDataId;
  }

  static Future<void> setUserInfo(LoginModel model) async {
    userInfo = model;
    // Atualizar permissões do usuário no PermissionService (menu dinâmico)
    PermissionService().setPermissoes(model.permissoes);
    SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    try {
      await _sharedPreferences.setString(
        "user_data",
        jsonEncode(_persistableSessionJson(model)),
      );
    } catch (e) {
      L.w('[AuthUtility] falha ao persistir sessao completa; salvando sessao minima: $e');
      try {
        await _sharedPreferences.remove("user_data");
        await _sharedPreferences.setString(
          "user_data",
          jsonEncode(_minimalSessionJson(model)),
        );
      } catch (fallbackError) {
        L.w('[AuthUtility] falha ao persistir sessao minima: $fallbackError');
      }
    }
  }

  /// Atualiza a empresa ativa na sessão corrente (troca de empresa) e
  /// repersiste a sessão. Usado por `LoginEmpresaAcessoService.trocarEmpresaAtiva`.
  static Future<void> atualizarEmpresaAtiva(Empresa empresa) async {
    final model = userInfo;
    if (model == null) return;
    if (model.login != null) {
      model.login!.empresa = empresa;
    }
    if (model.data?.login != null) {
      model.data!.login!.empresa = empresa;
    }
    await setUserInfo(model);
  }

  /// Atualiza de forma atomica o contexto fiscal retornado pela troca de
  /// empresa. O parceiro precisa acompanhar a empresa para evitar requisicoes
  /// e emissoes usando estabelecimentos de tenants diferentes.
  static Future<void> atualizarContextoAtivo(
    Empresa empresa,
    Parceiro? parceiro,
  ) async {
    final model = userInfo;
    if (model == null) return;
    if (model.login != null) {
      model.login!
        ..empresa = empresa
        ..parceiro = parceiro;
    }
    if (model.data?.login != null) {
      model.data!.login!
        ..empresa = empresa
        ..parceiro = parceiro;
    }
    await setUserInfo(model);
  }

  static Future<LoginModel?> getUserInfo() async {
    try {
      SharedPreferences _sharedPreferences =
          await SharedPreferences.getInstance();
      String? value = _sharedPreferences.getString("user_data");

      if (value == null) return null;

      Map<String, dynamic> jsonData = jsonDecode(value);
      return LoginModel.fromJson(jsonData);
    } catch (e) {
      L.d('Erro ao recuperar user_data: $e');
      return null;
    }
  }

  static Future<void> clearUserInfo() async {
    SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    await _sharedPreferences.remove("user_data");
    userInfo = null;
    // Limpar permissões ao fazer logout
    PermissionService().clear();
  }

  /// Retorna o LoginModel do usuário logado (lê de SharedPreferences se necessário).
  static Future<LoginModel?> obterLogin() async {
    if (userInfo != null) return userInfo;
    return getUserInfo();
  }

  /// Headers HTTP com autenticação + tenant.
  static Future<Map<String, String>> obterHeaders() async {
    final token = userInfo?.token;
    if (token == null) await getUserInfo();
    final Map<String, String> headers = {};
    if (userInfo?.token != null) {
      headers['Authorization'] = 'Bearer ${userInfo!.token}';
    }
    return headers;
  }

  static Future<bool> isUserLoggedIn() async {
    SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    bool isLogin = _sharedPreferences.containsKey("user_data");

    if (isLogin) {
      userInfo = await getUserInfo();
      // Se o token armazenado estiver expirado, força novo login
      if (userInfo?.token != null && _isJwtExpired(userInfo!.token!)) {
        L.w('[AuthUtility] token expirado — limpando sessão e forçando re-login');
        await clearUserInfo();
        return false;
      }
      // Sincronizar permissões ao recuperar do cache
      if (userInfo != null) {
        PermissionService().setPermissoes(userInfo!.permissoes);
        if (!ModuloAccess.isLoaded) {
          try {
            await ModuloAccess.load();
          } catch (e) {
            L.w('[AuthUtility] falha ao carregar ModuloAccess: $e');
          }
        }
      }
    }

    return isLogin && userInfo != null;
  }
}
