import 'package:task_manager_flutter/models/nfe/nfe_model.dart';

/// Estado imutável que representa o estado gerenciado de NFes
///
/// Pode estar em 4 estados principais:
/// - Loading: carregando dados
/// - Loaded: dados carregados com sucesso
/// - Error: erro ao carregar
/// - Empty: nenhuma NFe disponível
class NfeState {
  /// Lista de NFes carregadas
  final List<NfeModel> nfes;

  /// NFe atualmente selecionada (null se nenhuma)
  final NfeModel? selected;

  /// Indica se está carregando
  final bool isLoading;

  /// Mensagem de erro (null se sem erro)
  final String? errorMessage;

  /// Página atual para paginação
  final int? currentPage;

  /// Quantidade de itens por página
  final int? pageSize;

  /// Construtor da classe
  const NfeState({
    required this.nfes,
    this.selected,
    required this.isLoading,
    this.errorMessage,
    this.currentPage,
    this.pageSize,
  });

  /// Verifica se há erro
  bool get hasError => errorMessage != null;

  /// Verifica se está vazio (sem NFes)
  bool get isEmpty => nfes.isEmpty;

  /// Calcula número total de páginas
  int get totalPages {
    if (pageSize == null || pageSize! <= 0) return 1;
    if (nfes.isEmpty) return 1;
    return (nfes.length / pageSize!).ceil();
  }

  /// Verifica se pode ir para próxima página
  bool get canNextPage {
    final page = currentPage ?? 1;
    return page < totalPages;
  }

  /// Verifica se pode voltar para página anterior
  bool get canPreviousPage => (currentPage ?? 1) > 1;

  /// Retorna descrição do estado para debugging
  String get stateDescription {
    if (isLoading) return 'LOADING';
    if (hasError) return 'ERROR: $errorMessage';
    if (isEmpty) return 'EMPTY';
    return 'LOADED (${nfes.length} NFes)';
  }

  /// Cria uma cópia do estado com valores opcionalmente alterados
  NfeState copyWith({
    List<NfeModel>? nfes,
    NfeModel? selected,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? pageSize,
  }) {
    return NfeState(
      nfes: nfes ?? this.nfes,
      selected: selected ?? this.selected,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  String toString() => 'NfeState(nfes: ${nfes.length}, selected: $selected, isLoading: $isLoading, error: $errorMessage, page: $currentPage/$totalPages)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NfeState &&
          runtimeType == other.runtimeType &&
          nfes == other.nfes &&
          selected == other.selected &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          currentPage == other.currentPage &&
          pageSize == other.pageSize;

  @override
  int get hashCode => Object.hash(
    nfes,
    selected,
    isLoading,
    errorMessage,
    currentPage,
    pageSize,
  );
}
