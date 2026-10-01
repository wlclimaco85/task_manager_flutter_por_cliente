import '../models/auth_utility.dart';
import '../models/empresa_acesso_model.dart';
import '../models/network_response.dart';
import '../models/parceiro_model.dart';
import '../utils/api_links.dart';
import 'network_caller.dart';

class LoginEmpresaAcessoService {
  final NetworkCaller _networkCaller;

  LoginEmpresaAcessoService({NetworkCaller? networkCaller})
      : _networkCaller = networkCaller ?? NetworkCaller();

  Future<List<EmpresaAcesso>> listarMeusAcessos() async {
    final response =
        await _networkCaller.getRequest(ApiLinks.loginEmpresasAcesso);
    final acessos = _parseList(response);
    AuthUtility.empresasAcesso = acessos;
    return acessos;
  }

  Future<List<EmpresaAcesso>> listarAcessosDoLogin(int loginId) async {
    return _parseList(
      await _networkCaller
          .getRequest(ApiLinks.loginEmpresasAcessoDoLogin(loginId)),
    );
  }

  Future<List<Map<String, dynamic>>> listarEmpresasDisponiveisParaLogin(
    int loginId,
  ) async {
    final response = await _networkCaller
        .getRequest(ApiLinks.loginEmpresasDisponiveisDoLogin(loginId));
    if (!response.isSuccess || response.body == null) return [];
    return _parseRawList(response.body)
        .whereType<Map>()
        .map((empresa) {
          final item = Map<String, dynamic>.from(empresa);
          final id = item['id'] ?? item['value'];
          final label = (item['nomeFantasia'] ??
                  item['nome'] ??
                  item['razaoSocial'] ??
                  item['label'] ??
                  'Empresa #$id')
              .toString();
          return {'value': id, 'label': label};
        })
        .where((empresa) => empresa['value'] != null)
        .toList();
  }

  Future<bool> trocarEmpresaAtiva(int empresaId) async {
    final response = await _networkCaller.putRequest(
      ApiLinks.loginEmpresaAtiva,
      {'empresaId': empresaId},
    );
    if (!response.isSuccess || response.body == null) return false;
    final acesso = EmpresaAcesso.fromJson(
      Map<String, dynamic>.from(response.body as Map),
    );
    final parceiro = acesso.parceiroId == null
        ? null
        : Parceiro(
            id: acesso.parceiroId,
            nome: acesso.parceiroNome,
            empresa: acesso.toEmpresa(),
          );
    await AuthUtility.atualizarContextoAtivo(acesso.toEmpresa(), parceiro);
    await listarMeusAcessos();
    return true;
  }

  Future<bool> solicitarAcesso(int empresaId) async {
    final response = await _networkCaller.postRequest(
      ApiLinks.loginEmpresasAcessoSolicitar,
      {'empresaId': empresaId},
    );
    if (response.isSuccess) {
      await listarMeusAcessos();
    }
    return response.isSuccess;
  }

  Future<bool> solicitarAcessoParaLogin(int loginId, int empresaId) async {
    final response = await _networkCaller.postRequest(
      ApiLinks.loginEmpresasAcessoDoLoginSolicitar(loginId),
      {'empresaId': empresaId},
    );
    return response.isSuccess;
  }

  Future<List<EmpresaAcesso>> listarPendentes({int? empresaId}) async {
    final url = empresaId == null
        ? ApiLinks.loginEmpresaAcessoPendentes
        : '${ApiLinks.loginEmpresaAcessoPendentes}?empresaId=$empresaId';
    return _parseList(await _networkCaller.getRequest(url));
  }

  Future<bool> aprovar(int acessoId) async {
    final response = await aprovarResponse(acessoId);
    return response.isSuccess;
  }

  Future<NetworkResponse> aprovarResponse(int acessoId) async {
    return await _networkCaller.putRequest(
      ApiLinks.loginEmpresaAcessoAprovar(acessoId),
      {},
    );
  }

  Future<bool> negar(int acessoId) async {
    final response = await negarResponse(acessoId);
    return response.isSuccess;
  }

  Future<NetworkResponse> negarResponse(int acessoId) async {
    return await _networkCaller.putRequest(
      ApiLinks.loginEmpresaAcessoNegar(acessoId),
      {},
    );
  }

  List<EmpresaAcesso> _parseList(NetworkResponse response) {
    if (!response.isSuccess || response.body == null) return [];
    final raw = _parseRawList(response.body);
    return raw
        .whereType<Map>()
        .map((e) => EmpresaAcesso.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<dynamic> _parseRawList(dynamic body) {
    final raw = body is List
        ? body
        : body is Map<String, dynamic>
            ? (body['data'] is Map
                ? (body['data'] as Map)['dados']
                : body['data'])
            : null;
    return raw is List ? raw : [];
  }
}
