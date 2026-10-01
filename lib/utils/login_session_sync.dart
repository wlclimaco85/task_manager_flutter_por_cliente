import '../models/auth_utility.dart';
import '../models/empresa_model.dart';
import '../models/parceiro_model.dart';

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _asString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.trim().isEmpty) return null;
  return text;
}

/// Mantem o menu/header coerentes quando o usuario salva o proprio cadastro.
Future<void> sincronizarSessaoLoginAtualAposSalvar(
  Map<String, dynamic> formData,
  Map<String, dynamic>? item,
) async {
  final sessao = AuthUtility.userInfo;
  final loginAtual = sessao?.login ?? sessao?.data?.login;
  final idSalvo = _asInt(formData['id'] ?? item?['id']);

  if (sessao == null || loginAtual == null || idSalvo != loginAtual.id) {
    return;
  }

  final loginTopLevel = sessao.login;
  final loginData = sessao.data?.login;

  final foto = _asString(formData['foto']);
  if (foto != null) {
    if (loginTopLevel != null) {
      loginTopLevel.foto = foto;
    } else {
      loginData?.foto = foto;
      sessao.data?.photo = foto;
    }
  }

  final nome = _asString(formData['nome']);
  if (nome != null) {
    loginTopLevel?.nome = nome;
    loginData?.nome = nome;
  }

  final email = _asString(formData['email']);
  if (email != null) {
    loginTopLevel?.email = email;
    loginData?.email = email;
    sessao.data?.email = email;
  }

  final parcRaw = formData['parceiro'] ?? item?['parceiro'];
  if (parcRaw is Map<String, dynamic>) {
    final p = Parceiro.fromJson(parcRaw);
    loginTopLevel?.parceiro = p;
    loginData?.parceiro = p;
  }

  final empRaw = formData['empresa'] ?? item?['empresa'];
  if (empRaw is Map<String, dynamic>) {
    final e = Empresa.fromJson(empRaw);
    loginTopLevel?.empresa = e;
    loginData?.empresa = e;
  }

  await AuthUtility.setUserInfo(sessao);
}
