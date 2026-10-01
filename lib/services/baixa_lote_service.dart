import '../models/baixa_lote_model.dart';
import '../models/network_response.dart';
import 'network_caller.dart';
import '../utils/api_links.dart';

/// Service for batch baixa (bulk payment) operations.
class BaixaLoteService {
  final NetworkCaller _caller = NetworkCaller();

  /// Execute batch baixa for contas a pagar.
  Future<BaixaLoteResponse> baixaLotePagar(
    List<int> ids,
    BaixaLoteRequest request,
  ) async {
    final response = await _caller.postRequest(
      ApiLinks.baixaLotePagar,
      {
        'ids': ids,
        ...request.toJson(),
      },
    );
    return _parseResponse(response);
  }

  /// Execute batch baixa for contas a receber.
  Future<BaixaLoteResponse> baixaLoteReceber(
    List<int> ids,
    BaixaLoteRequest request,
  ) async {
    final response = await _caller.postRequest(
      ApiLinks.baixaLoteReceber,
      {
        'ids': ids,
        ...request.toJson(),
      },
    );
    return _parseResponse(response);
  }

  BaixaLoteResponse _parseResponse(NetworkResponse response) {
    if (response.isSuccess && response.body != null) {
      return BaixaLoteResponse.fromJson(response.body!);
    }
    return BaixaLoteResponse(
      success: false,
      totalProcessados: 0,
      totalSucesso: 0,
      totalErros: 0,
      resultados: [],
      mensagemGeral: 'Erro na requisição (HTTP ${response.statusCode})',
    );
  }
}
