import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/aplicativo_model.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';

void main() {
  tearDown(() {
    AuthUtility.userInfo = null;
  });

  group('TenantContext — Trading broker config', () {
    test('jsonHeaders inclui X-Tenant-ID para salvar configuração da corretora', () {
      AuthUtility.userInfo = LoginModel(
        token: 'token-trading',
        login: Login(
          id: 5,
          empresa: Empresa(id: 321),
          parceiro: Parceiro(id: 77),
          aplicativo: Aplicativo(id: 9),
        ),
      );

      expect(TenantContext.hasEmpresa, isTrue);
      expect(TenantContext.jsonHeaders['Authorization'], equals('Bearer token-trading'));
      expect(TenantContext.jsonHeaders['X-Tenant-ID'], equals('321'));
    });
  });
}
