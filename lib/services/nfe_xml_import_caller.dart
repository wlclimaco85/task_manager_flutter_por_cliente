import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class NfeXmlImportResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;

  NfeXmlImportResult({required this.success, this.data, this.message});
}

class NfeXmlImportCaller {
  /// Envia o XML para o backend a partir dos BYTES já lidos pelo FilePicker
  /// (`withData: true`), nunca reabrindo o arquivo pelo `path` via `dart:io`.
  ///
  /// Bug de produção: a versão anterior recebia `filePath` e fazia
  /// `File(filePath).readAsBytes()`. Isso funciona no Windows (path real de
  /// disco), mas quebra no Flutter Web com
  /// "Erro ao conectar: Unsupported operation: _Namespace" -- `dart:io` não
  /// tem implementação real no navegador, e qualquer uso de `File` estoura
  /// essa exceção antes mesmo de tentar a requisição HTTP. Os bytes já
  /// carregados em `PlatformFile.bytes` (web+windows+mobile) eliminam essa
  /// dependência de disco.
  static Future<NfeXmlImportResult> preview(
    Uint8List bytes,
    String fileName, {
    http.Client? client,
  }) {
    return _enviar(ApiLinks.nfeImportacaoPreview, bytes, fileName,
        mensagemErroPadrao: 'Erro no preview', client: client);
  }

  static Future<NfeXmlImportResult> confirmar(
    Uint8List bytes,
    String fileName, {
    http.Client? client,
  }) {
    return _enviar(ApiLinks.nfeImportacaoConfirmar, bytes, fileName,
        mensagemErroPadrao: 'Erro na importação', client: client);
  }

  static Future<NfeXmlImportResult> _enviar(
    String endpoint,
    Uint8List bytes,
    String fileName, {
    required String mensagemErroPadrao,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final uri = TenantContext.applyToUrl(endpoint);
      final token = AuthUtility.userInfo?.token;

      final request = http.MultipartRequest('POST', Uri.parse(uri));
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      // Nome do campo multipart deve casar com @RequestParam("xml") em
      // NfeImportController.preview/confirmar -- "file" nunca bateu com o
      // parametro real esperado pelo backend.
      request.files.add(http.MultipartFile.fromBytes(
        'xml',
        bytes,
        filename: fileName,
      ));

      final streamed = await httpClient.send(request);
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : <String, dynamic>{};
        return NfeXmlImportResult(
          success: true,
          data: body is Map<String, dynamic> ? body : {'data': body},
        );
      }

      String msg = '$mensagemErroPadrao (${resp.statusCode})';
      try {
        final body = jsonDecode(resp.body);
        msg = body['mensagem']?.toString() ??
            body['message']?.toString() ??
            body['error']?.toString() ??
            msg;
      } catch (_) {}
      return NfeXmlImportResult(success: false, message: msg);
    } catch (e) {
      return NfeXmlImportResult(success: false, message: 'Erro ao conectar: $e');
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Future<List<dynamic>> listar() async {
    try {
      final uri = TenantContext.applyToUrl(ApiLinks.nfeImportacaoListar);
      final token = AuthUtility.userInfo?.token;

      final resp = await http.get(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : [];
        if (body is List) return body;
        if (body is Map && body.containsKey('data')) return body['data'] as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
