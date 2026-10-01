/// Model for batch baixa (bulk payment) requests and responses.
class BaixaLoteRequest {
  final DateTime dataBaixa;
  final int? formaPagamentoId;
  final int? contaBancariaId;
  final String? observacao;
  final List<BaixaLoteItem>? itens;

  BaixaLoteRequest({
    required this.dataBaixa,
    this.formaPagamentoId,
    this.contaBancariaId,
    this.observacao,
    this.itens,
  });

  Map<String, dynamic> toJson() {
    return {
      'dataBaixa': dataBaixa.toIso8601String().substring(0, 10),
      if (formaPagamentoId != null) 'formaPagamentoId': formaPagamentoId,
      if (contaBancariaId != null) 'contaBancariaId': contaBancariaId,
      if (observacao != null && observacao!.isNotEmpty)
        'observacao': observacao,
      if (itens != null && itens!.isNotEmpty)
        'itens': itens!.map((i) => i.toJson()).toList(),
    };
  }
}

/// Individual item with optional juros/multa/desconto overrides.
class BaixaLoteItem {
  final int contaId;
  final double? valorBaixa;
  final double? valorJuros;
  final double? valorMulta;
  final double? valorDesconto;

  BaixaLoteItem({
    required this.contaId,
    this.valorBaixa,
    this.valorJuros,
    this.valorMulta,
    this.valorDesconto,
  });

  Map<String, dynamic> toJson() {
    return {
      'contaId': contaId,
      if (valorBaixa != null) 'valorBaixa': valorBaixa,
      if (valorJuros != null) 'valorJuros': valorJuros,
      if (valorMulta != null) 'valorMulta': valorMulta,
      if (valorDesconto != null) 'valorDesconto': valorDesconto,
    };
  }
}

/// Response from batch baixa API.
class BaixaLoteResponse {
  final bool success;
  final int totalProcessados;
  final int totalSucesso;
  final int totalErros;
  final List<BaixaLoteItemResult> resultados;
  final String? mensagemGeral;

  BaixaLoteResponse({
    required this.success,
    required this.totalProcessados,
    required this.totalSucesso,
    required this.totalErros,
    required this.resultados,
    this.mensagemGeral,
  });

  factory BaixaLoteResponse.fromJson(Map<String, dynamic> json) {
    final resultados = (json['resultados'] as List<dynamic>?)
            ?.map((r) => BaixaLoteItemResult.fromJson(r))
            .toList() ??
        [];
    return BaixaLoteResponse(
      success: json['success'] ?? false,
      totalProcessados: json['totalProcessados'] ?? 0,
      totalSucesso: json['totalSucesso'] ?? 0,
      totalErros: json['totalErros'] ?? 0,
      resultados: resultados,
      mensagemGeral: json['mensagemGeral'],
    );
  }
}

/// Result for a single item in batch baixa.
class BaixaLoteItemResult {
  final int contaId;
  final bool sucesso;
  final String? mensagem;
  final String? descricao;

  BaixaLoteItemResult({
    required this.contaId,
    required this.sucesso,
    this.mensagem,
    this.descricao,
  });

  factory BaixaLoteItemResult.fromJson(Map<String, dynamic> json) {
    return BaixaLoteItemResult(
      contaId: json['contaId'] ?? 0,
      sucesso: json['sucesso'] ?? false,
      mensagem: json['mensagem'],
      descricao: json['descricao'],
    );
  }
}
