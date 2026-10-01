import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = null;
  });

  test('setUserInfo grava em SharedPreferences e popula userInfo', () async {
    final model = LoginModel(
      token: 'token-test',
      login: Login(id: 1, email: 'user@test.com', empresa: Empresa(id: 5)),
    );

    await AuthUtility.setUserInfo(model);
    expect(AuthUtility.userInfo, isNotNull);
    expect(AuthUtility.userInfo?.token, equals('token-test'));

    final restored = await AuthUtility.getUserInfo();
    expect(restored, isNotNull);
    expect(restored?.token, equals('token-test'));
    expect(restored?.login?.empresa?.id, equals(5));
  });

  test('setUserInfo nao persiste imagens base64 grandes', () async {
    final model = LoginModel(
      token: 'token-test',
      login: Login(
        id: 1,
        email: 'user@test.com',
        foto: 'base64-muito-grande',
      ),
    );

    await AuthUtility.setUserInfo(model);

    expect(AuthUtility.userInfo?.login?.foto, equals('base64-muito-grande'));

    final prefs = await SharedPreferences.getInstance();
    final stored =
        jsonDecode(prefs.getString('user_data')!) as Map<String, dynamic>;
    expect(stored['login'], isNot(contains('foto')));
  });

  test('getUserInfo restaura sessao persistida com data e login top-level',
      () async {
    final model = LoginModel(
      status: 'success',
      token: 'token-test',
      data: Data(id: 99),
      login: Login(id: 1, email: 'user@test.com', empresa: Empresa(id: 5)),
    );

    await AuthUtility.setUserInfo(model);
    AuthUtility.userInfo = null;

    final restored = await AuthUtility.getUserInfo();

    expect(restored?.token, equals('token-test'));
    expect(restored?.login?.id, equals(1));
    expect(restored?.login?.empresa?.id, equals(5));
  });

  test('clearUserInfo remove SharedPreferences e limpa userInfo', () async {
    final model = LoginModel(token: 'token-test', login: Login(id: 1));
    await AuthUtility.setUserInfo(model);
    await AuthUtility.clearUserInfo();

    expect(AuthUtility.userInfo, isNull);
    final restored = await AuthUtility.getUserInfo();
    expect(restored, isNull);
    expect(await AuthUtility.isUserLoggedIn(), isFalse);
  });

  test('isUserLoggedIn retorna false quando não há dados', () async {
    expect(await AuthUtility.isUserLoggedIn(), isFalse);
  });

  // Card empresa-acesso: `atualizarEmpresaAtiva` foi apagado por acidente
  // num commit de restauracao de layout de login (da750a15) e reintroduzido
  // nesta correcao -- cobre o caso de sucesso (login top-level e data.login)
  // e o caso sem sessao (no-op).
  test('atualizarEmpresaAtiva atualiza empresa no login e persiste sessao',
      () async {
    final model = LoginModel(
      token: 'token-test',
      login: Login(id: 1, email: 'user@test.com', empresa: Empresa(id: 5)),
      data: Data(id: 99, login: Login(id: 1, empresa: Empresa(id: 5))),
    );
    await AuthUtility.setUserInfo(model);

    await AuthUtility.atualizarEmpresaAtiva(Empresa(id: 42, nome: 'Nova Empresa'));

    expect(AuthUtility.userInfo?.login?.empresa?.id, equals(42));
    expect(AuthUtility.userInfo?.data?.login?.empresa?.id, equals(42));

    final restored = await AuthUtility.getUserInfo();
    expect(restored?.login?.empresa?.id, equals(42));
  });

  test('atualizarEmpresaAtiva nao lanca erro quando nao ha sessao ativa',
      () async {
    AuthUtility.userInfo = null;
    await AuthUtility.atualizarEmpresaAtiva(Empresa(id: 1));
    expect(AuthUtility.userInfo, isNull);
  });
}
