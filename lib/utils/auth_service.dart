import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _permissionsKey = 'user_permissions';

  /// 🔑 Retorna o token JWT salvo localmente
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// 💾 Salva o token JWT
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// ❌ Remove o token (logout)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// 📋 Headers para chamadas autenticadas JSON (NetworkCaller)
  Future<Map<String, String>> jsonHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 📦 Headers para uploads multipart (usado em authHeadersProvider)
  Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 🔐 Verifica se o usuário tem uma permissão específica
  Future<bool> hasPermission(String permission) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_permissionsKey);
    if (raw == null) return false;
    return raw.contains(permission);
  }

  /// 🔄 Atualiza a lista de permissões (ex.: após login)
  Future<void> savePermissions(List<String> permissions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_permissionsKey, permissions);
  }
}
