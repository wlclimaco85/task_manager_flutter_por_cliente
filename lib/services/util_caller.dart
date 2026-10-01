import 'package:flutter/material.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../models/auth_utility.dart';
import '../../mobile/screens/LoginPopup_screens.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class UtilCaller {
  Future<List<T>> fetchData<T>({
    required BuildContext context,
    required String apiEndpoint,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    List<T> items = [];
    try {
      // Check user authentication
      if (AuthUtility.userInfo?.data?.id == 1) {
        // AQUI CHAMAR O LOGIN
        await showDialog(
          context: context,
          builder: (BuildContext context) => const LoginPopup(),
        );
      } else {
        // Perform network request
        final NetworkResponse response =
            await NetworkCaller().getRequests(apiEndpoint, context);

        if (response.statusCode == 200 && response.body != null) {
          final List<dynamic> responseData = response.body?['data']['account'];
          items = responseData
              .map((item) => fromJson(Map<String, dynamic>.from(item)))
              .toList();
        } else if (response.statusCode == 403) {
          // AQUI CHAMAR O LOGIN
          await showDialog(
            context: context,
            builder: (BuildContext context) => const LoginPopup(),
          );
        } else {
          L.d(
              'Erro: Nenhum dado retornado. Status Code: ${response.statusCode}');
        }
      }
    } catch (e) {
      L.d('Erro ao carregar dados: $e');
      throw Exception('Erro ao carregar dados: $e');
    }
    return items;
  }
}
