class ItemVendaModel {
  final int produtoId;
  final String nomeProduto;
  final String? codigoProduto;
  final double precoUnitario;
  int quantidade;
  double desconto;

  ItemVendaModel({
    required this.produtoId,
    required this.nomeProduto,
    this.codigoProduto,
    required this.precoUnitario,
    this.quantidade = 1,
    this.desconto = 0,
  });

  double get subtotal => (precoUnitario * quantidade) - desconto;

  Map<String, dynamic> toJson() => {
        'produtoId': produtoId,
        'quantidade': quantidade,
        'precoUnitario': precoUnitario,
        'desconto': desconto,
      };
}

class PagamentoModel {
  // DINHEIRO, CARTAO_CREDITO, CARTAO_DEBITO, PIX, OUTRO ou codigo SEFAZ.
  final String formaPagamento;
  double valor;

  PagamentoModel({required this.formaPagamento, required this.valor});

  String get codigoSefaz {
    switch (formaPagamento.toUpperCase()) {
      case 'DINHEIRO':
        return '01';
      case 'CHEQUE':
        return '02';
      case 'CARTAO_CREDITO':
        return '03';
      case 'CARTAO_DEBITO':
        return '04';
      case 'PIX':
        return '17';
      case 'OUTRO':
      case 'OUTROS':
        return '99';
      default:
        return RegExp(r'^\d{2}$').hasMatch(formaPagamento)
            ? formaPagamento
            : '99';
    }
  }

  Map<String, dynamic> toJson() => {
        'formaPagamento': codigoSefaz,
        'valor': valor,
      };
}
