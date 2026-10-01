import 'dart:convert';
import '../../../models/cotacao_model.dart';
import '../../../models/dollar_model.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class CotacaoCaller {
  Future<List<Cotacao>> fetchCotacoes() async {
    List<Cotacao>? model = [];
    CotacaoModel models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.allCotacoes);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = CotacaoModel.fromJson(response.body!);
        model.addAll(models.data ?? []);

        // if (model != null && model.data != null) {
        //   newsList.addAll(model.data!);
        // }
        // Use jsonString conforme necessário
      } else {
        // Trate o caso onde o data é nulo
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  Future<List<Dollar>> fetchCotacoesDollar() async {
    List<Dollar>? model = [];
    DollarModel models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.fecthAllCotacaoDollar);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = DollarModel.fromJson(response.body!);
        model.addAll(models.data ?? []);

        // if (model != null && model.data != null) {
        //   newsList.addAll(model.data!);
        // }
        // Use jsonString conforme necessário
      } else {
        // Trate o caso onde o data é nulo
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }
}
