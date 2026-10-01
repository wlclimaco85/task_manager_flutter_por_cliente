import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/parceiro_model.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../models/auth_utility.dart';
import '../../mobile/screens/LoginPopup_screens.dart';
import '../../../utils/utils.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class ParceiroCaller {
  Future<List<Parceiro>> fetchParceiros(
    BuildContext context,
    int idParceiro,
  ) async {
    List<Parceiro>? model = [];
    ParceiroModel models;
    try {
      if (AuthUtility.userInfo?.data?.id != null &&
          AuthUtility.userInfo?.data?.id == 1) {
        // AQUI CHAMAR O LOGIN
        await showDialog(
          context: context,
          builder: (BuildContext context) => const LoginPopup(),
        );
      } else {
        final NetworkResponse response = await NetworkCaller().getRequest(
          '${ApiLinks.parceiroById}/$idParceiro',
        );
        String jsonString;

        if (response.statusCode == 200 && response.body != null) {
          jsonString = json.encode(response.body);
          models = ParceiroModel.fromJson(response.body!);
          model.addAll(models.parceiros ?? []);
        } else {
          // Trate o caso onde o data é nulo
        }
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  Future<bool> insertParceiro(
    BuildContext context,
    Map<String, dynamic> parceiroData,
  ) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.insertParceiro,
        parceiroData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Analisar o JSON retornado para verificar se contém erros
        final Map<String, dynamic> responseBody =
            response.body as Map<String, dynamic>;
        final responseError = responseBody['response']['error'] as bool?;
        final responseMessage = responseBody['response']['message'];
        String sanitizedMessage = responseMessage != null
            ? utf8.decode(responseMessage.runes.toList())
            : "Erro desconhecido.";

        if (responseError == true) {
          // Mostra a mensagem de erro do servidor
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sanitizedMessage),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        L.d("Parceiro inserido com sucesso.");
        return true;
      } else {
        L.d("Erro ao inserir parceiro: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao inserir parceiro: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      L.d('Erro ao inserir parceiro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao inserir parceiro: $e"),
          backgroundColor: Colors.red,
        ),
      );
      throw Exception('Erro ao inserir parceiro: $e');
    }
  }

  Future<bool> updateParceiro(
    BuildContext context,
    Map<String, dynamic> parceiroData,
  ) async {
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.updateParceiro(parceiroData['id'].toString()),
        parceiroData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Analisar o JSON retornado para verificar se contém erros
        final Map<String, dynamic> responseBody =
            response.body as Map<String, dynamic>;
        final responseError = responseBody['response']['error'] as bool?;
        final responseMessage = responseBody['response']['message'];
        String sanitizedMessage = responseMessage != null
            ? utf8.decode(responseMessage.runes.toList())
            : "Erro desconhecido.";

        if (responseError == true) {
          // Mostra a mensagem de erro do servidor
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sanitizedMessage),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sanitizedMessage),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        L.d("Erro ao inserir parceiro: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao inserir parceiro: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      L.d('Erro ao inserir parceiro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao inserir parceiro: $e"),
          backgroundColor: Colors.red,
        ),
      );
      throw Exception('Erro ao inserir parceiro: $e');
    }
  }

  /// Busca todos os parceiros
  Future<List<Parceiro>> fetchParceiross() async {
    List<Parceiro> list = [];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allParceirosPorEmp(pegarEmpresaLogada().toString()),
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']['dados'] ?? [];
        list = data.map<Parceiro>((item) => Parceiro.fromJson(item)).toList();
      }
    } catch (e) {
      L.d('Erro ao carregar parceiros: $e');
      throw Exception('Erro ao carregar parceiros: $e');
    }
    return list;
  }

  /// Retorna lista formatada para dropdown de parceiros (value = id simples)
  Future<List<Map<String, dynamic>>> fetchParceiroDropdown() async {
    return _fetchParceiroList(
      toMap: (item) => {'value': item['id'], 'label': item['nome']?.toString() ?? ''},
    );
  }

  /// Retorna lista para dropdown onde value = objeto {id, nome} completo.
  /// Necessário para formulários que submetem parceiro como objeto aninhado.
  Future<List<Map<String, dynamic>>> fetchParceiroDropdownObjeto() async {
    return _fetchParceiroList(
      toMap: (item) => {
        'value': {'id': item['id'], 'nome': item['nome']?.toString() ?? ''},
        'label': item['nome']?.toString() ?? '',
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchParceiroList({
    required Map<String, dynamic> Function(dynamic item) toMap,
  }) async {
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allParceiros,
      );
      if (response.isSuccess && response.body != null) {
        final body = response.body!;
        List<dynamic> data = [];
        // Suporta {data: {dados: [...]}}, {content: [...]}, {data: [...]}, ou lista direta
        if (body['data'] is Map && body['data']['dados'] is List) {
          data = body['data']['dados'];
        } else if (body['content'] is List) {
          data = body['content'];
        } else if (body['data'] is List) {
          data = body['data'];
        } else if (body['dados'] is List) {
          data = body['dados'];
        } else if (body is List) {
          data = body as List;
        }
        return data.map<Map<String, dynamic>>((item) => toMap(item)).toList();
      }
    } catch (e) {
      L.d('Erro ao carregar parceiros dropdown: $e');
    }
    return [];
  }
}
