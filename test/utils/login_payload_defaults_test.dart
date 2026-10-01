import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/aplicativo_model.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/utils/login_payload_defaults.dart';
import 'package:task_manager_flutter/web/screens/login_grid_screen.dart';

void main() {
  setUp(() {
    AuthUtility.userInfo = null;
  });

  tearDown(() {
    AuthUtility.userInfo = null;
  });

  test('usa tipoLogin do login atual da sessao', () {
    AuthUtility.userInfo = LoginModel(
      login: Login(
        tipoLogin: LoginEnum.APP_CONTABILIDADE,
        aplicativo: Aplicativo(id: 99),
      ),
    );

    final payload = buildLoginAdditionalFormData();

    expect(payload['tipoLogin'], LoginEnum.APP_CONTABILIDADE.value);
    expect(payload['aplicativo'], {'id': 1});
    expect(payload['trocarSenhaProximoLogin'], isTrue);
    expect(payload.containsKey('ativo'), isFalse);
  });

  test('configuracao da tela de login envia tipoLogin sem exibir campo', () {
    AuthUtility.userInfo = LoginModel(
      login: Login(
        tipoLogin: LoginEnum.APP_CONTABILIDADE,
        aplicativo: Aplicativo(id: 99),
      ),
    );

    final payload = WebLoginGridScreen.additionalFormData;

    expect(payload['tipoLogin'], LoginEnum.APP_CONTABILIDADE.value);
    expect(
      WebLoginGridScreen.loginHiddenFields
          .firstWhere((field) => field.fieldName == 'tipoLogin')
          .isInForm,
      isFalse,
    );
  });

  test('mantem ativo no payload mobile quando solicitado', () {
    final payload = buildLoginAdditionalFormData(
      ativo: true,
      sessionLogin: Login(
        tipoLogin: LoginEnum.APP_ABRACO,
        aplicativo: Aplicativo(id: 5),
      ),
    );

    expect(payload['tipoLogin'], LoginEnum.APP_ABRACO.value);
    expect(payload['aplicativo'], {'id': 1});
    expect(payload['ativo'], isTrue);
  });

  test('assume tipoLogin seguro (APP_CONTABILIDADE) quando a sessao nao informa o valor', () {
    final payload = buildLoginAdditionalFormData();

    expect(payload['tipoLogin'], LoginEnum.APP_CONTABILIDADE.value);
    expect(payload['aplicativo'], {'id': 1});
  });

  test('assume tipoLogin de parceiro (APP_ABRACO) quando sessao e de parceiro sem tipoLogin explicito', () {
    AuthUtility.userInfo = LoginModel(
      login: Login(
        parceiro: Parceiro(id: 10),
      ),
    );

    final payload = buildLoginAdditionalFormData();

    expect(payload['tipoLogin'], LoginEnum.APP_ABRACO.value);
  });
}

