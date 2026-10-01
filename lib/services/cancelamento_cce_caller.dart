import 'dart:convert';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class CancelamentoCceResult {
  final bool success;
  final Map<String, dynamic>? data;
  final List<dynamic>? list;
  final String? message;
  final int? statusCode;

  CancelamentoCceResult({
    required this.success,
    this.data,
    this.list,
    this.message,
    this.statusCode,
  });
}

class CancelamentoCceCaller {
  static Future<CancelamentoCceResult> cancelar(String nfeId, {String? justificativa}) async {
    try {
      final body = <String, dynamic>{};
      if (justificativa != null && justificativa.isNotEmpty) body['justificativa'] = justificativa;

      final response = await TenantContext.post(
        ApiLinks.cancelamentoNfeCancelar(nfeId),
        body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
        return CancelamentoCceResult(
          success: true,
          data: decoded is Map<String, dynamic> ? decoded : {'data': decoded},
          statusCode: response.statusCode,
        );
      }

      String msg = 'Erro ao cancelar (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        msg = decoded['mensagem'] ?? decoded['message'] ?? decoded['error'] ?? msg;
      } catch (_) {}
      return CancelamentoCceResult(success: false, message: msg, statusCode: response.statusCode);
    } catch (e) {
      return CancelamentoCceResult(success: false, message: 'Erro ao conectar: $e');
    }
  }

  static Future<CancelamentoCceResult> enviarCce(String nfeId, {required String correcao}) async {
    try {
      final body = <String, dynamic>{'correcao': correcao};

      final response = await TenantContext.post(
        ApiLinks.cancelamentoNfeCce(nfeId),
        body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
        return CancelamentoCceResult(
          success: true,
          data: decoded is Map<String, dynamic> ? decoded : {'data': decoded},
          statusCode: response.statusCode,
        );
      }

      String msg = 'Erro ao enviar CC-e (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        msg = decoded['mensagem'] ?? decoded['message'] ?? decoded['error'] ?? msg;
      } catch (_) {}
      return CancelamentoCceResult(success: false, message: msg, statusCode: response.statusCode);
    } catch (e) {
      return CancelamentoCceResult(success: false, message: 'Erro ao conectar: $e');
    }
  }

  static Future<CancelamentoCceResult> historico(String nfeId) async {
    try {
      final response = await TenantContext.get(
        ApiLinks.cancelamentoNfeHistorico(nfeId),
      );

      if (response.statusCode == 200) {
        final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          list = decoded['data'] ?? decoded['conteudo'] ?? decoded['resultado'] ?? [];
        }
        return CancelamentoCceResult(
          success: true,
          list: list,
          data: decoded is Map<String, dynamic> ? decoded : null,
          statusCode: response.statusCode,
        );
      }

      String msg = 'Erro ao buscar histórico (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        msg = decoded['mensagem'] ?? decoded['message'] ?? decoded['error'] ?? msg;
      } catch (_) {}
      return CancelamentoCceResult(success: false, message: msg, statusCode: response.statusCode);
    } catch (e) {
      return CancelamentoCceResult(success: false, message: 'Erro ao conectar: $e');
    }
  }
}
