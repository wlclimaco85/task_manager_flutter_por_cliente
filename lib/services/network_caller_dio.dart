// network_caller.dart
import 'package:dio/dio.dart';
import 'package:task_manager_flutter/models/network_response_dio.dart';
import 'package:task_manager_flutter/services/auth_interceptor.dart';

class NetworkCaller {
  static final Dio _dio = _initializeDio();

  static Dio _initializeDio() {
    final dio = Dio();
    dio.interceptors.add(AuthInterceptor());
    return dio;
  }

  NetworkCaller();

  Dio get dio => _dio;

  Future<NetworkResponseDio> multipartRequestWithDio(
    String url,
    String filePath, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
        ...data ?? {},
      });

      Response response = await _dio.post(
        url,
        data: formData,
        options: Options(headers: headers),
      );

      return NetworkResponseDio(
        statusCode: response.statusCode,
        body: response.data,
      );
    } on DioException catch (e) {
      return NetworkResponseDio(
        statusCode: e.response?.statusCode,
        errorMessage: e.message,
      );
    }
  }
}
