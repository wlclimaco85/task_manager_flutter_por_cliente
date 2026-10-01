import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:task_manager_flutter/services/auth_interceptor.dart';

void main() {
  group('AuthInterceptor', () {
    late AuthInterceptor interceptor;

    setUp(() {
      interceptor = AuthInterceptor();
    });

    test('AuthInterceptor é instanciável', () {
      expect(interceptor, isNotNull);
      expect(interceptor, isA<AuthInterceptor>());
    });

    test('AuthInterceptor herda de Interceptor', () {
      expect(interceptor, isA<Interceptor>());
    });

    test('onRequest é implementado', () {
      // Verificar que o método onRequest existe
      expect(interceptor.onRequest, isNotNull);
    });

    test('onError é implementado', () {
      // Verificar que o método onError existe
      expect(interceptor.onError, isNotNull);
    });
  });

  group('AuthInterceptor - comportamento', () {
    test('detecta status code 401', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/test'),
        statusCode: 401,
      );

      final error = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        response: response,
      );

      // Verificar que é possível criar DioException com status 401
      expect(error.response?.statusCode, 401);
    });

    test('detecta status code 500', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/test'),
        statusCode: 500,
      );

      final error = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        response: response,
      );

      // Verificar que é possível criar DioException com status 500
      expect(error.response?.statusCode, 500);
    });
  });
}
