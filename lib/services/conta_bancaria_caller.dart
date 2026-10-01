import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/auth_utility.dart';
import '../models/network_response.dart';
import './network_caller.dart';
import '../utils/api_links.dart';
import '../models/conta_bancaria_model.dart';

class ContaBancariaCaller {
  /// Buscar todas as contas bancárias
  Future<List<ContaBancaria>> fetchContas(BuildContext context) async {
    List<ContaBancaria> contas = [];
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.contasBancarias);
      if (response.isSuccess && response.body != null) {
        final List<dynamic> data = response.body!['data']['dados'] ?? [];
        contas = data
            .map((item) =>
                ContaBancaria.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar contas bancárias: $e');
    }
    return contas;
  }

  /// Ativar ou desativar uma conta
  Future<bool> ativarConta(int id, bool ativo) async {
    try {
      final url = '${ApiLinks.contasBancarias}/$id/ativar?ativo=$ativo';
      final NetworkResponse response =
          await NetworkCaller().patchRequest(url, {});
      return response.isSuccess;
    } catch (e) {
      debugPrint('Erro ao ativar/desativar conta: $e');
      return false;
    }
  }

  /// Ajustar saldo (inicial ou final) da conta
  Future<bool> ajustarSaldo({
    required int contaId,
    double? saldoInicial,
    double? saldoFinal,
  }) async {
    try {
      final url = '${ApiLinks.contasBancarias}/$contaId/ajustar-saldo';
      final body = <String, dynamic>{};
      if (saldoInicial != null) body['saldoInicial'] = saldoInicial;
      if (saldoFinal != null) body['saldoFinal'] = saldoFinal;
      final NetworkResponse response =
          await NetworkCaller().postRequest(url, body);
      return response.isSuccess;
    } catch (e) {
      debugPrint('Erro ao ajustar saldo: $e');
      return false;
    }
  }

  /// Transferência entre contas
  Future<bool> transferirSaldo({
    required int contaOrigemId,
    required int contaDestinoId,
    required double valor,
    required int empresaId,
    int? parceiroId,
    String? historico,
  }) async {
    try {
      final uri = Uri.parse('${ApiLinks.contasBancarias}/transferir').replace(
        queryParameters: {
          'contaOrigemId': contaOrigemId.toString(),
          'contaDestinoId': contaDestinoId.toString(),
          'valor': valor.toString(),
          'empresaId': empresaId.toString(),
          if (parceiroId != null) 'parceiroId': parceiroId.toString(),
          if (historico != null && historico.isNotEmpty) 'historico': historico,
        },
      );
      final NetworkResponse response =
          await NetworkCaller().postRequest(uri.toString(), {});
      return response.isSuccess;
    } catch (e) {
      debugPrint('Erro ao transferir saldo: $e');
      return false;
    }
  }

  /// Extrato PDF
  Future<Uint8List?> gerarExtratoPdf({
    required int contaId,
    required int empresaId,
    int? parceiroId,
    required String de,
    required String ate,
  }) async {
    try {
      final uri = Uri.parse('${ApiLinks.contasBancarias}/extrato/pdf').replace(
        queryParameters: {
          'contaId': contaId.toString(),
          'empresaId': empresaId.toString(),
          if (parceiroId != null) 'parceiroId': parceiroId.toString(),
          'de': de,
          'ate': ate,
        },
      );
      final token = AuthUtility.userInfo?.token;
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) return response.bodyBytes;
      return null;
    } catch (e) {
      debugPrint('Erro ao gerar extrato PDF: $e');
      return null;
    }
  }

  /// Evolução do saldo diário
  Future<List<Map<String, dynamic>>> evolucaoSaldoDiario(
      int contaId, int days) async {
    try {
      final url = '${ApiLinks.contasBancarias}/$contaId/evolucao?days=$days';
      final NetworkResponse response = await NetworkCaller().getRequest(url);
      if (response.isSuccess && response.body != null) {
        final body = response.body!;
        final List<dynamic> data = body is List ? body : (body['data'] ?? []);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar evolução de saldo: $e');
    }
    return [];
  }

  /// Listar saldos por empresa/parceiro
  Future<List<Map<String, dynamic>>> listarSaldos({
    required int empresaId,
    int? parceiroId,
  }) async {
    try {
      final url = '${ApiLinks.contasBancarias}/saldos'
          '?empresaId=$empresaId'
          '${parceiroId != null ? '&parceiroId=$parceiroId' : ''}';
      final NetworkResponse response = await NetworkCaller().getRequest(url);
      if (response.isSuccess && response.body != null) {
        final body = response.body!;
        final List<dynamic> data = body is List ? body : (body['data'] ?? []);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao listar saldos: $e');
    }
    return [];
  }

  /// Dropdown simplificado de contas
  static Future<List<Map<String, dynamic>>> loadContas() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.contasBancarias);
    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map((item) => {
                'value': item['id'],
                'label': '${item['banco'] ?? ''} - ${item['numero'] ?? ''}',
              })
          .toList();
    }
    return [];
  }
}
