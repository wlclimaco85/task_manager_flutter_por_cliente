import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bank_reconciliation_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class BankReconciliationService {
  Future<BankImportResult> importStatement({
    int? empresaId,
    int? contaBancariaId,
    required String bankCode,
    required String content,
    String format = 'CSV',
  }) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.bankingImport)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        'tenantId': (empresaId ?? TenantContext.empresaId)?.toString(),
        'empresaId': empresaId ?? TenantContext.empresaId,
        'contaBancariaId': contaBancariaId,
        'bankCode': bankCode,
        'content': content,
        'format': format,
      }..removeWhere((_, value) => value == null)),
    );

    return _parseSingle(
      response,
      BankImportResult.fromJson,
      'Erro ao importar extrato bancário.',
    );
  }

  Future<BankReconciliationResult> reconcile({
    required String importId,
    String ruleName = 'AUTO_VALOR_DATA_TEXTO',
    String textSearch = '',
    double tolerance = 0.01,
  }) async {
    final response = await http.post(
      Uri.parse(
        TenantContext.applyToUrl(
          ApiLinks.bankingReconcile(
            importId: importId,
            ruleName: ruleName,
            textSearch: textSearch,
            tolerance: tolerance,
          ),
        ),
      ),
      headers: TenantContext.jsonHeaders,
    );

    return _parseSingle(
      response,
      BankReconciliationResult.fromJson,
      'Erro ao conciliar extrato bancário.',
    );
  }

  Future<BankReconciliationResult> importAndReconcile({
    int? empresaId,
    int? contaBancariaId,
    required String bankCode,
    required String content,
    String format = 'CSV',
    double tolerance = 0.01,
  }) async {
    final imported = await importStatement(
      empresaId: empresaId,
      contaBancariaId: contaBancariaId,
      bankCode: bankCode,
      content: content,
      format: format,
    );
    return reconcile(importId: imported.importId, tolerance: tolerance);
  }

  T _parseSingle<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
    String defaultMessage,
  ) {
    final body = _decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) return parser(body);
      if (body is Map) return parser(Map<String, dynamic>.from(body));
    }
    throw BankReconciliationException(
      _extractError(body) ?? '$defaultMessage (${response.statusCode}).',
    );
  }

  dynamic _decode(List<int> bytes) {
    if (bytes.isEmpty) return null;
    final raw = utf8.decode(bytes).trim();
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  String? _extractError(dynamic body) {
    if (body is String && body.trim().isNotEmpty) return body.trim();
    if (body is Map) {
      final message = body['message'] ?? body['error'] ?? body['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
    }
    return null;
  }
}

class BankReconciliationException implements Exception {
  final String message;

  const BankReconciliationException(this.message);

  @override
  String toString() => message;
}
