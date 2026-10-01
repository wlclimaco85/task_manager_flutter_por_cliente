/// Enum que representa os estados possíveis de uma NFe
enum NfeStatus {
  autorizada('AUTORIZADA', 'Autorizada'),
  rejeitada('REJEITADA', 'Rejeitada'),
  pendente('PENDENTE', 'Pendente'),
  cancelada('CANCELADA', 'Cancelada'),
  contingencia('CONTINGENCIA', 'Contingência'),
  erro('ERROR', 'Erro');

  final String code;
  final String label;

  const NfeStatus(this.code, this.label);

  /// Factory para criar enum a partir de string code
  factory NfeStatus.fromCode(String? code) {
    if (code == null || code.isEmpty) return NfeStatus.pendente;
    return values.firstWhere(
      (v) => v.code == code.toUpperCase(),
      orElse: () => NfeStatus.erro,
    );
  }

  /// Verifica se NFe está autorizada
  bool get isAutorizada => this == NfeStatus.autorizada;

  /// Verifica se NFe foi rejeitada
  bool get isRejeitada => this == NfeStatus.rejeitada;

  /// Verifica se NFe está pendente
  bool get isPendente => this == NfeStatus.pendente;

  /// Verifica se NFe foi cancelada
  bool get isCancelada => this == NfeStatus.cancelada;

  /// Verifica se NFe está em contingência
  bool get isContingencia => this == NfeStatus.contingencia;

  /// Verifica se há erro
  bool get isErro => this == NfeStatus.erro;
}
