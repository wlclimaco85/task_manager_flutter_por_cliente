import '../models/regua_cobranca_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';
import 'network_caller.dart';

class ReguaCobrancaException implements Exception {
  const ReguaCobrancaException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ReguaCobrancaService {
  ReguaCobrancaService({NetworkCaller? caller})
      : _caller = caller ?? NetworkCaller();

  final NetworkCaller _caller;

  /// O usuario MASTER nao tem empresa fixa no token; o backend resolve a empresa
  /// pelo parametro empId (a empresa selecionada na UI). Sem isso a regua retorna
  /// HTTP 500 ("Tenant da empresa nao identificado"). Para nao-master o backend
  /// ignora o empId, entao anexar e seguro.
  String _comEmpresa(String url) {
    final empresaId = TenantContext.empresaId;
    if (empresaId == null) return url;
    final separador = url.contains('?') ? '&' : '?';
    return '$url${separador}empId=$empresaId';
  }

  Future<List<ReguaCobranca>> listarReguas() async {
    final response = await _caller.getRequest(_comEmpresa(ApiLinks.reguasCobranca));
    final items =
        _requireList(response.isSuccess, response.statusCode, response.body);
    return items.map(ReguaCobranca.fromJson).toList();
  }

  Future<ReguaCobranca> salvarRegua(ReguaCobranca regua) async {
    final response = regua.id == null
        ? await _caller.postRequest(
            _comEmpresa(ApiLinks.reguasCobranca), regua.toJson())
        : await _caller.putRequest(
            _comEmpresa(ApiLinks.reguaCobranca(regua.id!)), regua.toJson());
    final body =
        _requireMap(response.isSuccess, response.statusCode, response.body);
    return ReguaCobranca.fromJson(_unwrapMap(body));
  }

  Future<List<CobrancaRegua>> listarPendencias() =>
      _listarCobrancas('pendencias');
  Future<List<CobrancaRegua>> listarHistorico() =>
      _listarCobrancas('historico');
  Future<List<CobrancaRegua>> listarFila() => _listarCobrancas('fila');

  Future<PainelReguaCobranca> carregarPainel() async {
    final response =
        await _caller.getRequest(_comEmpresa('${ApiLinks.cobrancasRegua}/painel'));
    final body =
        _requireMap(response.isSuccess, response.statusCode, response.body);
    return PainelReguaCobranca.fromJson(_unwrapMap(body));
  }

  Future<List<CobrancaRegua>> _listarCobrancas(String recurso) async {
    final response = await _caller
        .getRequest(_comEmpresa('${ApiLinks.cobrancasRegua}/$recurso'));
    final items =
        _requireList(response.isSuccess, response.statusCode, response.body);
    return items.map(CobrancaRegua.fromJson).toList();
  }

  Future<ExecucaoReguaResultado> executar() async {
    final response = await _caller.postRequest(
      _comEmpresa('${ApiLinks.cobrancasRegua}/executar'),
      const <String, dynamic>{},
    );
    if (!response.isSuccess) {
      throw ReguaCobrancaException(
          _errorMessage(response.statusCode, response.body));
    }
    final body = response.body;
    if (body == null) {
      throw const ReguaCobrancaException('Resposta inesperada do servidor.');
    }
    return ExecucaoReguaResultado.fromJson(_unwrapMap(body));
  }

  Future<void> reprocessar(int acaoId) async {
    final response = await _caller.postRequest(
      _comEmpresa('${ApiLinks.cobrancasRegua}/acoes/$acaoId/reprocessar'),
      const <String, dynamic>{},
    );
    _requireMap(response.isSuccess, response.statusCode, response.body);
  }

  List<Map<String, dynamic>> _requireList(
      bool success, int status, Map<String, dynamic>? body) {
    if (!success) throw ReguaCobrancaException(_errorMessage(status, body));
    final raw = body?['data'] ?? body?['content'] ?? body?['items'];
    if (raw is! List) {
      throw const ReguaCobrancaException('Resposta inesperada do servidor.');
    }
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _requireMap(
      bool success, int status, Map<String, dynamic>? body) {
    if (!success || body == null) {
      throw ReguaCobrancaException(_errorMessage(status, body));
    }
    return body;
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic> body) {
    final raw = body['data'];
    return raw is Map ? Map<String, dynamic>.from(raw) : body;
  }

  String _errorMessage(int status, Map<String, dynamic>? body) {
    final detail = body?['message'] ?? body?['mensagem'] ?? body?['error'];
    return detail?.toString() ?? 'Falha na regua de cobranca (HTTP $status).';
  }
}
