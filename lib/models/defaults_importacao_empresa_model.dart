/// Defaults financeiros de uma empresa usados na resolução de conta/centro
/// de custo quando um arquivo de importação (SINTEGRA/SPED) vem incompleto.
///
/// Espelha `DefaultsImportacaoEmpresaResponseDTO`/`DefaultsImportacaoEmpresaRequestDTO`
/// do backend (`GET`/`PUT /api/defaults-importacao/{empresaId}`).
class DefaultsImportacaoEmpresa {
  final int? empresaId;
  final int? contaBancariaId;
  final String? contaBancariaNome;
  final int? contaCaixaId;
  final String? contaCaixaNome;
  final int? centroCustoId;
  final String? centroCustoNome;
  final bool baixarAutomaticoNoVencimento;

  const DefaultsImportacaoEmpresa({
    this.empresaId,
    this.contaBancariaId,
    this.contaBancariaNome,
    this.contaCaixaId,
    this.contaCaixaNome,
    this.centroCustoId,
    this.centroCustoNome,
    this.baixarAutomaticoNoVencimento = false,
  });

  /// Estado vazio (nenhum default salvo ainda) para a empresa informada —
  /// usado antes da primeira carga e quando o backend não tem registro.
  factory DefaultsImportacaoEmpresa.vazio(int? empresaId) =>
      DefaultsImportacaoEmpresa(empresaId: empresaId);

  factory DefaultsImportacaoEmpresa.fromJson(Map<String, dynamic> json) {
    return DefaultsImportacaoEmpresa(
      empresaId: _toInt(json['empresaId']),
      contaBancariaId: _toInt(json['contaBancariaId']),
      contaBancariaNome: json['contaBancariaNome']?.toString(),
      contaCaixaId: _toInt(json['contaCaixaId']),
      contaCaixaNome: json['contaCaixaNome']?.toString(),
      centroCustoId: _toInt(json['centroCustoId']),
      centroCustoNome: json['centroCustoNome']?.toString(),
      baixarAutomaticoNoVencimento: json['baixarAutomaticoNoVencimento'] == true,
    );
  }

  /// Corpo enviado ao `PUT` — o backend limpa qualquer campo que vier nulo.
  Map<String, dynamic> toRequestJson() => {
        'contaBancariaId': contaBancariaId,
        'contaCaixaId': contaCaixaId,
        'centroCustoId': centroCustoId,
        'baixarAutomaticoNoVencimento': baixarAutomaticoNoVencimento,
      };

  DefaultsImportacaoEmpresa copyWith({
    int? empresaId,
    int? contaBancariaId,
    bool limparContaBancaria = false,
    String? contaBancariaNome,
    int? contaCaixaId,
    bool limparContaCaixa = false,
    String? contaCaixaNome,
    int? centroCustoId,
    bool limparCentroCusto = false,
    String? centroCustoNome,
    bool? baixarAutomaticoNoVencimento,
  }) {
    return DefaultsImportacaoEmpresa(
      empresaId: empresaId ?? this.empresaId,
      contaBancariaId:
          limparContaBancaria ? null : (contaBancariaId ?? this.contaBancariaId),
      contaBancariaNome:
          limparContaBancaria ? null : (contaBancariaNome ?? this.contaBancariaNome),
      contaCaixaId: limparContaCaixa ? null : (contaCaixaId ?? this.contaCaixaId),
      contaCaixaNome:
          limparContaCaixa ? null : (contaCaixaNome ?? this.contaCaixaNome),
      centroCustoId: limparCentroCusto ? null : (centroCustoId ?? this.centroCustoId),
      centroCustoNome:
          limparCentroCusto ? null : (centroCustoNome ?? this.centroCustoNome),
      baixarAutomaticoNoVencimento:
          baixarAutomaticoNoVencimento ?? this.baixarAutomaticoNoVencimento,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
