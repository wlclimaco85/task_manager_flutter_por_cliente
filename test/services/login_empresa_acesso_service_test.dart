import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/network_response.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/services/login_empresa_acesso_service.dart';
import 'package:task_manager_flutter/services/network_caller.dart';

class _NetworkCallerTrocaEmpresa extends NetworkCaller {
  @override
  Future<NetworkResponse> putRequest(String url, dynamic body) async {
    return NetworkResponse(true, 200, {
      'empresaId': 2,
      'empresaNome': 'Empresa 2',
      'parceiroId': 51,
      'parceiroNome': 'Parceiro Empresa 2',
      'status': 'APROVADO',
      'ativa': true,
    });
  }

  @override
  Future<NetworkResponse> getRequest(String url) async {
    return NetworkResponse(true, 200, <Map<String, dynamic>>[]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthUtility.userInfo = LoginModel(
      token: 'token',
      login: Login(
        id: 10,
        empresa: Empresa(id: 1, nome: 'Empresa 1'),
        parceiro: Parceiro(id: 50, nome: 'Parceiro Empresa 1'),
      ),
    );
  });

  tearDown(() {
    AuthUtility.userInfo = null;
    AuthUtility.empresasAcesso = [];
  });

  test('troca empresa e parceiro da sessao como um unico contexto fiscal',
      () async {
    final service = LoginEmpresaAcessoService(
      networkCaller: _NetworkCallerTrocaEmpresa(),
    );

    final trocou = await service.trocarEmpresaAtiva(2);

    expect(trocou, isTrue);
    expect(AuthUtility.userInfo?.login?.empresa?.id, 2);
    expect(AuthUtility.userInfo?.login?.empresa?.nome, 'Empresa 2');
    expect(AuthUtility.userInfo?.login?.parceiro?.id, 51);
    expect(
      AuthUtility.userInfo?.login?.parceiro?.nome,
      'Parceiro Empresa 2',
    );
  });
}
