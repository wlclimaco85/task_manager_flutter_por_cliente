import 'network_caller.dart';
import '../utils/api_links.dart';

/// Service for cobrança automática (automatic collection) operations.
class CobrancaService {
  final NetworkCaller _caller = NetworkCaller();

  /// Send automatic cobranca for selected contas a receber.
  Future<Map<String, dynamic>> enviarCobranca(List<int> contaIds) async {
    final response = await _caller.postRequest(
      ApiLinks.cobrancaAutomaticaEnviar,
      {'contaIds': contaIds},
    );
    if (response.isSuccess && response.body != null) {
      return response.body!;
    }
    return {
      'success': false,
      'mensagem': 'Erro ao enviar cobrança (HTTP ${response.statusCode})',
    };
  }

  /// Schedule cobranca for future date.
  Future<Map<String, dynamic>> agendarCobranca({
    required List<int> contaIds,
    required String dataAgendamento,
    String? observacao,
  }) async {
    final response = await _caller.postRequest(
      ApiLinks.cobrancaAutomaticaAgendar,
      {
        'contaIds': contaIds,
        'dataAgendamento': dataAgendamento,
        if (observacao != null && observacao.isNotEmpty) 'observacao': observacao,
      },
    );
    if (response.isSuccess && response.body != null) {
      return response.body!;
    }
    return {
      'success': false,
      'mensagem': 'Erro ao agendar cobrança (HTTP ${response.statusCode})',
    };
  }

  /// Get cobranca history.
  Future<List<Map<String, dynamic>>> getHistorico() async {
    final response = await _caller.getRequest(ApiLinks.cobrancaAutomaticaHistorico);
    if (response.isSuccess && response.body != null) {
      return _extractList(response.body!);
    }
    return [];
  }

  /// Get pending cobrancas.
  Future<List<Map<String, dynamic>>> getPendentes() async {
    final response = await _caller.getRequest(ApiLinks.cobrancaAutomaticaPendentes);
    if (response.isSuccess && response.body != null) {
      return _extractList(response.body!);
    }
    return [];
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is List) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    if (body.containsKey('content') && body['content'] is List) {
      return List<Map<String, dynamic>>.from(body['content']);
    }
    final values = body.values.whereType<List>();
    if (values.isNotEmpty) {
      return List<Map<String, dynamic>>.from(values.first);
    }
    return [];
  }
}
