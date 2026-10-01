import 'package:flutter/foundation.dart';
import 'package:task_manager_flutter/models/nfe/nfe_exceptions.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Notifier que gerencia o estado de NFes com Provider
///
/// Responsável por:
/// - Carregar lista de NFes com filtros
/// - Obter detalhes de uma NFe específica
/// - Manipular erros e estados de loading
/// - Limpar estado de erro
class NfeNotifier extends ChangeNotifier {
  final NfeRepository _repository;

  NfeState _state = NfeState(
    nfes: [],
    selected: null,
    isLoading: false,
    errorMessage: null,
    currentPage: 1,
    pageSize: 10,
  );

  NfeNotifier(this._repository);

  /// Getter do estado atual
  NfeState get state => _state;

  /// Atualiza estado interno e notifica listeners
  void _setState(NfeState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Método público de teste para manipular estado
  @visibleForTesting
  void setTestState(NfeState newState) {
    _setState(newState);
  }

  /// Lista NFes com paginação e filtros opcionais
  ///
  /// [page] - número da página (começa em 1)
  /// [pageSize] - quantidade de itens por página
  /// [status] - filtrar por status (RASCUNHO, AUTORIZADA, REJEITADA, etc)
  /// [dataInicio] - filtrar por data inicial
  /// [dataFim] - filtrar por data final
  /// [clienteCnpj] - filtrar por CNPJ do cliente
  Future<void> listarNfe({
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {
    L.d('[NfeNotifier] Iniciando listarNfe: page=$page, pageSize=$pageSize');

    // Atualiza para loading
    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      // Chama repository
      final nfes = await _repository.listarNfe(
        page: page,
        pageSize: pageSize,
        status: status,
        dataInicio: dataInicio,
        dataFim: dataFim,
        clienteCnpj: clienteCnpj,
      );

      L.d('[NfeNotifier] Carregou ${nfes.length} NFes com sucesso');

      // Atualiza estado com sucesso
      _setState(_state.copyWith(
        nfes: nfes,
        isLoading: false,
        errorMessage: null,
        currentPage: page,
        pageSize: pageSize,
      ));
    } on NfeRepositoryException catch (e) {
      L.e('[NfeNotifier] Erro ao listar NFes: ${e.message}');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        nfes: [],
      ));
    } catch (e) {
      final errorMsg = 'Erro inesperado ao listar NFes: $e';
      L.e('[NfeNotifier] $errorMsg');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
        nfes: [],
      ));
    }
  }

  /// Obtém detalhes completos de uma NFe específica
  ///
  /// [id] - ID da NFe a ser obtida
  /// Atualiza [selected] no estado
  Future<void> obterNfe(int id) async {
    L.d('[NfeNotifier] Obtendo NFe ID=$id');

    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final nfe = await _repository.obterNfe(id);
      L.d('[NfeNotifier] Obteve NFe $id com sucesso');

      _setState(_state.copyWith(
        selected: nfe,
        isLoading: false,
        errorMessage: null,
      ));
    } on NfeNotFoundException catch (e) {
      L.w('[NfeNotifier] NFe não encontrada: ${e.message}');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        selected: null,
      ));
    } on NfeRepositoryException catch (e) {
      L.e('[NfeNotifier] Erro ao obter NFe: ${e.message}');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        selected: null,
      ));
    } catch (e) {
      final errorMsg = 'Erro inesperado ao obter NFe: $e';
      L.e('[NfeNotifier] $errorMsg');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
        selected: null,
      ));
    }
  }

  /// Remove uma NFe da lista local
  ///
  /// Nota: não faz delete no servidor, apenas atualiza UI
  void removerNfeLocal(int id) {
    L.d('[NfeNotifier] Removendo NFe $id da lista local');
    final updated = _state.nfes.where((nfe) => nfe.id != id).toList();
    _setState(_state.copyWith(nfes: updated));
  }

  /// Limpa mensagem de erro
  void limparErro() {
    L.d('[NfeNotifier] Limpando erro');
    _setState(_state.copyWith(errorMessage: null));
  }

  /// Reseta o estado para valores iniciais
  void resetarEstado() {
    L.d('[NfeNotifier] Resetando estado');
    _setState(NfeState(
      nfes: [],
      selected: null,
      isLoading: false,
      errorMessage: null,
      currentPage: 1,
      pageSize: 10,
    ));
  }

  /// Cria uma nova NFe com os dados do formulário
  ///
  /// [dados] - Map com tomador, itens, natureza, observações, etc
  /// Retorna NfeModel criada ou lança NfeRepositoryException
  Future<NfeModel> criarNfe(Map<String, dynamic> dados) async {
    L.d('[NfeNotifier] Criando nova NFe com dados: $dados');

    _setState(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final nfe = await _repository.criarNfe(dados);
      L.d('[NfeNotifier] Criou NFe #${nfe.id} com sucesso');

      // Atualiza estado com a NFe criada como selecionada
      _setState(_state.copyWith(
        selected: nfe,
        isLoading: false,
        errorMessage: null,
      ));

      return nfe;
    } on NfeRepositoryException catch (e) {
      L.e('[NfeNotifier] Erro ao criar NFe: ${e.message}');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      ));
      rethrow;
    } catch (e) {
      final errorMsg = 'Erro inesperado ao criar NFe: $e';
      L.e('[NfeNotifier] $errorMsg');
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      ));
      rethrow;
    }
  }

  /// Avança para próxima página (se possível)
  Future<void> proximaPagina({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {
    final nextPage = (_state.currentPage ?? 1) + 1;
    if (nextPage <= _state.totalPages) {
      await listarNfe(
        page: nextPage,
        pageSize: _state.pageSize ?? 10,
        status: status,
        dataInicio: dataInicio,
        dataFim: dataFim,
        clienteCnpj: clienteCnpj,
      );
    }
  }

  /// Volta para página anterior (se possível)
  Future<void> paginaAnterior({
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {
    final prevPage = (_state.currentPage ?? 1) - 1;
    if (prevPage >= 1) {
      await listarNfe(
        page: prevPage,
        pageSize: _state.pageSize ?? 10,
        status: status,
        dataInicio: dataInicio,
        dataFim: dataFim,
        clienteCnpj: clienteCnpj,
      );
    }
  }
}
