import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/utils/login_session_sync.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = null;
  });

  tearDown(() {
    AuthUtility.userInfo = null;
  });

  test('sincroniza foto do login salvo quando ele e o usuario logado',
      () async {
    AuthUtility.userInfo = LoginModel(
      token: 'token-fake',
      login: Login(
        id: 967,
        email: 'brasilmodasurfltda@gmail.com',
        nome: 'BRASIL MODA SURF LTDA',
      ),
    );

    await sincronizarSessaoLoginAtualAposSalvar(
      {
        'id': 967,
        'email': 'brasilmodasurfltda@gmail.com',
        'nome': 'BRASIL MODA SURF LTDA',
        'foto': 'data:image/png;base64,AAAA',
      },
      {'id': 967},
    );

    expect(
      AuthUtility.userInfo?.login?.foto,
      equals('data:image/png;base64,AAAA'),
    );
  });

  test('nao altera sessao quando o login salvo e de outro usuario', () async {
    AuthUtility.userInfo = LoginModel(
      token: 'token-fake',
      login: Login(id: 967, foto: 'foto-atual'),
    );

    await sincronizarSessaoLoginAtualAposSalvar(
      {'id': 969, 'foto': 'foto-de-outro-login'},
      {'id': 969},
    );

    expect(AuthUtility.userInfo?.login?.foto, equals('foto-atual'));
  });
}
