/// Enum para status de filtro de NFe
enum NfeStatusFilter {
  all('Todas'),
  rascunho('Rascunho'),
  autorizada('Autorizada'),
  rejeitada('Rejeitada'),
  cancelada('Cancelada');

  final String label;
  const NfeStatusFilter(this.label);

  String get apiValue {
    switch (this) {
      case NfeStatusFilter.all:
        return '';
      case NfeStatusFilter.rascunho:
        return 'RASCUNHO';
      case NfeStatusFilter.autorizada:
        return 'AUTORIZADA';
      case NfeStatusFilter.rejeitada:
        return 'REJEITADA';
      case NfeStatusFilter.cancelada:
        return 'CANCELADA';
    }
  }

  static NfeStatusFilter fromApiValue(String value) {
    return NfeStatusFilter.values.firstWhere(
      (e) => e.apiValue == value.toUpperCase(),
      orElse: () => NfeStatusFilter.all,
    );
  }
}

/// Enum para ordenação de lista de NFe
enum NfeSortField {
  numero('Número'),
  data('Data'),
  valor('Valor'),
  status('Status');

  final String label;
  const NfeSortField(this.label);
}

/// Modelo de filtros para lista de NFe.
/// Define critérios de filtro, busca e ordenação.
class NfeFilterModel {
  final NfeStatusFilter status;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? empresaId; // Multi-tenant: empresaId do contexto
  final NfeSortField sortBy;
  final bool sortAscending;

  NfeFilterModel({
    this.status = NfeStatusFilter.all,
    this.dataInicio,
    this.dataFim,
    this.empresaId,
    this.sortBy = NfeSortField.data,
    this.sortAscending = false,
  });

  /// Factory para criar filtro vazio (sem filtros aplicados)
  factory NfeFilterModel.empty() {
    return NfeFilterModel();
  }

  /// Cópia com campos sobrescritos (imutabilidade)
  NfeFilterModel copyWith({
    NfeStatusFilter? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? empresaId,
    NfeSortField? sortBy,
    bool? sortAscending,
  }) {
    return NfeFilterModel(
      status: status ?? this.status,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      empresaId: empresaId ?? this.empresaId,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// Remove todos os filtros de data
  NfeFilterModel clearDateRange() {
    return NfeFilterModel(
      status: status,
      dataInicio: null,
      dataFim: null,
      empresaId: empresaId,
      sortBy: sortBy,
      sortAscending: sortAscending,
    );
  }

  /// Retorna true se há filtros ativos (além de status=all)
  bool get hasActiveFilters {
    return status != NfeStatusFilter.all ||
        dataInicio != null ||
        dataFim != null;
  }

  /// Conta quantos filtros estão ativos
  int get activeFilterCount {
    int count = 0;
    if (status != NfeStatusFilter.all) count++;
    if (dataInicio != null) count++;
    if (dataFim != null) count++;
    return count;
  }

  /// Retorna descrição dos filtros ativos para UI
  String get activeFiltersDescription {
    final parts = <String>[];
    if (status != NfeStatusFilter.all) {
      parts.add(status.label);
    }
    if (dataInicio != null && dataFim != null) {
      final inicio = _formatDate(dataInicio!);
      final fim = _formatDate(dataFim!);
      parts.add('$inicio a $fim');
    } else if (dataInicio != null) {
      parts.add('De ${_formatDate(dataInicio!)}');
    } else if (dataFim != null) {
      parts.add('Até ${_formatDate(dataFim!)}');
    }
    return parts.join(' • ');
  }

  /// Formata DateTime para DD/MM/YYYY
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NfeFilterModel &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          dataInicio == other.dataInicio &&
          dataFim == other.dataFim &&
          empresaId == other.empresaId &&
          sortBy == other.sortBy &&
          sortAscending == other.sortAscending;

  @override
  int get hashCode =>
      status.hashCode ^
      dataInicio.hashCode ^
      dataFim.hashCode ^
      empresaId.hashCode ^
      sortBy.hashCode ^
      sortAscending.hashCode;

  @override
  String toString() =>
      'NfeFilterModel(status: $status, dataInicio: $dataInicio, dataFim: $dataFim, '
      'empresaId: $empresaId, sortBy: $sortBy, sortAscending: $sortAscending)';
}
