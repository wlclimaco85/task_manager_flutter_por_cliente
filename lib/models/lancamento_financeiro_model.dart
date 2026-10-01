class LancamentoFinanceiro {
  int? id;
  String tipo;
  String descricao;
  double valor;
  DateTime? dataVencimento;
  DateTime? dataBaixa;
  double? valorBaixa;
  int? statusId;
  String? statusNome;
  int? empresaId;
  int? parceiroId;
  String? parceiroNome;
  int? formaPagamentoId;
  String? formaPagamentoNome;
  int? categoriaFinanceiraId;
  String? categoriaFinanceiraNome;
  int? centroCustoId;
  String? centroCustoNome;
  int? contaBaixaId;
  String? contaBaixaNome;
  String? numeroNota;
  String? observacao;
  DateTime? createdAt;
  DateTime? updatedAt;

  LancamentoFinanceiro({
    this.id,
    required this.tipo,
    required this.descricao,
    required this.valor,
    this.dataVencimento,
    this.dataBaixa,
    this.valorBaixa,
    this.statusId,
    this.statusNome,
    this.empresaId,
    this.parceiroId,
    this.parceiroNome,
    this.formaPagamentoId,
    this.formaPagamentoNome,
    this.categoriaFinanceiraId,
    this.categoriaFinanceiraNome,
    this.centroCustoId,
    this.centroCustoNome,
    this.contaBaixaId,
    this.contaBaixaNome,
    this.numeroNota,
    this.observacao,
    this.createdAt,
    this.updatedAt,
  });

  factory LancamentoFinanceiro.fromJson(Map<String, dynamic> json) {
    return LancamentoFinanceiro(
      id: json['id'],
      tipo: json['tipo'] ?? 'PAGAR',
      descricao: json['descricao'] ?? '',
      valor: (json['valor'] ?? 0).toDouble(),
      dataVencimento: json['dataVencimento'] != null
          ? DateTime.tryParse(json['dataVencimento'])
          : null,
      dataBaixa: json['dataBaixa'] != null
          ? DateTime.tryParse(json['dataBaixa'])
          : null,
      valorBaixa: json['valorBaixa']?.toDouble(),
      statusId: json['statusId'],
      statusNome: json['statusNome'],
      empresaId: json['empresaId'],
      parceiroId: json['parceiroId'],
      parceiroNome: json['parceiroNome'],
      formaPagamentoId: json['formaPagamentoId'],
      formaPagamentoNome: json['formaPagamentoNome'],
      categoriaFinanceiraId: json['categoriaFinanceiraId'],
      categoriaFinanceiraNome: json['categoriaFinanceiraNome'],
      centroCustoId: json['centroCustoId'],
      centroCustoNome: json['centroCustoNome'],
      contaBaixaId: json['contaBaixaId'],
      contaBaixaNome: json['contaBaixaNome'],
      numeroNota: json['numeroNota'],
      observacao: json['observacao'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'descricao': descricao,
      'valor': valor,
      'dataVencimento': dataVencimento?.toIso8601String(),
      'dataBaixa': dataBaixa?.toIso8601String(),
      'valorBaixa': valorBaixa,
      'statusId': statusId,
      'statusNome': statusNome,
      'empresaId': empresaId,
      'parceiroId': parceiroId,
      'parceiroNome': parceiroNome,
      'formaPagamentoId': formaPagamentoId,
      'formaPagamentoNome': formaPagamentoNome,
      'categoriaFinanceiraId': categoriaFinanceiraId,
      'categoriaFinanceiraNome': categoriaFinanceiraNome,
      'centroCustoId': centroCustoId,
      'centroCustoNome': centroCustoNome,
      'contaBaixaId': contaBaixaId,
      'contaBaixaNome': contaBaixaNome,
      'numeroNota': numeroNota,
      'observacao': observacao,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isPagamento => tipo == 'PAGAR';
  bool get isRecebimento => tipo == 'RECEBER';
}
