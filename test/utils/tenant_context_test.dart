import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/aplicativo_model.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';

void main() {
  tearDown(() {
    AuthUtility.userInfo = null;
  });

  group('TenantContext', () {
    test(
        'headers e jsonHeaders incluem Authorization e X-Tenant-ID quando há token e empresa',
        () {
      AuthUtility.userInfo = LoginModel(
        token: 'abc123',
        login: Login(
          id: 99,
          empresa: Empresa(id: 42),
          parceiro: Parceiro(id: 17),
          aplicativo: Aplicativo(id: 7),
        ),
      );

      expect(TenantContext.headers['Authorization'], equals('Bearer abc123'));
      expect(TenantContext.headers['X-Tenant-ID'], equals('42'));
      expect(TenantContext.headers['Accept-Encoding'], equals('gzip'));

      expect(
          TenantContext.jsonHeaders['Authorization'], equals('Bearer abc123'));
      expect(TenantContext.jsonHeaders['X-Tenant-ID'], equals('42'));
      expect(TenantContext.jsonHeaders['Content-Type'],
          equals('application/json'));
    });

    test(
        'applyToUrl adiciona empId, parceiro, parceiroId, parcId, clienteId, userId e userLogadoId',
        () {
      AuthUtility.userInfo = LoginModel(
        login: Login(
          id: 99,
          empresa: Empresa(id: 42),
          parceiro: Parceiro(id: 17),
          aplicativo: Aplicativo(id: 7),
        ),
      );

      final url = TenantContext.applyToUrl(
          'http://example.com/api/resource?existing=1');
      final uri = Uri.parse(url);
      expect(uri.queryParameters['existing'], equals('1'));
      expect(uri.queryParameters['empId'], equals('42'));
      expect(uri.queryParameters['parceiro'], equals('17'));
      expect(uri.queryParameters['parceiroId'], equals('17'));
      expect(uri.queryParameters['parcId'], equals('17'));
      expect(uri.queryParameters['clienteId'], equals('17'));
      expect(uri.queryParameters['userId'], equals('99'));
      expect(uri.queryParameters['userLogadoId'], equals('99'));
    });

    test('applyToUrl adiciona parceiroId na URL de transmissao da NF-e', () {
      AuthUtility.userInfo = LoginModel(
        login: Login(
          id: 970,
          empresa: Empresa(id: 1),
          parceiro: Parceiro(id: 1756),
          aplicativo: Aplicativo(id: 7),
        ),
      );

      final uri =
          Uri.parse(TenantContext.applyToUrl(ApiLinks.emitirNfe('1077')));

      expect(uri.path, contains('/api/nfe/1077/emitir'));
      expect(uri.queryParameters['empId'], equals('1'));
      expect(uri.queryParameters['parceiroId'], equals('1756'));
      expect(uri.queryParameters['parcId'], equals('1756'));
      expect(uri.queryParameters['clienteId'], equals('1756'));
      expect(uri.queryParameters['userId'], equals('970'));
    });

    test('applyToBody injeta empresa, parceiro e aplicativo quando ausentes',
        () {
      AuthUtility.userInfo = LoginModel(
        login: Login(
          id: 99,
          empresa: Empresa(id: 42),
          parceiro: Parceiro(id: 17),
          aplicativo: Aplicativo(id: 7),
        ),
      );

      final body = TenantContext.applyToBody({'foo': 'bar'});
      expect(body['foo'], equals('bar'));
      expect(body['empresa'], equals({'id': 42}));
      expect(body['parceiro'], equals({'id': 17}));
      expect(body['aplicativo'], equals({'id': 7}));
    });

    test('debugInfo descreve os ids configurados', () {
      AuthUtility.userInfo = LoginModel(
        login: Login(
          id: 99,
          empresa: Empresa(id: 42),
          parceiro: Parceiro(id: 17),
        ),
      );

      expect(TenantContext.debugInfo, contains('empresaId=42'));
      expect(TenantContext.debugInfo, contains('parceiroId=17'));
      expect(TenantContext.debugInfo, contains('userId=99'));
    });
  });
}
