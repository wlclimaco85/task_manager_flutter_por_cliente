import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/auth_utility.dart';
import '../models/network_response.dart';
import './network_caller.dart';
import '../utils/api_links.dart';
import '../models/ponto_model.dart';

class PontoCaller {
  /// Registrar entrada ou saída
  Future<PontoModel?> registrarPonto(
    BuildContext context, {
    required TipoRegistro tipo,
    String? observacao,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final login = AuthUtility.userInfo?.login;

      final Map<String, dynamic> body = {
        "login": {"id": login?.id},
        "empresa": {"id": login?.empresa?.id},
        if (login?.parceiro != null) "parceiro": {"id": login?.parceiro?.id},
        "tipo": tipo.apiValue,
        if (observacao != null && observacao.isNotEmpty)
          "observacao": observacao,
        if (latitude != null) "latitude": latitude,
        if (longitude != null) "longitude": longitude,
      };

      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.pontoRegistrar,
        body,
      );

      if (response.statusCode == 200 && response.body != null) {
        return PontoModel.fromJson(response.body!);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao registrar ponto: $e');
      return null;
    }
  }

  /// Listar marcações do dia
  Future<List<PontoModel>> listarPorDia({required DateTime data}) async {
    try {
      final String d = data.toIso8601String().split("T")[0];
      final int? loginId = AuthUtility.userInfo?.login?.id;
      if (loginId == null) return [];

      final NetworkResponse response = await NetworkCaller().getRequest(
        "${ApiLinks.pontoListar}/$loginId?data=$d",
      );

      if (response.statusCode == 200 && response.body != null) {
        final List lista = (response.body!["data"] as List<dynamic>).toList();
        return lista.map((e) => PontoModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao listar pontos: $e');
      return [];
    }
  }

  /// Calcular banco de horas
  Future<double> calcularBancoHoras({required DateTime mes}) async {
    try {
      final mesStr = mes.toIso8601String().split("T")[0];
      final int? loginId = AuthUtility.userInfo?.login?.id;
      if (loginId == null) return 0;

      final NetworkResponse response = await NetworkCaller().getRequest(
        "${ApiLinks.pontoBancoHoras}/$loginId?mesReferencia=$mesStr",
      );

      if (response.statusCode == 200 && response.body != null) {
        return double.tryParse(response.body.toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Erro ao calcular banco de horas: $e');
      return 0;
    }
  }

  /// Gerar PDF do ponto
  Future<Uint8List?> gerarPdf({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    try {
      final i = inicio.toIso8601String().split("T")[0];
      final f = fim.toIso8601String().split("T")[0];
      final String? token = AuthUtility.userInfo?.token;
      final loginId = AuthUtility.userInfo?.login?.id;
      final uri = Uri.parse("${ApiLinks.pontoPdf}/$loginId?inicio=$i&fim=$f");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) return response.bodyBytes;
      return null;
    } catch (e) {
      debugPrint('Erro ao gerar PDF do ponto: $e');
      return null;
    }
  }
}

/// Wrapper estático simplificado para uso na PontoScreen (sem riverpod)
class PontoService {
  static final _caller = PontoCaller();

  /// Registra ponto automático (alterna entrada/saída)
  static Future<bool> registrarPonto(int loginId,
      {double? latitude, double? longitude, double? lat, double? lng}) async {
    // Usa BuildContext fake — registra como ENTRADA por padrão
    // A lógica de alternância fica no backend
    final latReal = latitude ?? lat;
    final lngReal = longitude ?? lng;
    try {
      final login = AuthUtility.userInfo?.login;
      final body = {
        "login": {"id": login?.id},
        "empresa": {"id": login?.empresa?.id},
        if (login?.parceiro != null) "parceiro": {"id": login?.parceiro?.id},
        "tipo": "ENTRADA",
        if (latReal != null) "latitude": latReal,
        if (lngReal != null) "longitude": lngReal,
      };
      final response =
          await NetworkCaller().postRequest(ApiLinks.pontoRegistrar, body);
      return response.isSuccess;
    } catch (_) {
      return false;
    }
  }

  /// Lista pontos do dia atual
  static Future<List<PontoModel>> listarPontos(int loginId) async {
    return _caller.listarPorDia(data: DateTime.now());
  }

  /// Gera PDF do mês atual
  static Future<Uint8List?> gerarPdf(int loginId) async {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, 1);
    final fim = DateTime(now.year, now.month + 1, 0);
    return _caller.gerarPdf(inicio: inicio, fim: fim);
  }

  /// Gera PDF de um mês e ano específicos
  static Future<Uint8List?> gerarEspelhoPdf(
      int loginId, int mes, int ano) async {
    final inicio = DateTime(ano, mes, 1);
    final fim = DateTime(ano, mes + 1, 0);
    return _caller.gerarPdf(inicio: inicio, fim: fim);
  }

  /// Banco de horas do mês atual
  static Future<double?> bancoHoras(int loginId) async {
    return _caller.calcularBancoHoras(mes: DateTime.now());
  }

  static Future<List<Map<String, dynamic>>> relatorioAbsenteismo(
      int mes, int ano) async {
    final inicio = DateTime(ano, mes, 1);
    final fim = DateTime(ano, mes + 1, 0);
    final i = inicio.toIso8601String().split("T")[0];
    final f = fim.toIso8601String().split("T")[0];
    try {
      final response = await NetworkCaller().getRequest(
          "${ApiLinks.baseUrl}/api/ponto/absenteismo?dataInicio=$i&dataFim=$f");
      if (response.statusCode == 200 && response.body != null) {
        final List lista = (response.body! as List<dynamic>).toList();
        return lista.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (_) {}
    return [];
  }
}
