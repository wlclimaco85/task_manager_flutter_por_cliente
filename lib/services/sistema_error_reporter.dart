import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

/// Serviço singleton para captura global e envio de erros/warnings/exceções ao backend.
class SistemaErrorReporter {
  SistemaErrorReporter._();
  static final SistemaErrorReporter instance = SistemaErrorReporter._();

  http.Client _client = http.Client();
  final List<Map<String, dynamic>> _buffer = [];
  Timer? _timerEnvio;
  final Set<String> _recentes = {};

  @visibleForTesting
  void setClient(http.Client client) {
    _client = client;
  }

  /// Inicializa os handlers globais de erro do Flutter e da plataforma.
  void inicializar() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      reportarErro(
        mensagem: details.exceptionAsString(),
        detalhes: details.stack?.toString(),
        classeOuRota: details.library ?? 'FlutterFramework',
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      reportarErro(
        mensagem: error.toString(),
        detalhes: stack.toString(),
        classeOuRota: 'PlatformDispatcher',
      );
      return false; // Não engolir o erro
    };
  }

  /// Envia ou enfileira um erro para o backend com rate limiting.
  void reportarErro({
    required String mensagem,
    String? detalhes,
    String? classeOuRota,
    String nivel = 'ERROR',
    String? usuario,
    int? empresaId,
    int? parceiroId,
  }) {
    final chave = '$nivel:$classeOuRota:$mensagem';
    if (_recentes.contains(chave)) {
      return;
    }
    _recentes.add(chave);
    if (_recentes.length > 50) {
      _recentes.clear();
    }

    final payload = <String, dynamic>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'nivel': nivel.toUpperCase(),
      'origem': 'APP_FLUTTER',
      'mensagem': mensagem.length > 1000 ? mensagem.substring(0, 1000) : mensagem,
      if (detalhes != null) 'detalhes': detalhes,
      if (classeOuRota != null) 'classeOuRota': classeOuRota,
      if (usuario != null) 'usuario': usuario,
      'empresaId': empresaId ?? TenantContext.empresaId,
      'parceiroId': parceiroId ?? TenantContext.parceiroId,
      'versaoApp': kIsWeb ? 'Web' : defaultTargetPlatform.name,
      'ambiente': kReleaseMode ? 'prod' : 'dev',
    };

    _buffer.add(payload);

    if (const bool.fromEnvironment('FLUTTER_TEST') ||
        (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))) {
      return;
    }

    _timerEnvio?.cancel();
    _timerEnvio = Timer(const Duration(milliseconds: 1500), _descarregarBuffer);
  }

  Future<void> _descarregarBuffer() async {
    if (_buffer.isEmpty) return;
    final itens = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    for (final item in itens) {
      try {
        await _client.post(
          Uri.parse(ApiLinks.sistemaLogs),
          headers: TenantContext.jsonHeaders,
          body: jsonEncode(item),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Falha ao enviar sistema_log: $e');
        }
      }
    }
  }

  @visibleForTesting
  Future<void> flushBuffer() async {
    _timerEnvio?.cancel();
    await _descarregarBuffer();
  }

  @visibleForTesting
  void reset() {
    _timerEnvio?.cancel();
    _timerEnvio = null;
    _buffer.clear();
    _recentes.clear();
  }
}
