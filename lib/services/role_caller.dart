import 'package:task_manager_flutter/models/role_model.dart'; // Ajuste o caminho conforme necessário
import 'package:task_manager_flutter/utils/api_links.dart'; // Onde definiremos as URLs
import 'package:task_manager_flutter/models/network_response.dart';
import 'package:task_manager_flutter/services/network_caller.dart';

import 'package:task_manager_flutter/utils/app_logger.dart';

class RoleCaller {
  static List<Role> parseRolesResponse(dynamic body) {
    dynamic rawList = body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        rawList = data['dados'];
      } else if (data is List) {
        rawList = data;
      } else {
        rawList = body['dados'];
      }
    }

    if (rawList is! List) return [];
    return rawList
        .whereType<Map>()
        .map((item) => Role.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Role>> getRoles() async {
    final roles = <Role>[];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.getAllRoles,
      );

      if (response.statusCode == 200 && response.body != null) {
        roles.addAll(parseRolesResponse(response.body));
      } else {
        throw Exception('Falha ao carregar roles: ${response.statusCode}');
      }
    } catch (e) {
      L.d('Erro: $e');
      throw Exception('Erro ao carregar roles: $e');
    }
    return roles;
  }

  Future<List<Role>> fetchRolesDoLogin(int loginId) async {
    List<Role> roles = [];
    try {
      final response =
          await NetworkCaller().getRequest(ApiLinks.getRolesLoginId(loginId));
      if (response.isSuccess && response.body != null) {
        final dynamic body = response.body;
        // Lida com { data: { dados: [...] } } (Response customizado) e outras variações comuns
        List<dynamic> dataList = [];
        if (body is Map<String, dynamic>) {
          if (body.containsKey('data') &&
              body['data'] is Map<String, dynamic> &&
              body['data'].containsKey('dados')) {
            dataList = body['data']['dados'];
          } else if (body.containsKey('data') && body['data'] is List) {
            dataList = body['data'];
          } else if (body.containsKey('dados') && body['dados'] is List) {
            dataList = body['dados'];
          }
        } else if (body is List) {
          dataList = List<dynamic>.from(body);
        }

        roles = dataList
            .map((r) => Role.fromJson(r as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Falha ao carregar roles do login: ');
      }
    } catch (e) {
      L.d('Erro ao buscar roles do login: ');
      throw Exception('Erro ao carregar roles do login: ');
    }
    return roles;
  }

  Future<bool> atualizarRolesDoLogin(int loginId, List<int> roleIds) async {
    try {
      final response = await NetworkCaller().putRequest(
        ApiLinks.updateRolesLoginId(loginId),
        roleIds,
      );
      return response.isSuccess;
    } catch (e) {
      L.d('Erro ao atualizar roles do login: ');
      return false;
    }
  }

  Future<bool> associateRoleToLogin(int loginId, int roleId) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.associateRoleToLogin(loginId, roleId),
        {"roleid": roleId},
        // Como é uma associação, não enviamos body, mas se a API exigir, ajuste aqui.
        // No exemplo, o endpoint é POST e não tem body.
      );

      if (response.isSuccess) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      L.d('Erro: $e');
      return false;
    }
  }

  Future<bool> removeRoleFromLogin(int loginId, int roleId) async {
    try {
      final NetworkResponse response = await NetworkCaller().deleteRequest(
        ApiLinks.removeRoleFromLogin(loginId, roleId),
      );

      if (response.isSuccess) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      L.d('Erro: $e');
      return false;
    }
  }

  /// Busca roles disponíveis filtradas por módulos contratados
  /// da empresa/parceiro informado.
  ///
  /// @param empresaId ID da empresa (prioridade baixa)
  /// @param parceiroId ID do parceiro (prioridade alta)
  /// @return List<Role> contendo apenas roles compatíveis
  Future<List<Role>> getRolesDisponiveis({
    int? empresaId,
    int? parceiroId,
  }) async {
    List<Role> roles = [];
    try {
      String url = ApiLinks.rolesDisponiveis;

      // Monta query string
      List<String> params = [];
      if (empresaId != null) params.add('empresaId=$empresaId');
      if (parceiroId != null) params.add('parceiroId=$parceiroId');
      if (params.isNotEmpty) url += '?' + params.join('&');

      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.statusCode == 200 && response.body != null) {
        // Resposta é List<Role> direto, não envolvida em "data"
        final body = response.body;
        List<dynamic> data = body is List ? body as List<dynamic> : [body];
        roles =
            data.map((r) => Role.fromJson(r as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 403) {
        // Anti-IDOR: usuário não tem acesso ao tenant informado
        throw Exception('Sem acesso ao tenant (403)');
      } else {
        throw Exception('Falha ao carregar roles: ${response.statusCode}');
      }
    } catch (e) {
      L.d('Erro ao buscar roles disponíveis: $e');
      // Fallback: não bloqueia, retorna vazio
      return [];
    }
    return roles;
  }
}
