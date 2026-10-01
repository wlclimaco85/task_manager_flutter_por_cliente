// Interceptador para adicionar token JWT e tratar erros 401 (logout automático)
import 'package:dio/dio.dart';
import 'package:task_manager_flutter/services/auth_service.dart';
import 'package:task_manager_flutter/services/session_expired_handler.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

class AuthInterceptor extends Interceptor {
  final AuthService authService = AuthService();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Adiciona token JWT ao header Authorization
    final token = await authService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Se receber 401 (Unauthorized), faz logout automático
    if (err.response?.statusCode == 401) {
      L.w('[AuthInterceptor] 401 Unauthorized — iniciando logout automático');

      // Usa SessionExpiredHandler para fazer logout de forma consistente
      await SessionExpiredHandler.handle();

      return handler.reject(err);
    }

    return handler.next(err);
  }
}
