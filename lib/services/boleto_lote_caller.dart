import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import 'session_expired_handler.dart';

class BoletoLoteItem {
  final String itemId;
  final String nomeArquivo;
  final String? documentoExtraido;
  final double? valorExtraido;
  final String? vencimentoExtraido;
  final int? parceiroIdSugerido;
  final String? parceiroNomeSugerido;
  final bool semMatch;
  final String? erro;

  int? parceiroIdConfirmado;
  double? valorConfirmado;
  String? vencimentoConfirmado;

  BoletoLoteItem({
    required this.itemId,
    required this.nomeArquivo,
    this.documentoExtraido,
    this.valorExtraido,
    this.vencimentoExtraido,
    this.parceiroIdSugerido,
    this.parceiroNomeSugerido,
    this.semMatch = false,
    this.erro,
  }) {
    parceiroIdConfirmado = parceiroIdSugerido;
    valorConfirmado = valorExtraido;
    vencimentoConfirmado = vencimentoExtraido;
  }

  factory BoletoLoteItem.fromJson(Map<String, dynamic> json) {
    return BoletoLoteItem(
      itemId: json['itemId'] ?? '',
      nomeArquivo: json['nomeArquivo'] ?? '',
      documentoExtraido: json['documentoExtraido'],
      valorExtraido: (json['valorExtraido'] as num?)?.toDouble(),
      vencimentoExtraido: json['vencimentoExtraido'],
      parceiroIdSugerido: json['parceiroIdSugerido'] as int?,
      parceiroNomeSugerido: json['parceiroNomeSugerido'],
      semMatch: json['semMatch'] == true,
      erro: json['erro'],
    );
  }
}

class BoletoLoteCaller {
  static Map<String, String> get _authHeaders {
    final headers = Map<String, String>.from(TenantContext.headers);
    final token = AuthUtility.userInfo?.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<String?> iniciarLote() async {
    try {
      final url = TenantContext.applyToUrl(ApiLinks.boletoLoteIniciar);
      final response = await http.post(
        Uri.parse(url),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['loteId'] as String?;
      }
      if (response.statusCode == 401) {
        await SessionExpiredHandler.handle();
      }
    } catch (_) {}
    return null;
  }

  static Future<List<BoletoLoteItem>> enviarArquivos(
    String loteId,
    List<PlatformFile> arquivos,
  ) async {
    try {
      final url =
          TenantContext.applyToUrl(ApiLinks.boletoLoteArquivos(loteId));
      final token = AuthUtility.userInfo?.token;

      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      for (final arq in arquivos) {
        Uint8List bytes;
        if (arq.bytes != null) {
          bytes = arq.bytes!;
        } else if (arq.path != null) {
          bytes = await File(arq.path!).readAsBytes();
        } else {
          continue;
        }
        request.files.add(http.MultipartFile.fromBytes(
          'arquivos',
          bytes,
          filename: arq.name,
        ));
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        final list = jsonDecode(body) as List;
        return list
            .map((e) => BoletoLoteItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (streamed.statusCode == 401) {
        await SessionExpiredHandler.handle();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> confirmar(
    String loteId,
    List<BoletoLoteItem> itens,
  ) async {
    try {
      final url =
          TenantContext.applyToUrl(ApiLinks.boletoLoteConfirmar(loteId));
      final confirmacoes = itens
          .where((i) => i.parceiroIdConfirmado != null)
          .map((i) => {
                'itemId': i.itemId,
                'parceiroId': i.parceiroIdConfirmado,
                if (i.valorConfirmado != null) 'valor': i.valorConfirmado,
                if (i.vencimentoConfirmado != null)
                  'vencimento': i.vencimentoConfirmado,
              })
          .toList();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          ..._authHeaders,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'confirmacoes': confirmacoes}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        await SessionExpiredHandler.handle();
      }
    } catch (_) {}
    return null;
  }
}
