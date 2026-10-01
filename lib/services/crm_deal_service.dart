import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/crm_deal_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class CrmDealService {
  Future<CrmDeal> createDeal({
    required String title,
    String? customerName,
    String source = 'MANUAL',
    String? marketplace,
    String? externalOrderId,
    String stage = 'LEAD',
    double? amount,
    DateTime? expectedCloseDate,
    String status = 'OPEN',
    String? notes,
    int? parceiroId,
  }) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.createCrmDeal)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        if (TenantContext.empresaId != null)
          'tenantId': TenantContext.empresaId.toString(),
        if (TenantContext.empresaId != null) 'empresaId': TenantContext.empresaId,
        if (parceiroId != null) 'parceiroId': parceiroId,
        'title': title,
        if (customerName != null) 'customerName': customerName,
        'source': source,
        if (marketplace != null) 'marketplace': marketplace,
        if (externalOrderId != null) 'externalOrderId': externalOrderId,
        'stage': stage,
        if (amount != null) 'amount': amount,
        if (expectedCloseDate != null)
          'expectedCloseDate': expectedCloseDate.toIso8601String().split('T').first,
        'status': status,
        if (notes != null) 'notes': notes,
      }),
    );

    return CrmDeal.fromJson(_parseMap(response, 'Erro ao criar oportunidade.'));
  }

  Future<List<CrmDeal>> listDeals() async {
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.allCrmDeals)),
      headers: TenantContext.jsonHeaders,
    );
    final body = _decode(response.bodyBytes);
    if (response.statusCode == 200) {
      if (body is List) {
        return body
            .whereType<Map>()
            .map((item) => CrmDeal.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return const [];
    }
    throw CrmDealException(
      _extractErrorMessage(body) ??
          'Erro ao listar oportunidades (${response.statusCode}).',
    );
  }

  Future<CrmDeal> importMarketplaceOrder({
    required String source,
    required String externalOrderId,
    String? marketplace,
    String? customerName,
    String? title,
    double? amount,
    String? paymentStatus,
    String? orderStatus,
    DateTime? expectedCloseDate,
    String? notes,
    int? parceiroId,
  }) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.importMarketplaceOrder)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        if (TenantContext.empresaId != null)
          'tenantId': TenantContext.empresaId.toString(),
        if (TenantContext.empresaId != null) 'empresaId': TenantContext.empresaId,
        if (parceiroId != null) 'parceiroId': parceiroId,
        'source': source,
        if (marketplace != null) 'marketplace': marketplace,
        'externalOrderId': externalOrderId,
        if (customerName != null) 'customerName': customerName,
        if (title != null) 'title': title,
        if (amount != null) 'amount': amount,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (orderStatus != null) 'orderStatus': orderStatus,
        if (expectedCloseDate != null)
          'expectedCloseDate': expectedCloseDate.toIso8601String().split('T').first,
        if (notes != null) 'notes': notes,
      }),
    );

    return CrmDeal.fromJson(
      _parseMap(response, 'Erro ao importar pedido de marketplace.'),
    );
  }

  Future<CrmDeal> updateStage({
    required int dealId,
    required String stage,
    String? status,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse(
        TenantContext.applyToUrl(ApiLinks.updateCrmDealStage(dealId.toString())),
      ),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        if (TenantContext.empresaId != null)
          'tenantId': TenantContext.empresaId.toString(),
        if (TenantContext.empresaId != null) 'empresaId': TenantContext.empresaId,
        'stage': stage,
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
      }),
    );

    return CrmDeal.fromJson(
      _parseMap(response, 'Erro ao atualizar etapa da oportunidade.'),
    );
  }

  Map<String, dynamic> _parseMap(http.Response response, String message) {
    final body = _decode(response.bodyBytes);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
    }
    throw CrmDealException(_extractErrorMessage(body) ?? message);
  }

  dynamic _decode(List<int> bodyBytes) {
    if (bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(bodyBytes));
  }

  String? _extractErrorMessage(dynamic body) {
    if (body is Map) {
      return body['message']?.toString() ??
          body['error']?.toString() ??
          body['response']?['mensagem']?.toString();
    }
    return null;
  }
}

class CrmDealException implements Exception {
  final String message;

  const CrmDealException(this.message);

  @override
  String toString() => message;
}
