import 'dart:convert';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class ConsultaDfeResult {
  final bool success;
  final Map<String, dynamic>? data;
  final List<dynamic>? list;
  final String? message;
  final int? statusCode;

  ConsultaDfeResult({
    required this.success,
    this.data,
    this.list,
    this.message,
    this.statusCode,
  });
}

class ConsultaDfeCaller {
  static Future<ConsultaDfeResult> consultar({
    String? cnpjEmitente,
    String? chave,
    String? dataInicio,
    String? dataFim,
    int? empresaId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (cnpjEmitente != null && cnpjEmitente.isNotEmpty) body['cnpjEmitente'] = cnpjEmitente;
      if (chave != null && chave.isNotEmpty) body['chave'] = chave;
      if (dataInicio != null) body['dataInicio'] = dataInicio;
      if (dataFim != null) body['dataFim'] = dataFim;
      if (empresaId != null) body['empresaId'] = empresaId;

      final response = await TenantContext.post(
        ApiLinks.consultaDfeConsultar,
        body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
        return ConsultaDfeResult(
          success: true,
          data: decoded is Map<String, dynamic> ? decoded : {'data': decoded},
          statusCode: response.statusCode,
        );
      }

      String msg = 'Erro na consulta (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        msg = decoded['mensagem'] ?? decoded['message'] ?? decoded['error'] ?? msg;
      } catch (_) {}
      return ConsultaDfeResult(success: false, message: msg, statusCode: response.statusCode);
    } catch (e) {
      return ConsultaDfeResult(success: false, message: 'Erro ao conectar: $e');
    }
  }

  static Future<ConsultaDfeResult> baixar(String nsu) async {
    try {
      final response = await TenantContext.post(
        ApiLinks.baixarDfe(nsu),
        {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
        return ConsultaDfeResult(
          success: true,
          data: decoded is Map<String, dynamic> ? decoded : {'data': decoded},
          statusCode: response.statusCode,
        );
      }

      String msg = 'Erro ao baixar (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        msg = decoded['mensagem'] ?? decoded['message'] ?? decoded['error'] ?? msg;
      } catch (_) {}
      return ConsultaDfeResult(success: false, message: msg, statusCode: response.statusCode);
    } catch (e) {
      return ConsultaDfeResult(success: false, message: 'Erro ao conectar: $e');
    }
  }

  static Future<ConsultaDfeResult> listarImportacoes() async {
    try {
      final response = await TenantContext.get(ApiLinks.importacoesDfe);

      if (response.statusCode == 200) {
        final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list = decoded['data'] ?? decoded['conteudo'] ?? decoded['resultado'] ?? [];
        }
        return ConsultaDfeResult(success: true, list: list, data: decoded is Map<String, dynamic> ? decoded : null, statusCode: response.statusCode);
      }

      String msg = 'Erro ao listar importações (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        msg = decoded['mensagem'] ?? decoded['message'] ?? decoded['error'] ?? msg;
      } catch (_) {}
      return ConsultaDfeResult(success: false, message: msg, statusCode: response.statusCode);
    } catch (e) {
      return ConsultaDfeResult(success: false, message: 'Erro ao conectar: $e');
    }
  }
}
