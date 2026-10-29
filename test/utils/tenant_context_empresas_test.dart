import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';

void main() {
  tearDown(() {
    AuthUtility.userInfo = null;
  });

  LoginModel loginDe(String email) => LoginModel(
        login: Login(id: 1, email: email, empresa: Empresa(id: 42)),
      );

  test('dono nao tem empId injetado na listagem de empresas', () {
    AuthUtility.userInfo = loginDe('wlclimaco@gmail.com');

    final uri = Uri.parse(TenantContext.applyToUrl('http://x/api/empresa'));

    expect(uri.queryParameters.containsKey('empId'), isFalse);
  });

  test('dono continua com empId nas demais listagens', () {
    AuthUtility.userInfo = loginDe('wlclimaco@gmail.com');

    final uri = Uri.parse(TenantContext.applyToUrl('http://x/api/parceiro'));

    expect(uri.queryParameters['empId'], '42');
  });

  test('usuario comum continua com empId na listagem de empresas', () {
    AuthUtility.userInfo = loginDe('cliente@exemplo.com');

    final uri = Uri.parse(TenantContext.applyToUrl('http://x/api/empresa'));

    expect(uri.queryParameters['empId'], '42');
  });
}
