import '../models/auth_utility.dart';
import '../models/login_model.dart';

int resolveDefaultTipoLogin({Login? sessionLogin}) {
  final login = sessionLogin ?? AuthUtility.userInfo?.login;
  if (login?.tipoLogin != null) {
    return login!.tipoLogin!.value;
  }
  if (login?.parceiro != null) {
    return LoginEnum.APP_ABRACO.value;
  }
  return LoginEnum.APP_CONTABILIDADE.value;
}

Map<String, dynamic> buildLoginAdditionalFormData({
  Login? sessionLogin,
  bool ativo = false,
  int? tipoLoginOverride,
}) {
  final tipoLogin =
      tipoLoginOverride ?? resolveDefaultTipoLogin(sessionLogin: sessionLogin);

  return {
    if (ativo) 'ativo': true,
    'trocarSenhaProximoLogin': true,
    'aplicativo': {'id': 1},
    'tipoLogin': tipoLogin,
  };
}

