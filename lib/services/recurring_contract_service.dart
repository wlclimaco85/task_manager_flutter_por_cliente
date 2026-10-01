import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recurring_contract_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class RecurringContractService {
  Future<RecurringContract> createContract({
    String? contractId,
    int? empresaId,
    int? parceiroId,
    required String customerName,
    String? customerDocument,
    required String planName,
    String? serviceDescription,
    String? municipalityCode,
    required double monthlyValue,
    required DateTime nextDueDate,
    bool generateReceivable = true,
    bool issueNfse = false,
  }) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.createRecurringContract)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        'tenantId': (empresaId ?? TenantContext.empresaId)?.toString(),
        'contractId': contractId,
        'empresaId': empresaId ?? TenantContext.empresaId,
        'parceiroId': parceiroId,
        'customerName': customerName,
        'customerDocument': customerDocument,
        'planName': planName,
        'serviceDescription': serviceDescription ?? planName,
        'municipalityCode': municipalityCode,
        'monthlyValue': monthlyValue,
        'nextDueDate': _formatDate(nextDueDate),
        'generateReceivable': generateReceivable,
        'issueNfse': issueNfse,
      }..removeWhere((_, value) => value == null)),
    );

    return _parseSingle(
      response,
      RecurringContract.fromJson,
      'Erro ao criar contrato recorrente.',
    );
  }

  Future<List<RecurringContract>> listContracts({int? empresaId}) async {
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.allRecurringContracts)),
      headers: TenantContext.jsonHeaders,
    );

    return _parseList(
      response,
      RecurringContract.fromJson,
      'Erro ao consultar contratos recorrentes.',
    );
  }

  Future<RecurringInvoice> generateInvoice({
    required String contractId,
    int? empresaId,
    double? amount,
    DateTime? dueDate,
    bool generateReceivable = true,
    bool? issueNfse,
  }) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.generateInvoice)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        'tenantId': (empresaId ?? TenantContext.empresaId)?.toString(),
        'contractId': contractId,
        'empresaId': empresaId ?? TenantContext.empresaId,
        'amount': amount,
        'dueDate': dueDate != null ? _formatDate(dueDate) : null,
        'generateReceivable': generateReceivable,
        'issueNfse': issueNfse,
      }..removeWhere((_, value) => value == null)),
    );

    return _parseSingle(
      response,
      RecurringInvoice.fromJson,
      'Erro ao gerar fatura recorrente.',
    );
  }

  Future<List<RecurringInvoice>> listInvoices() async {
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.allInvoiceRecords)),
      headers: TenantContext.jsonHeaders,
    );

    return _parseList(
      response,
      RecurringInvoice.fromJson,
      'Erro ao consultar faturas recorrentes.',
    );
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
    throw RecurringContractException(
      _extractError(body) ?? '$defaultMessage (${response.statusCode}).',
    );
  }

  List<T> _parseList<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parser,
    String defaultMessage,
  ) {
    final body = _decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is List) {
        return body
            .whereType<Map>()
            .map((item) => parser(Map<String, dynamic>.from(item)))
            .toList();
      }
      return const [];
    }
    throw RecurringContractException(
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

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class RecurringContractException implements Exception {
  final String message;

  const RecurringContractException(this.message);

  @override
  String toString() => message;
}
