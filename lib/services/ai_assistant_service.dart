import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_assistant_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class AiAssistantService {
  Future<ChatSummaryResult> summarizeChat({
    String? chatId,
    List<String> messages = const [],
    String? text,
  }) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.aiChatSummarize)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        if (TenantContext.empresaId != null)
          'tenantId': TenantContext.empresaId.toString(),
        if (chatId != null) 'chatId': chatId,
        if (messages.isNotEmpty) 'messages': messages,
        if (text != null) 'text': text,
      }),
    );

    return ChatSummaryResult.fromJson(
      _parseMap(response, 'Erro ao resumir atendimento.'),
    );
  }

  Future<TextCorrectionResult> correctMessage({
    required String text,
    String tone = 'profissional',
  }) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.aiTextCorrect)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        if (TenantContext.empresaId != null)
          'tenantId': TenantContext.empresaId.toString(),
        'text': text,
        'tone': tone,
      }),
    );

    return TextCorrectionResult.fromJson(
      _parseMap(response, 'Erro ao corrigir mensagem.'),
    );
  }

  Future<DocumentClassificationResult> classifyDocument({
    String? fileName,
    String? fileType,
    String? description,
    String? content,
  }) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.aiGedClassify)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        if (TenantContext.empresaId != null)
          'tenantId': TenantContext.empresaId.toString(),
        if (fileName != null) 'fileName': fileName,
        if (fileType != null) 'fileType': fileType,
        if (description != null) 'description': description,
        if (content != null) 'content': content,
      }),
    );

    return DocumentClassificationResult.fromJson(
      _parseMap(response, 'Erro ao classificar documento.'),
    );
  }

  Map<String, dynamic> _parseMap(http.Response response, String message) {
    final body = response.bodyBytes.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
    }
    throw AiAssistantException(_extractErrorMessage(body) ?? message);
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

class AiAssistantException implements Exception {
  final String message;

  const AiAssistantException(this.message);

  @override
  String toString() => message;
}
