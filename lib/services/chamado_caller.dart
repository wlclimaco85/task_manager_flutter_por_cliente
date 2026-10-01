import '../models/chamado_model.dart';
import 'package:task_manager_flutter/models/network_response.dart';
import 'package:task_manager_flutter/services/network_caller.dart';
import 'package:task_manager_flutter/utils/api_links.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class ChamadoCaller {
  Future<List<Chamado>> fetchAllChamados() async {
    List<Chamado> list = [];
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.allChamados,
      );

      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']['dados'] ?? [];
        list = (data as List).map((item) => Chamado.fromJson(item)).toList();
      }
    } catch (e) {
      L.d('Erro ao carregar chamados: $e');
      throw Exception('Erro ao carregar chamados: $e');
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> fetchChamadoDropdown() async {
    final chamados = await fetchAllChamados();
    return chamados.map((c) => {'value': c.id, 'label': c.titulo}).toList();
  }

  Future<Chamado> createChamado(Chamado chamado,
      {required String token}) async {
    final NetworkResponse response = await NetworkCaller()
        .postRequest(ApiLinks.allChamados, chamado.toJson());

    if (response.isSuccess && response.body != null) {
      final data = response.body ?? response.body!;
      return Chamado.fromJson(data);
    } else {
      throw Exception('Falha ao criar chamado (${response.statusCode})');
    }
  }

  // 🔹 Pegar (assumir) chamado
  Future<bool> pegarChamado(int id, int userId) async {
    final response = await NetworkCaller().postRequest(
        "${ApiLinks.workflowChamados}/$id/atribuir?usuarioId=$userId", {});
    return response.isSuccess;
  }

  //	@RequestParam Integer origemId,
  //	@RequestParam Integer destinoId) {
  // 🔹 Transferir chamado
  Future<bool> transferirChamado(
      int id, int usuarioId, int usuarioOrigem) async {
    final response = await NetworkCaller().postRequest(
        "${ApiLinks.workflowChamados}/$id/transferir?origemId=$usuarioOrigem&destinoId=$usuarioId",
        {});
    return response.isSuccess;
  }

  // 🔹 Atribuir chamado
  Future<bool> atribuirChamado(int id, int usuarioId) async {
    final response = await NetworkCaller().postRequest(
      "${ApiLinks.workflowChamados}/$id/atribuir?usuarioId=$usuarioId",
      {'usuarioId': usuarioId},
    );
    return response.isSuccess;
  }

  // 🔹 Fechar chamado
  Future<bool> fecharChamado(int id, String motivo, int userId) async {
    final response = await NetworkCaller().postRequest(
      "${ApiLinks.workflowChamados}/$id/fechar?usuarioId=$userId&motivo=$motivo",
      {'motivoFechamento': motivo},
    );
    return response.isSuccess;
  }

  // 🔹 Histórico do chamado
  Future<List<Map<String, dynamic>>> getHistoricoChamado(int id) async {
    final response = await NetworkCaller()
        .getRequest(ApiLinks.getAllChamados(id.toString()));
    if (response.isSuccess && response.body != null) {
      return List<Map<String, dynamic>>.from(
          response.body!['data']['dados'] ?? []);
    }
    throw Exception('Erro ao buscar histórico (${response.statusCode})');
  }

  // 🔹 Retornar chamado (card #451)
  Future<bool> retornarChamado(int id, int usuarioOrigem, int usuarioDestino) async {
    final response = await NetworkCaller().postRequest(
        "${ApiLinks.workflowChamados}/$id/retornar?origemId=$usuarioOrigem&destinoId=$usuarioDestino",
        {});
    return response.isSuccess;
  }

  // 🔹 Reabrir chamado (card #451)
  Future<bool> reabrirChamado(int id, int usuarioId) async {
    final response = await NetworkCaller().postRequest(
        "${ApiLinks.workflowChamados}/$id/reabrir?usuarioId=$usuarioId", {});
    return response.isSuccess;
  }

  // 🔹 Comentar chamado — timeline (card #451)
  Future<bool> comentarChamado(int id, int usuarioId, String observacao) async {
    final response = await NetworkCaller().postRequest(
        "${ApiLinks.workflowChamados}/$id/comentario?usuarioId=$usuarioId&observacao=${Uri.encodeQueryComponent(observacao)}",
        {});
    return response.isSuccess;
  }

  // 🔹 Registrar anexo/comprovante na timeline do chamado (card #468)
  Future<bool> registrarAnexoChamado(int id, int usuarioId, String nomeArquivo) async {
    final response = await NetworkCaller().postRequest(
        "${ApiLinks.workflowChamados}/$id/anexo?usuarioId=$usuarioId&nomeArquivo=${Uri.encodeQueryComponent(nomeArquivo)}",
        {});
    return response.isSuccess;
  }

  // 🔹 Notificar toda a empresa sobre o chamado (card #451)
  Future<bool> notificarEmpresaChamado(int id, int usuarioId) async {
    final response = await NetworkCaller().postRequest(
        "${ApiLinks.workflowChamados}/$id/notificar-empresa?usuarioId=$usuarioId",
        {});
    return response.isSuccess;
  }
}
