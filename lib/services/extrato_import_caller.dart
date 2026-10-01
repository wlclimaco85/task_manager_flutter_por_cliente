import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';

class ExtratoImportResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;
  final int? statusCode;

  ExtratoImportResult({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });
}

class ExtratoImportCaller {
  static Future<ExtratoImportResult> preview({
    required int contaBancariaId,
    required PlatformFile arquivo,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final url = TenantContext.applyToUrl(ApiLinks.extratoPreview);
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
        return ExtratoImportResult(
          success: false,
          message: 'Arquivo inválido: sem bytes e sem caminho',
        );
      }

      // BUG produção: o campo multipart era enviado como "file", mas
      // ExtratoImportacaoController.preview espera
      // @RequestParam("arquivo") MultipartFile arquivo -- o backend nunca
      // reconhecia o arquivo enviado (500 "Required part 'arquivo' is not
      // present.").
      request.files.add(http.MultipartFile.fromBytes(
        'arquivo',
        fileBytes,
        filename: arquivo.name,
      ));
      request.fields['contaBancariaId'] = contaBancariaId.toString();
      request.fields['empresaId'] = TenantContext.empresaId?.toString() ?? '0';

      final streamed = await httpClient.send(request);
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body =
            resp.body.isNotEmpty ? jsonDecode(resp.body) : <String, dynamic>{};
        final dados = body is Map<String, dynamic> ? body : {'resposta': body};
        return ExtratoImportResult(
          success: true,
          data: dados,
          statusCode: resp.statusCode,
        );
      }

      String msg = 'Erro ao processar preview (${resp.statusCode})';
      try {
        final body = jsonDecode(resp.body);
        msg = body['mensagem']?.toString() ??
            body['message']?.toString() ??
            body['error']?.toString() ??
            msg;
      } catch (_) {}
      return ExtratoImportResult(
        success: false,
        message: msg,
        statusCode: resp.statusCode,
      );
    } catch (e) {
      return ExtratoImportResult(
        success: false,
        message: 'Erro ao conectar: $e',
      );
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Future<ExtratoImportResult> confirmar({
    required int contaBancariaId,
    required PlatformFile arquivo,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final url = TenantContext.applyToUrl(ApiLinks.extratoConfirmar);
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
        return ExtratoImportResult(
          success: false,
          message: 'Arquivo inválido: sem bytes e sem caminho',
        );
      }

      // BUG produção: o campo multipart era enviado como "file", mas
      // ExtratoImportacaoController.confirmar espera
      // @RequestParam("arquivo") MultipartFile arquivo -- 500 "Required
      // part 'arquivo' is not present." em toda tentativa de confirmar
      // importação de extrato bancário.
      request.files.add(http.MultipartFile.fromBytes(
        'arquivo',
        fileBytes,
        filename: arquivo.name,
      ));
      request.fields['contaBancariaId'] = contaBancariaId.toString();
      request.fields['empresaId'] = TenantContext.empresaId?.toString() ?? '0';

      final streamed = await httpClient.send(request);
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body =
            resp.body.isNotEmpty ? jsonDecode(resp.body) : <String, dynamic>{};
        final dados = body is Map<String, dynamic> ? body : {'resposta': body};
        return ExtratoImportResult(
          success: true,
          data: dados,
          statusCode: resp.statusCode,
        );
      }

      String msg = 'Erro na importação (${resp.statusCode})';
      try {
        final body = jsonDecode(resp.body);
        msg = body['mensagem']?.toString() ??
            body['message']?.toString() ??
            body['error']?.toString() ??
            msg;
      } catch (_) {}
      return ExtratoImportResult(
        success: false,
        message: msg,
        statusCode: resp.statusCode,
      );
    } catch (e) {
      return ExtratoImportResult(
        success: false,
        message: 'Erro ao conectar: $e',
      );
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Future<bool> excluirImportacao(int id) async {
    try {
      final url =
          TenantContext.applyToUrl(ApiLinks.excluirExtratoImportacao(id));
      final token = AuthUtility.userInfo?.token;
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao excluir importação $id: $e');
      return false;
    }
  }

  static Future<List<dynamic>> listarImportacoes() async {
    try {
      final url = TenantContext.applyToUrl(ApiLinks.extratoImportacoes);
      final token = AuthUtility.userInfo?.token;
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map && body.containsKey('data')) {
          final data = body['data'];
          if (data is List) return data;
        }
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao listar importações: $e');
      return [];
    }
  }
}
