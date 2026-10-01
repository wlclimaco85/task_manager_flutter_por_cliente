import 'dart:convert';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class ManifestacaoResult {
  final bool success;
  final Map<String, dynamic>? data;
  final List<dynamic>? list;
  final String? message;
  final int? statusCode;

  ManifestacaoResult({
    required this.success,
    this.data,
    this.list,
    this.message,
    this.statusCode,
  });
}

class ManifestacaoCaller {
  static Future<ManifestacaoResult> listarPendentes() async {
    try {
      final response = await TenantContext.get(ApiLinks.manifestacaoPendentes);
      if (response.statusCode == 200) {
        final decoded = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : <String, dynamic>{};
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list = decoded['data'] ?? decoded['conteudo'] ?? decoded['resultado'] ?? [];
        }
        return ManifestacaoResult(
          success: true,
          list: list,
          data: decoded is Map<String, dynamic> ? decoded : null,
          statusCode: response.statusCode,
        );
      }
      String msg = 'Erro ao listar pendências (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        msg = decoded['mensagem'] ?? decoded['message'] ?? decoded['error'] ?? msg;
      } catch (_) {}
      return ManifestacaoResult(success: false, message: msg, statusCode: response.statusCode);
    } catch (e) {
      return ManifestacaoResult(success: false, message: 'Erro ao conectar: $e');
    }
  }

  static Future<ManifestacaoResult> listarHistorico() async {
    try {
      final response = await TenantContext.get(ApiLinks.manifestacaoHistorico);
      if (response.statusCode == 200) {
        final decoded = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : <String, dynamic>{};
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list = decoded['data'] ?? decoded['conteudo'] ?? decoded['resultado'] ?? [];
        }
        return ManifestacaoResult(
          success: true,
          list: list,
          data: decoded is Map<String, dynamic> ? decoded : null,
          statusCode: response.statusCode,
        );
      }
      String msg = 'Erro ao listar histórico (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        msg = decoded['mensagem'] ?? decoded['message'] ?? decoded['error'] ?? msg;
      } catch (_) {}
      return ManifestacaoResult(success: false, message: msg, statusCode: response.statusCode);
    } catch (e) {
      return ManifestacaoResult(success: false, message: 'Erro ao conectar: $e');
    }
  }

  static Future<ManifestacaoResult> registrarManifestacao({
    required String chave,
    required String tipo,
    String? justificativa,
  }) async {
    try {
      final body = <String, dynamic>{
        'chave': chave,
        'tipo': tipo,
      };
      if (justificativa != null && justificativa.isNotEmpty) {
        body['justificativa'] = justificativa;
      }

      final response = await TenantContext.post(
        ApiLinks.manifestacaoRegistrar,
        body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : <String, dynamic>{};
        return ManifestacaoResult(
          success: true,
          data: decoded is Map<String, dynamic> ? decoded : {'data': decoded},
          statusCode: response.statusCode,
        );
      }

      String msg = 'Erro ao registrar manifestação (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        msg = decoded['mensagem'] ?? decoded['message'] ?? decoded['error'] ?? msg;
      } catch (_) {}
      return ManifestacaoResult(success: false, message: msg, statusCode: response.statusCode);
    } catch (e) {
      return ManifestacaoResult(success: false, message: 'Erro ao conectar: $e');
    }
  }
}
