import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/anexo_financeiro_model.dart';
import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

const int _maxBytes = 10 * 1024 * 1024; // 10MB
const List<String> _allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'xml'];

class AnexoFinanceiroService {
  /// [empresaId] e opcional (a maioria dos usuarios ja tem empresa fixada no
  /// TenantContext no backend) mas OBRIGATORIO na pratica para usuarios
  /// MASTER — o TenantContext deles nunca tem empresaId (por definicao, ver
  /// TenantContextPopulator), e sem esse parametro o backend nao tem como
  /// saber de qual empresa sao os anexos, causando 500. Passe sempre que
  /// souber a empresa do lancamento (ex.: conta.empresa.id).
  Future<List<AnexoFinanceiro>> listar(int lancamentoId, String tipo, {int? empresaId}) async {
    final uri = Uri.parse(
      TenantContext.applyToUrl(ApiLinks.anexosFinanceiros) +
          '&lancamentoId=$lancamentoId&tipo=$tipo'
          '${empresaId != null ? '&empresaId=$empresaId' : ''}',
    );
    final resp = await http.get(uri, headers: TenantContext.jsonHeaders);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => AnexoFinanceiro.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw AnexoException(_mensagemErro(resp.body, resp.statusCode, 'listar anexos'));
  }

  Future<AnexoFinanceiro> upload(int lancamentoId, String tipo, PlatformFile file, {int? empresaId}) async {
    _validarArquivo(file);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(TenantContext.applyToUrl(ApiLinks.anexosFinanceiros)),
    );
    request.headers.addAll(TenantContext.headers);
    request.fields['lancamentoId'] = lancamentoId.toString();
    request.fields['tipo'] = tipo;
    if (empresaId != null) request.fields['empresaId'] = empresaId.toString();

    final bytes = file.bytes;
    if (bytes == null) throw const AnexoException('Não foi possível ler o arquivo. Use withData: true no FilePicker.');

    final mimeType = _inferirMimeType(file.name);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: file.name,
      contentType: mimeType,
    ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return AnexoFinanceiro.fromJson(jsonDecode(body) as Map<String, dynamic>);
    }
    throw AnexoException(_mensagemErro(body, streamed.statusCode, 'enviar anexo'));
  }

  /// Envia um anexo a partir de bytes ja em memoria (ex.: imagem baixada do
  /// chat ao abrir um chamado — ver card #432), sem depender de FilePicker.
  Future<AnexoFinanceiro> uploadBytes(
      int lancamentoId, String tipo, Uint8List bytes, String fileName, {int? empresaId}) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(TenantContext.applyToUrl(ApiLinks.anexosFinanceiros)),
    );
    request.headers.addAll(TenantContext.headers);
    request.fields['lancamentoId'] = lancamentoId.toString();
    request.fields['tipo'] = tipo;
    if (empresaId != null) request.fields['empresaId'] = empresaId.toString();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
      contentType: _inferirMimeType(fileName),
    ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return AnexoFinanceiro.fromJson(jsonDecode(body) as Map<String, dynamic>);
    }
    throw AnexoException(_mensagemErro(body, streamed.statusCode, 'enviar anexo'));
  }

  Future<Uint8List> download(int id, {int? empresaId}) async {
    final token = AuthUtility.userInfo?.token;
    final resp = await http.get(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.anexoFinanceiroDownload(id.toString())) +
          (empresaId != null ? '&empresaId=$empresaId' : '')),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) return resp.bodyBytes;
    throw AnexoException(_mensagemErro(resp.body, resp.statusCode, 'baixar anexo'));
  }

  Future<void> remover(int id, {int? empresaId}) async {
    final resp = await http.delete(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.anexoFinanceiro(id.toString())) +
          (empresaId != null ? '&empresaId=$empresaId' : '')),
      headers: TenantContext.headers,
    );
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw AnexoException(_mensagemErro(resp.body, resp.statusCode, 'remover anexo'));
    }
  }

  /// Extrai a mensagem real do backend (campo 'message' de ExceptionResponse/
  /// GlobalException) em vez de so mostrar o status code.
  String _mensagemErro(String rawBody, int statusCode, String acao) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {}
    return 'Erro ao $acao ($statusCode)';
  }

  void _validarArquivo(PlatformFile file) {
    final ext = file.name.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw AnexoException('Tipo não aceito: .$ext. Use: ${_allowedExtensions.join(', ')}');
    }
    final size = file.size;
    if (size > _maxBytes) {
      throw AnexoException('Arquivo muito grande (${(size / (1024 * 1024)).toStringAsFixed(1)}MB). Máximo: 5MB');
    }
  }

  /// Infere o MediaType pelo nome do arquivo para garantir upload correto no mobile.
  MediaType _inferirMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf'  => MediaType('application', 'pdf'),
      'jpg'  => MediaType('image', 'jpeg'),
      'jpeg' => MediaType('image', 'jpeg'),
      'png'  => MediaType('image', 'png'),
      'xml'  => MediaType('application', 'xml'),
      _      => MediaType('application', 'octet-stream'),
    };
  }
}

class AnexoException implements Exception {
  final String message;
  const AnexoException(this.message);
  @override
  String toString() => message;
}
