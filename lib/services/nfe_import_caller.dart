import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';

class NfeImportResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;
  final int? statusCode;

  NfeImportResult({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });
}

class NfeImportCaller {
  static Future<NfeImportResult> enviarXml(PlatformFile arquivo, {bool isPreview = false}) async {
    try {
      final url = TenantContext.applyToUrl('${ApiLinks.baseUrl}/api/nfe/entrada/import');
      final token = AuthUtility.userInfo?.token;

      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      Uint8List fileBytes;
      if (arquivo.bytes != null) {
        fileBytes = arquivo.bytes!;
      } else if (arquivo.path != null) {
        fileBytes = await File(arquivo.path!).readAsBytes();
      } else {
        return NfeImportResult(success: false, message: 'Arquivo inválido: sem bytes e sem caminho');
      }

      request.files.add(http.MultipartFile.fromBytes(
        'xml',
        fileBytes,
        filename: arquivo.name,
      ));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : <String, dynamic>{};
        final dados = body is Map<String, dynamic> ? body : {'resposta': body};
        return NfeImportResult(success: true, data: dados, statusCode: resp.statusCode);
      }

      String msg = isPreview
          ? 'Erro ao processar XML (${resp.statusCode})'
          : 'Erro na importação (${resp.statusCode})';
      try {
        final body = jsonDecode(resp.body);
        msg = body['mensagem']?.toString() ??
            body['message']?.toString() ??
            body['error']?.toString() ??
            msg;
      } catch (_) {}
      return NfeImportResult(success: false, message: msg, statusCode: resp.statusCode);
    } catch (e) {
      return NfeImportResult(success: false, message: 'Erro ao conectar: $e');
    }
  }
}
