import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/billing_charge_model.dart';
import '../models/conta_receber_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class BillingChargeService {
  Future<BillingChargeResult> generateFromContaReceber({
    required ContaReceber conta,
    required BillingChargeType type,
  }) async {
    final contaId = conta.id;
    if (contaId == null) {
      throw const BillingChargeException(
        'Conta a receber sem ID para gerar cobrança.',
      );
    }

    final empresaId = conta.empresa.id ?? TenantContext.empresaId;
    if (empresaId == null) {
      throw const BillingChargeException(
        'Empresa não identificada para gerar a cobrança.',
      );
    }

    final response = await http.post(
      Uri.parse(
        TenantContext.applyToUrl(
          ApiLinks.contaReceberCobrancas(contaId.toString()),
        ),
      ),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        'empresaId': empresaId,
        'tipoCobranca': type.apiValue,
        if (conta.formaPagamento?.id != null)
          'formaPagamentoId': conta.formaPagamento!.id,
      }),
    );

    return _parseSingleResponse(
      response,
      defaultMessage: 'Erro ao gerar cobrança financeira.',
    );
  }

  Future<List<BillingChargeResult>> listByContaReceber({
    required int contaReceberId,
    int? empresaId,
  }) async {
    final response = await http.get(
      Uri.parse(
        TenantContext.applyToUrl(
          ApiLinks.contaReceberCobrancas(contaReceberId.toString()) +
              _buildEmpresaQuery(empresaId),
        ),
      ),
      headers: TenantContext.jsonHeaders,
    );

    final body = _decodeBody(response.bodyBytes);
    if (response.statusCode == 200) {
      if (body is List) {
        return body
            .whereType<Map>()
            .map(
              (item) => BillingChargeResult.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      return const [];
    }

    throw BillingChargeException(
      _extractErrorMessage(body) ??
          'Erro ao consultar cobranças financeiras (${response.statusCode}).',
    );
  }

  Future<BillingChargeResult> consultCharge({
    required String billingId,
    int? empresaId,
  }) async {
    final response = await http.get(
      Uri.parse(
        TenantContext.applyToUrl(
          ApiLinks.contaReceberCobranca(billingId) +
              _buildEmpresaQuery(empresaId),
        ),
      ),
      headers: TenantContext.jsonHeaders,
    );

    return _parseSingleResponse(
      response,
      defaultMessage: 'Erro ao consultar a cobrança.',
    );
  }

  Future<List<BillingChargeResult>> listReminderQueue({int? empresaId}) async {
    final response = await http.get(
      Uri.parse(
        TenantContext.applyToUrl(
          ApiLinks.contaReceberCobrancasReguaPendentes +
              _buildEmpresaQuery(empresaId),
        ),
      ),
      headers: TenantContext.jsonHeaders,
    );

    final body = _decodeBody(response.bodyBytes);
    if (response.statusCode == 200) {
      if (body is List) {
        return body
            .whereType<Map>()
            .map(
              (item) => BillingChargeResult.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      return const [];
    }

    throw BillingChargeException(
      _extractErrorMessage(body) ??
          'Erro ao consultar régua de cobrança (${response.statusCode}).',
    );
  }

  Future<BillingChargeResult> markReminderSent({
    required String billingId,
    int? empresaId,
    String canalEnvio = 'EMAIL',
  }) async {
    final response = await http.post(
      Uri.parse(
        TenantContext.applyToUrl(
          ApiLinks.marcarEnvioReguaContaReceberCobranca(billingId),
        ),
      ),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        if (empresaId != null || TenantContext.empresaId != null)
          'empresaId': empresaId ?? TenantContext.empresaId,
        'canalEnvio': canalEnvio,
        'observacao': 'Envio da régua registrado pelo usuário.',
      }),
    );

    return _parseSingleResponse(
      response,
      defaultMessage: 'Erro ao registrar envio da régua.',
    );
  }

  BillingChargeResult _parseSingleResponse(
    http.Response response, {
    required String defaultMessage,
  }) {
    final body = _decodeBody(response.bodyBytes);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body is Map<String, dynamic>) {
        return BillingChargeResult.fromJson(body);
      }
      if (body is Map) {
        return BillingChargeResult.fromJson(Map<String, dynamic>.from(body));
      }
      throw const BillingChargeException(
        'A API retornou uma resposta inválida ao processar a cobrança.',
      );
    }

    throw BillingChargeException(
      _extractErrorMessage(body) ?? '$defaultMessage (${response.statusCode}).',
    );
  }

  dynamic _decodeBody(List<int> bytes) {
    if (bytes.isEmpty) return null;
    final raw = utf8.decode(bytes).trim();
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  String? _extractErrorMessage(dynamic body) {
    if (body == null) return null;
    if (body is String && body.trim().isNotEmpty) return body.trim();
    if (body is Map) {
      final directMessage = body['message'] ?? body['error'] ?? body['detail'];
      if (directMessage != null && directMessage.toString().trim().isNotEmpty) {
        return directMessage.toString().trim();
      }

      final response = body['response'];
      if (response is Map) {
        final nestedMessage =
            response['message'] ?? response['error'] ?? response['detail'];
        if (nestedMessage != null &&
            nestedMessage.toString().trim().isNotEmpty) {
          return nestedMessage.toString().trim();
        }
      }
    }
    return null;
  }

  String _buildEmpresaQuery(int? empresaId) {
    final effectiveEmpresaId = empresaId ?? TenantContext.empresaId;
    if (effectiveEmpresaId == null) return '';
    return '?empresaId=$effectiveEmpresaId';
  }
}
