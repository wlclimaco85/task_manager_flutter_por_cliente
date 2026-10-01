// lib/models/nfe_pagamento_model.dart
// NF07 — modelo de forma de pagamento da NF-e

class NfePagamento {
  final int? id;
  final String tPag;
  final double vPag;

  const NfePagamento({this.id, required this.tPag, required this.vPag});

  factory NfePagamento.fromJson(Map<String, dynamic> json) => NfePagamento(
        id: json['id'] as int?,
        tPag: (json['tPag'] ?? json['t_pag'] ?? '99').toString(),
        vPag: ((json['vPag'] ?? json['v_pag']) as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {'tPag': tPag, 'vPag': vPag};

  /// Retorna o label legível do código de pagamento NF-e 4.0
  static String labelTipo(String tPag) {
    const m = {
      '01': 'Dinheiro',
      '02': 'Cheque',
      '03': 'Cartão Crédito',
      '04': 'Cartão Débito',
      '05': 'Crédito Loja',
      '10': 'Vale Alimentação',
      '11': 'Vale Refeição',
      '12': 'Vale Presente',
      '13': 'Vale Combustível',
      '15': 'Boleto',
      '16': 'Depósito Bancário',
      '17': 'PIX',
      '90': 'Sem Pagamento',
      '99': 'Outros',
    };
    return m[tPag] ?? tPag;
  }

  static const List<String> todosCodigos = [
    '01', '02', '03', '04', '05', '10', '11', '12', '13', '15', '16', '17', '90', '99',
  ];
}
