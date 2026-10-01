import 'dart:convert';

import '../models/defaults_importacao_empresa_model.dart';
import '../utils/api_links.dart';
import '../utils/dropdown_helpers.dart';
import '../utils/tenant_context.dart';

/// Erro ao buscar/salvar defaults financeiros de importação.
class DefaultsImportacaoException implements Exception {
  final String message;
  final int statusCode;

  const DefaultsImportacaoException(this.message, {this.statusCode = -1});

  @override
  String toString() => 'DefaultsImportacaoException($statusCode): $message';
}

/// Serviço responsável pelas chamadas HTTP de defaults financeiros de
/// importação (Sistema > Config de Sistemas > Defaults de Importação).
///
/// Os dropdowns de conta bancária/caixa e centro de custo reaproveitam os
/// mesmos endpoints já usados pelo resto do app (ver
/// [DropdownHelpers.contasBancariasPorEmpresa] e
/// [DropdownHelpers.centrosCustoPorEmpresa]) — nenhuma chamada nova foi
/// criada para popular essas listas.
class DefaultsImportacaoService {
  Future<DefaultsImportacaoEmpresa> buscar(int empresaId) async {
    final resp = await TenantContext.get(
        '${ApiLinks.baseUrl}/api/defaults-importacao/$empresaId');
    if (resp.statusCode == 200) {
      return DefaultsImportacaoEmpresa.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>);
    }
    throw DefaultsImportacaoException(
        'Falha ao carregar defaults de importação (HTTP ${resp.statusCode})',
        statusCode: resp.statusCode);
  }

  Future<DefaultsImportacaoEmpresa> salvar(
      int empresaId, DefaultsImportacaoEmpresa dados) async {
    final resp = await TenantContext.put(
        '${ApiLinks.baseUrl}/api/defaults-importacao/$empresaId',
        dados.toRequestJson());
    if (resp.statusCode == 200) {
      return DefaultsImportacaoEmpresa.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>);
    }
    throw DefaultsImportacaoException(
        'Falha ao salvar defaults de importação (HTTP ${resp.statusCode})',
        statusCode: resp.statusCode);
  }

  Future<List<Map<String, dynamic>>> empresas() => DropdownHelpers.empresas();

  Future<List<Map<String, dynamic>>> contasBancarias(String? empresaId) =>
      DropdownHelpers.contasBancariasPorEmpresa(empresaId);

  Future<List<Map<String, dynamic>>> contasCaixa(String? empresaId) =>
      DropdownHelpers.contasBancariasPorEmpresa(empresaId, apenasCaixa: true);

  Future<List<Map<String, dynamic>>> centrosCusto(String? empresaId) =>
      DropdownHelpers.centrosCustoPorEmpresa(empresaId);
}
