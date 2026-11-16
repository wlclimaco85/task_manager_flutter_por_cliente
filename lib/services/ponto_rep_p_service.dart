import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';

/// Arquivo fiscal devolvido pelo backend (AFD, AEJ, espelho, comprovante).
class RepPArquivo {
  final Uint8List bytes;
  final String nome;
  final String extensao;
  final bool assinado;

  const RepPArquivo(this.bytes, this.nome, this.extensao, {this.assinado = false});
}

/// Resultado com mensagem de erro util para o usuario (nunca falha em silencio).
class RepPResultado<T> {
  final T? dado;
  final String? erro;

  const RepPResultado.ok(this.dado) : erro = null;
  const RepPResultado.falha(this.erro) : dado = null;

  bool get ok => erro == null;
}

/// Cliente dos endpoints REP-P (Portaria MTP 671/2021): AFD, AEJ, espelho (Art. 84)
/// e comprovante de registro.
class PontoRepPService {
  PontoRepPService({http.Client? client, String? baseUrl, String? Function()? token})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiLinks.baseUrl,
        _token = token ?? (() => AuthUtility.userInfo?.token);

  final http.Client _client;
  final String _baseUrl;
  final String? Function() _token;

  static String _data(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Uri uriArquivo(String tipo, int empresaId, DateTime inicio, DateTime fim) =>
      Uri.parse('$_baseUrl/api/ponto-rep-p/$tipo?empresaId=$empresaId&inicio=${_data(inicio)}&fim=${_data(fim)}');

  Uri uriEspelho(int empresaId, int funcionarioId, int mes, int ano) => Uri.parse(
      '$_baseUrl/api/ponto-rep-p/espelho?empresaId=$empresaId&funcionarioId=$funcionarioId&mes=$mes&ano=$ano');

  Uri uriComprovante(int empresaId, int pontoId) =>
      Uri.parse('$_baseUrl/api/ponto-rep-p/comprovante/$pontoId?empresaId=$empresaId');

  Map<String, String> get _headers {
    final t = _token();
    return {if (t != null) 'Authorization': 'Bearer $t'};
  }

  /// Extrai a mensagem de erro do corpo ({"erro": "..."}) ou usa o status.
  static String mensagemErro(int status, List<int> corpo) {
    try {
      final j = jsonDecode(utf8.decode(corpo));
      if (j is Map && j['erro'] != null) return j['erro'].toString();
    } catch (_) {}
    if (status == 403) return 'Acesso negado a esta empresa.';
    if (status == 412) return 'Certificado digital nao configurado no servidor.';
    return 'Falha ($status) ao gerar o arquivo.';
  }

  Future<RepPResultado<RepPArquivo>> _baixar(Uri uri, String nome, String ext) async {
    try {
      final r = await _client.get(uri, headers: _headers);
      if (r.statusCode != 200) {
        final msg = mensagemErro(r.statusCode, r.bodyBytes);
        AppLogger.i.warn('[REP-P] ${uri.path} respondeu ${r.statusCode}: $msg');
        return RepPResultado.falha(msg);
      }
      return RepPResultado.ok(RepPArquivo(r.bodyBytes, nome, ext,
          assinado: r.headers['x-comprovante-assinado'] == 'true'));
    } catch (e, st) {
      AppLogger.i.error('[REP-P] falha de rede em ${uri.path}: $e', st);
      return const RepPResultado.falha('Sem conexao com o servidor. Tente novamente.');
    }
  }

  Future<RepPResultado<RepPArquivo>> baixarAfd(int empresaId, DateTime inicio, DateTime fim) =>
      _baixar(uriArquivo('afd', empresaId, inicio, fim), 'AFD_${empresaId}_${_data(inicio)}_${_data(fim)}', 'txt');

  Future<RepPResultado<RepPArquivo>> baixarAej(int empresaId, DateTime inicio, DateTime fim) =>
      _baixar(uriArquivo('aej', empresaId, inicio, fim), 'AEJ_${empresaId}_${_data(inicio)}_${_data(fim)}', 'txt');

  Future<RepPResultado<RepPArquivo>> baixarAfdAssinatura(int empresaId, DateTime inicio, DateTime fim) =>
      _baixar(uriArquivo('afd/assinatura', empresaId, inicio, fim), 'AFD_${empresaId}_${_data(inicio)}_${_data(fim)}', 'p7s');

  Future<RepPResultado<RepPArquivo>> baixarAejAssinatura(int empresaId, DateTime inicio, DateTime fim) =>
      _baixar(uriArquivo('aej/assinatura', empresaId, inicio, fim), 'AEJ_${empresaId}_${_data(inicio)}_${_data(fim)}', 'p7s');

  Future<RepPResultado<RepPArquivo>> baixarEspelho(int empresaId, int funcionarioId, int mes, int ano) =>
      _baixar(uriEspelho(empresaId, funcionarioId, mes, ano), 'espelho_ponto_${ano}_$mes', 'pdf');

  Future<RepPResultado<RepPArquivo>> baixarComprovante(int empresaId, int pontoId) =>
      _baixar(uriComprovante(empresaId, pontoId), 'comprovante_ponto_$pontoId', 'pdf');

  /// Situacao de conformidade (pendencias que dependem de homologacao/certificado).
  Future<RepPResultado<Map<String, dynamic>>> conformidade() async {
    try {
      final r = await _client.get(Uri.parse('$_baseUrl/api/ponto-rep-p/conformidade'), headers: _headers);
      if (r.statusCode != 200) {
        return RepPResultado.falha(mensagemErro(r.statusCode, r.bodyBytes));
      }
      return RepPResultado.ok(Map<String, dynamic>.from(jsonDecode(utf8.decode(r.bodyBytes)) as Map));
    } catch (e, st) {
      AppLogger.i.error('[REP-P] falha ao consultar conformidade: $e', st);
      return const RepPResultado.falha('Nao foi possivel consultar a conformidade.');
    }
  }
}
