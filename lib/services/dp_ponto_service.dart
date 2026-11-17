import 'dart:convert';
import 'dart:typed_data';

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/tenant_context.dart';

/// Erro de negocio/rede do DP com mensagem pronta para o usuario.
/// [previa] vem preenchida quando o fechamento foi barrado por pendencias bloqueantes (HTTP 409).
class DpPontoException implements Exception {
  DpPontoException(this.message, {this.statusCode, this.previa});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? previa;

  @override
  String toString() => message;
}

/// Minutos -> "hh:mm" (com sinal quando negativo).
String formatarMinutos(num? minutos) {
  final m = (minutos ?? 0).round();
  final a = m.abs();
  final hh = (a ~/ 60).toString().padLeft(2, '0');
  final mm = (a % 60).toString().padLeft(2, '0');
  return '${m < 0 ? '-' : ''}$hh:$mm';
}

/// Fechamento da empresa e relatorios de ponto do Departamento Pessoal.
/// Toda regra (CLT, tenant, permissao) fica no backend; aqui so ha chamadas e tratamento de erro.
class DpPontoService {
  static const tiposRelatorio = <String, String>{
    'espelho': 'Espelho de ponto consolidado',
    'resumo-mensal': 'Resumo mensal por funcionário',
    'horas-extras': 'Horas extras',
    'banco-horas': 'Banco de horas (extrato e saldo)',
    'atrasos-faltas': 'Atrasos, saídas antecipadas e faltas',
    'inconsistencias': 'Inconsistências',
    'ajustes': 'Ajustes de ponto',
    'absenteismo-setor': 'Absenteísmo por setor',
    'jornada': 'Jornada prevista × realizada',
  };

  String get _fechamento => '${ApiLinks.baseUrl}/api/dp/fechamento-empresa';
  String get _relatorios => '${ApiLinks.baseUrl}/api/dp/relatorios';

  static String _data(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<Map<String, dynamic>>> competencias() async {
    final body = await _get('$_fechamento/competencias');
    return (body as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> previa(int mes, int ano) async =>
      Map<String, dynamic>.from(await _get('$_fechamento/previa?mes=$mes&ano=$ano') as Map);

  Future<Map<String, dynamic>> fechar(int mes, int ano, {bool forcar = false}) async =>
      Map<String, dynamic>.from(await _post('$_fechamento/fechar', {'mes': mes, 'ano': ano, 'forcar': forcar}) as Map);

  Future<Map<String, dynamic>> reabrir(int mes, int ano, String motivo) async =>
      Map<String, dynamic>.from(await _post('$_fechamento/reabrir', {'mes': mes, 'ano': ano, 'motivo': motivo}) as Map);

  // ── Assinatura do espelho, banco de horas e pendencias (regras CLT no backend) ──────────────────────

  String get _folhaPonto => '${ApiLinks.baseUrl}/api/folha-ponto';
  String get _banco => '${ApiLinks.baseUrl}/api/dp/banco-horas';
  String get _pendenciasUrl => '${ApiLinks.baseUrl}/api/dp/pendencias';

  /// Funcionarios da empresa para os seletores: [{id, nome}].
  Future<List<Map<String, dynamic>>> funcionarios() async {
    final body = await _get('${ApiLinks.baseUrl}/api/funcionario?tamanho=200');
    var lista = <dynamic>[];
    if (body is Map) {
      final d = body['data'];
      if (d is Map) {
        lista = (d['dados'] ?? d['content'] ?? []) as List;
      } else if (d is List) {
        lista = d;
      }
    }
    return lista.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> estadoAssinatura(int funcionarioId, int mes, int ano) async =>
      Map<String, dynamic>.from(await _get('$_folhaPonto/assinatura?funcionarioId=$funcionarioId&mes=$mes&ano=$ano') as Map);

  /// Aceite eletronico do funcionario (backend grava data/hora, IP e hash do espelho).
  Future<Map<String, dynamic>> aceitarEspelho(int funcionarioId, int mes, int ano) async => Map<String, dynamic>.from(
      await _post('$_folhaPonto/aceitar', {'funcionarioId': funcionarioId, 'mes': mes, 'ano': ano}) as Map);

  /// Validacao do gestor (fecha o espelho). Sem aceite do funcionario exige [justificativa].
  Future<Map<String, dynamic>> validarEspelho(int funcionarioId, int mes, int ano, {String? justificativa}) async =>
      Map<String, dynamic>.from(await _post('$_folhaPonto/fechar', {
        'funcionarioId': funcionarioId,
        'mes': mes,
        'ano': ano,
        if (justificativa != null && justificativa.isNotEmpty) 'justificativa': justificativa,
      }) as Map);

  Future<Map<String, dynamic>> extratoBanco(int funcionarioId) async =>
      Map<String, dynamic>.from(await _get('$_banco/extrato?funcionarioId=$funcionarioId') as Map);

  Future<List<Map<String, dynamic>>> alertasBanco() async =>
      (await _get('$_banco/alertas') as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  /// Paga em folha o saldo vencido (ou [minutos], quando informado) como hora extra 50%.
  Future<Map<String, dynamic>> quitarBanco(int funcionarioId, int folhaMes, int folhaAno,
          {int? minutos, String? observacao}) async =>
      Map<String, dynamic>.from(await _post('$_banco/quitar', {
        'funcionarioId': funcionarioId,
        'mes': folhaMes,
        'ano': folhaAno,
        if (minutos != null) 'minutos': minutos,
        if (observacao != null && observacao.isNotEmpty) 'observacao': observacao,
      }) as Map);

  Future<Map<String, dynamic>> pendencias() async => Map<String, dynamic>.from(await _get(_pendenciasUrl) as Map);

  /// Dispara agora os avisos (gestores e funcionarios); devolve quantos alertas foram enviados.
  Future<int> notificarPendencias() async {
    final r = await _post('$_pendenciasUrl/notificar', {});
    return r is Map ? (r['alertasEnviados'] as num? ?? 0).toInt() : 0;
  }

  Map<String, String> _filtros(String? setorId, String? funcionarioId, DateTime ini, DateTime fim) => {
        if (setorId != null && setorId.isNotEmpty) 'setorId': setorId,
        if (funcionarioId != null && funcionarioId.isNotEmpty) 'funcionarioId': funcionarioId,
        'dataInicio': _data(ini),
        'dataFim': _data(fim),
      };

  String _urlRelatorio(String tipo, String sufixo, Map<String, String> q) =>
      Uri.parse('$_relatorios/$tipo$sufixo').replace(queryParameters: q).toString();

  Future<Map<String, dynamic>> relatorio(String tipo,
          {String? setorId, String? funcionarioId, required DateTime inicio, required DateTime fim}) async =>
      Map<String, dynamic>.from(
          await _get(_urlRelatorio(tipo, '', _filtros(setorId, funcionarioId, inicio, fim))) as Map);

  /// [formato]: 'pdf' ou 'csv'.
  Future<Uint8List> baixar(String tipo, String formato,
      {String? setorId, String? funcionarioId, required DateTime inicio, required DateTime fim}) async {
    final url = _urlRelatorio(tipo, '/$formato', _filtros(setorId, funcionarioId, inicio, fim));
    try {
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) return resp.bodyBytes;
      throw DpPontoException(_mensagem(resp.bodyBytes, resp.statusCode), statusCode: resp.statusCode);
    } on DpPontoException {
      rethrow;
    } catch (e, st) {
      AppLogger.i.error('DP: falha ao baixar relatório $tipo/$formato: $e', st);
      throw DpPontoException('Não foi possível baixar o relatório. Verifique a conexão e tente novamente.');
    }
  }

  Future<dynamic> _get(String url) async {
    try {
      final resp = await TenantContext.get(url);
      return _tratar(resp.statusCode, resp.bodyBytes, url);
    } on DpPontoException {
      rethrow;
    } catch (e, st) {
      AppLogger.i.error('DP: falha de rede em GET $url: $e', st);
      throw DpPontoException('Não foi possível falar com o servidor. Tente novamente.');
    }
  }

  Future<dynamic> _post(String url, Map<String, dynamic> body) async {
    try {
      final resp = await TenantContext.post(url, body);
      return _tratar(resp.statusCode, resp.bodyBytes, url);
    } on DpPontoException {
      rethrow;
    } catch (e, st) {
      AppLogger.i.error('DP: falha de rede em POST $url: $e', st);
      throw DpPontoException('Não foi possível falar com o servidor. Tente novamente.');
    }
  }

  dynamic _tratar(int status, Uint8List bytes, String url) {
    if (status >= 200 && status < 300) {
      return jsonDecode(utf8.decode(bytes));
    }
    Map<String, dynamic>? previa;
    try {
      final b = jsonDecode(utf8.decode(bytes));
      if (b is Map && b['previa'] is Map) previa = Map<String, dynamic>.from(b['previa'] as Map);
    } catch (_) {}
    AppLogger.i.warn('DP: HTTP $status em $url');
    throw DpPontoException(_mensagem(bytes, status), statusCode: status, previa: previa);
  }

  static String _mensagem(Uint8List bytes, int status) {
    try {
      final b = jsonDecode(utf8.decode(bytes));
      if (b is Map) {
        final m = b['error'] ?? b['message'];
        if (m is String && m.isNotEmpty) return m;
      }
    } catch (_) {}
    if (status == 403) return 'Você não tem permissão para esta ação.';
    return 'Erro $status ao processar a solicitação.';
  }
}
