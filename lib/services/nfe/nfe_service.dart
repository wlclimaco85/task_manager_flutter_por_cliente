import 'dart:async';

import 'package:dio/dio.dart';
import 'package:task_manager_flutter/models/nfe/nfe_transmissao_response.dart';
import 'package:task_manager_flutter/services/nfe/nfe_service_exception.dart';

/// Callback para logging estruturado
typedef LogCallback = void Function(String message);

/// Serviço de transmissão de NFe com retry automático.
///
/// Responsabilidades principais:
/// - Transmitir NFe para backend (POST /api/nfe/transmissoes/{rpsId})
/// - Retry automático com exponential backoff (500ms → 1s → 2s)
/// - Tratamento de timeouts (15s padrão)
/// - Logging estruturado de tentativas
/// - Diferenciação de erros retentáveis vs não-retentáveis
///
/// Exemplo:
/// ```dart
/// final response = await nfeService.transmitirNfe(
///   nfeId: '123',
///   rpsId: '456',
///   maxRetries: 2,
///   timeout: Duration(seconds: 15),
/// );
/// ```
class NFeService {
  final Dio dio;
  late LogCallback _onLog;

  /// Configurações de retry
  static const Duration _backoffInitial = Duration(milliseconds: 500);
  static const double _backoffMultiplier = 2.0;
  static const Duration _timeoutDefault = Duration(seconds: 15);
  static const int _maxRetriesDefault = 2;

  NFeService({
    required this.dio,
    LogCallback? onLog,
  }) {
    _onLog = onLog ?? _defaultLog;
  }

  /// Callback para logging (getter)
  LogCallback get onLog => _onLog;

  /// Callback para logging (setter — pode ser sobrescrito em testes)
  set onLog(LogCallback callback) {
    _onLog = callback;
  }

  /// Transmitir NFe para SEFAZ via backend com retry automático.
  ///
  /// Implementa retry automático com exponential backoff para timeout e erros 5xx.
  /// Erros 4xx retornam imediatamente sem retry.
  ///
  /// Parâmetros:
  /// - `nfeId`: ID da NFe no banco de dados local (string)
  /// - `rpsId`: ID da RPS para transmissão (string)
  /// - `maxRetries`: Máximo de retentativas (padrão: 2). Total de tentativas = 1 + maxRetries
  /// - `timeout`: Timeout para cada tentativa HTTP (padrão: 15 segundos)
  ///
  /// Retorna:
  /// - [NfeTransmissaoResponse] contendo protocolo SEFAZ, status e timestamp
  ///
  /// Lança:
  /// - [NFeServiceException] se falhar após retries esgotados
  ///
  /// Logging:
  /// - Registra tentativa inicial, retries e resultado final
  /// - Segue formato: contexto (nfeId, tentativa, timeout)
  Future<NfeTransmissaoResponse> transmitirNfe({
    required String nfeId,
    required String rpsId,
    int maxRetries = _maxRetriesDefault,
    Duration timeout = _timeoutDefault,
  }) async {
    _log('Iniciando transmissão NFe (nfeId=$nfeId, rpsId=$rpsId, maxRetries=$maxRetries, timeout=${timeout.inSeconds}s)');

    int tentativa = 0;
    NFeServiceException? ultimoErro;

    while (tentativa <= maxRetries) {
      try {
        tentativa++;
        _log('Transmissão tentativa $tentativa/${maxRetries + 1} (nfeId=$nfeId)');

        final response = await _transmitirComTimeout(
          nfeId: nfeId,
          rpsId: rpsId,
          timeout: timeout,
        );

        _log('Transmissão sucesso (nfeId=$nfeId, protocolo=${response.protocolo}, tentativa=$tentativa)');
        return response;
      } on DioException catch (e) {
        ultimoErro = _handleDioException(e, nfeId, tentativa);

        // Não faz retry em erros 4xx (exceto timeout/connection)
        final isClientError = _isClientError(e);
        if (isClientError) {
          _log('Erro cliente não-retentável (nfeId=$nfeId, status=${e.response?.statusCode}, tentativa=$tentativa)');
          throw ultimoErro;
        }

        // Faz retry para timeouts e 5xx
        if (tentativa <= maxRetries) {
          final delayMs = _calcularBackoff(tentativa - 1);
          _log('Retry agendado (nfeId=$nfeId, tentativa=$tentativa, delayMs=$delayMs)');
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      } catch (e, stackTrace) {
        _log('Erro inesperado (nfeId=$nfeId, tentativa=$tentativa): $e');
        throw NFeServiceException(
          'Erro inesperado durante transmissão: $e',
          originalException: e,
        );
      }
    }

    // Esgotou retries
    _log('Transmissão falhou após $tentativa tentativas (nfeId=$nfeId)');
    throw ultimoErro ?? NFeServiceException('Falha ao transmitir NFe após $tentativa tentativas');
  }

  /// Transmitir com timeout configurado
  Future<NfeTransmissaoResponse> _transmitirComTimeout({
    required String nfeId,
    required String rpsId,
    required Duration timeout,
  }) async {
    final url = '/api/nfe/transmissoes/$rpsId';
    final options = Options(
      receiveTimeout: timeout,
      sendTimeout: timeout,
      connectTimeout: timeout,
    );

    final response = await dio.post(
      url,
      data: {'nfeId': nfeId},
      options: options,
    );

    if (response.statusCode == 200 || response.statusCode == 202) {
      return NfeTransmissaoResponse.fromJson(response.data as Map<String, dynamic>);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      message: 'Status ${response.statusCode}: ${response.data}',
    );
  }

  /// Calcular delay com exponential backoff
  /// - Tentativa 0: 500ms
  /// - Tentativa 1: 1000ms (500 * 2)
  /// - Tentativa 2: 2000ms (1000 * 2)
  int _calcularBackoff(int tentativaPrecedente) {
    final baseMs = _backoffInitial.inMilliseconds.toDouble();
    // Exponential backoff: baseMs * (2 ^ tentativaPrecedente)
    double delayMs = baseMs;
    for (int i = 0; i < tentativaPrecedente; i++) {
      delayMs *= _backoffMultiplier;
    }
    return delayMs.toInt();
  }

  /// Verificar se erro é do cliente (4xx, exceto timeout)
  bool _isClientError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return false; // Timeout é retentável
    }

    final statusCode = e.response?.statusCode;
    return statusCode != null && statusCode >= 400 && statusCode < 500;
  }

  /// Converter DioException para mensagem amigável
  String _descricaoErro(DioException e) {
    final statusCode = e.response?.statusCode;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Timeout ao conectar SEFAZ';
    }

    return switch (statusCode) {
      400 => 'Dados inválidos',
      401 => 'Não autorizado (credenciais inválidas)',
      403 => 'Acesso negado',
      404 => 'Endpoint não encontrado',
      502 || 503 => 'Backend indisponível',
      _ => 'Erro HTTP ${statusCode ?? "desconhecido"}',
    };
  }

  /// Tratamento de DioException (converter para NFeServiceException)
  NFeServiceException _handleDioException(
    DioException e,
    String nfeId,
    int tentativa,
  ) {
    final statusCode = e.response?.statusCode;
    final descricao = _descricaoErro(e);

    _log('DioException (nfeId=$nfeId, tentativa=$tentativa, status=$statusCode): $descricao');

    return NFeServiceException(
      descricao,
      statusCode: statusCode,
      originalException: e,
    );
  }

  /// Log estruturado
  void _log(String message) {
    _onLog(message);
  }

  /// Logger padrão (pode ser substituído em testes)
  static void _defaultLog(String message) {
    // No production, usar logger real (ex: logger package)
    // Por enquanto, silencioso
  }
}
