import 'package:dio/dio.dart';
import 'package:task_manager_flutter/models/nfe/nfe_exceptions.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/services/network_caller_dio.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';

/// Repository que gerencia operações de NFe com a API backend
class NfeRepository {
  static const String _baseUrl = '/api/nfe';

  final Dio _dio;

  NfeRepository({Dio? dio}) : _dio = dio ?? NetworkCaller().dio;

  /// Lista NFe com paginação, filtro status/data/cliente
  ///
  /// Retorna lista de [NfeModel] ou lança [NfeRepositoryException]
  Future<List<NfeModel>> listarNfe({
    required int page,
    required int pageSize,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'size': pageSize,
        if (status != null && status.isNotEmpty) 'status': status.toUpperCase(),
        if (dataInicio != null) 'dataInicio': dataInicio.toIso8601String().split('T')[0],
        if (dataFim != null) 'dataFim': dataFim.toIso8601String().split('T')[0],
        if (clienteCnpj != null && clienteCnpj.isNotEmpty) 'clienteCnpj': clienteCnpj,
      };

      final url = TenantContext.applyToUrl('$_baseUrl/listar');
      L.d('[NfeRepository] GET $url com params: $params');

      final response = await _dio.get(
        url,
        queryParameters: params,
      );

      // Trata resposta: pode ser list direta ou wrapped em 'content' (pagination)
      final List items = response.data?['content'] ?? response.data ?? [];
      final nfes = items
          .cast<Map<String, dynamic>>()
          .map((json) => NfeModel.fromJson(json))
          .toList();

      L.d('[NfeRepository] Listou ${nfes.length} NFe');
      return nfes;
    } on DioException catch (e) {
      final error = _extractErrorMessage(e);
      L.e('[NfeRepository] Erro ao listar NFe: $error');
      throw NfeRepositoryException(error);
    } catch (e) {
      L.e('[NfeRepository] Erro inesperado ao listar: $e');
      throw NfeRepositoryException('Erro inesperado: $e');
    }
  }

  /// Consulta detalhe de uma NFe específica
  ///
  /// Retorna [NfeModel] ou lança [NfeNotFoundException] (404) ou [NfeRepositoryException]
  Future<NfeModel> obterNfe(int id) async {
    try {
      final url = TenantContext.applyToUrl('$_baseUrl/$id');
      L.d('[NfeRepository] GET $url');

      final response = await _dio.get(url);
      final nfe = NfeModel.fromJson(response.data as Map<String, dynamic>);

      L.d('[NfeRepository] Obteve NFe #$id (série ${nfe.serie}, número ${nfe.numero})');
      return nfe;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        L.w('[NfeRepository] NFe #$id não encontrada (404)');
        throw NfeNotFoundException('NFe #$id não encontrada no servidor');
      }
      final error = _extractErrorMessage(e);
      L.e('[NfeRepository] Erro ao obter NFe #$id: $error');
      throw NfeApiException(error, statusCode: e.response?.statusCode);
    } catch (e) {
      L.e('[NfeRepository] Erro inesperado ao obter NFe: $e');
      throw NfeRepositoryException('Erro inesperado: $e');
    }
  }

  /// Download/leitura do XML assinado de uma NFe
  ///
  /// Retorna string contendo XML bruto ou lança [NfeRepositoryException]
  Future<String> downloadXml(int id) async {
    try {
      final url = TenantContext.applyToUrl('$_baseUrl/$id/xml');
      L.d('[NfeRepository] GET $url (XML)');

      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.plain),
      );

      final xml = response.data?.toString() ?? '';
      L.d('[NfeRepository] Downloaded XML para NFe #$id (${xml.length} chars)');
      return xml;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NfeNotFoundException('XML da NFe #$id não disponível');
      }
      final error = _extractErrorMessage(e);
      L.e('[NfeRepository] Erro ao baixar XML #$id: $error');
      throw NfeRepositoryException(error);
    } catch (e) {
      L.e('[NfeRepository] Erro ao baixar XML: $e');
      throw NfeRepositoryException('Erro ao baixar XML: $e');
    }
  }

  /// Download do PDF da NFe (blob/binary)
  ///
  /// Retorna bytes do PDF ou lança [NfeRepositoryException]
  Future<List<int>> downloadPdf(int id) async {
    try {
      final url = TenantContext.applyToUrl('$_baseUrl/$id/pdf');
      L.d('[NfeRepository] GET $url (PDF)');

      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = (response.data as List<int>?) ?? [];
      L.d('[NfeRepository] Downloaded PDF para NFe #$id (${bytes.length} bytes)');
      return bytes;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NfeNotFoundException('PDF da NFe #$id não disponível');
      }
      final error = _extractErrorMessage(e);
      L.e('[NfeRepository] Erro ao baixar PDF #$id: $error');
      throw NfeRepositoryException(error);
    } catch (e) {
      L.e('[NfeRepository] Erro ao baixar PDF: $e');
      throw NfeRepositoryException('Erro ao baixar PDF: $e');
    }
  }

  /// Cria uma nova NFe em rascunho
  ///
  /// [dados] - Map com os dados do formulário (tomador, itens, natureza, etc)
  /// Retorna [NfeModel] criada ou lança [NfeRepositoryException]
  Future<NfeModel> criarNfe(Map<String, dynamic> dados) async {
    try {
      // NfeController expõe a criação via POST na raiz de /api/nfe
      // (@PostMapping sem sub-path). Não existe endpoint /api/nfe/criar —
      // esse era o bug real por trás da falha silenciosa de criação no Mobile.
      final url = TenantContext.applyToUrl(_baseUrl);
      L.d('[NfeRepository] POST $url com dados: $dados');

      final response = await _dio.post(url, data: dados);
      final nfe = NfeModel.fromJson(response.data as Map<String, dynamic>);

      L.d('[NfeRepository] Criou NFe #${nfe.id} com sucesso (série ${nfe.serie}, número ${nfe.numero})');
      return nfe;
    } on DioException catch (e) {
      final error = _extractErrorMessage(e);
      L.e('[NfeRepository] Erro ao criar NFe: $error');
      throw NfeRepositoryException(error);
    } catch (e) {
      L.e('[NfeRepository] Erro inesperado ao criar NFe: $e');
      throw NfeRepositoryException('Erro inesperado: $e');
    }
  }

  /// Helper: extrai mensagem de erro de DioException
  ///
  /// Prioridade: response.data['message'] > response.statusMessage > e.message
  String _extractErrorMessage(DioException e) {
    // Tenta extrair mensagem do response body
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message']?.toString() ?? 'Erro desconhecido';
      }
      if (data is String && data.isNotEmpty) {
        return data;
      }
    }

    // Usa status message como fallback
    if (e.response?.statusMessage != null && e.response!.statusMessage!.isNotEmpty) {
      return '${e.response!.statusCode}: ${e.response!.statusMessage}';
    }

    // Fallback final: mensagem da exception
    return e.message ?? 'Erro de conexão desconhecido';
  }
}
