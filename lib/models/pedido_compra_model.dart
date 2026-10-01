class PedidoCompraItem {
  int? id;
  int? produtoId;
  String? produtoNome;
  String? descricao;
  double? quantidade;
  double? quantidadeRecebida;
  double? valorUnitario;
  double? desconto;
  double? total;

  PedidoCompraItem({
    this.id,
    this.produtoId,
    this.produtoNome,
    this.descricao,
    this.quantidade,
    this.quantidadeRecebida,
    this.valorUnitario,
    this.desconto,
    this.total,
  });

  PedidoCompraItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    produtoId = json['produtoId'];
    produtoNome = json['produtoNome'];
    descricao = json['descricao'];
    quantidade = (json['quantidade'] as num?)?.toDouble();
    quantidadeRecebida = (json['quantidadeRecebida'] as num?)?.toDouble();
    valorUnitario = (json['valorUnitario'] as num?)?.toDouble();
    desconto = (json['desconto'] as num?)?.toDouble();
    total = (json['total'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['produtoId'] = produtoId;
    data['produtoNome'] = produtoNome;
    data['descricao'] = descricao;
    data['quantidade'] = quantidade;
    data['quantidadeRecebida'] = quantidadeRecebida;
    data['valorUnitario'] = valorUnitario;
    data['desconto'] = desconto;
    data['total'] = total;
    return data;
  }
}

class PedidoCompraHistorico {
  int? id;
  int? versao;
  String? statusAnterior;
  String? statusNovo;
  String? observacao;
  String? data;

  PedidoCompraHistorico({
    this.id,
    this.versao,
    this.statusAnterior,
    this.statusNovo,
    this.observacao,
    this.data,
  });

  PedidoCompraHistorico.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    versao = json['versao'];
    statusAnterior = json['statusAnterior'];
    statusNovo = json['statusNovo'];
    observacao = json['observacao'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final d = <String, dynamic>{};
    d['id'] = id;
    d['versao'] = versao;
    d['statusAnterior'] = statusAnterior;
    d['statusNovo'] = statusNovo;
    d['observacao'] = observacao;
    d['data'] = data;
    return d;
  }
}

class PedidoCompra {
  int? id;
  String? numero;
  int? fornecedorId;
  String? fornecedorNome;
  int? centroCustoId;
  String? centroCustoNome;
  String? dataEmissao;
  String? dataEntrega;
  String? observacao;
  double? descontoGeral;
  double? totalGeral;
  String? status;
  List<PedidoCompraItem>? itens;
  List<PedidoCompraHistorico>? historico;

  PedidoCompra({
    this.id,
    this.numero,
    this.fornecedorId,
    this.fornecedorNome,
    this.centroCustoId,
    this.centroCustoNome,
    this.dataEmissao,
    this.dataEntrega,
    this.observacao,
    this.descontoGeral,
    this.totalGeral,
    this.status,
    this.itens,
    this.historico,
  });

  PedidoCompra.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    numero = json['numero'];
    fornecedorId = json['fornecedorId'];
    fornecedorNome = json['fornecedorNome'];
    centroCustoId = json['centroCustoId'];
    centroCustoNome = json['centroCustoNome'];
    dataEmissao = json['dataEmissao'];
    dataEntrega = json['dataEntrega'];
    observacao = json['observacao'];
    descontoGeral = (json['descontoGeral'] as num?)?.toDouble();
    totalGeral = (json['totalGeral'] as num?)?.toDouble();
    status = json['status'];
    if (json['itens'] != null) {
      itens = (json['itens'] as List)
          .map((i) => PedidoCompraItem.fromJson(i))
          .toList();
    }
    if (json['historico'] != null) {
      historico = (json['historico'] as List)
          .map((h) => PedidoCompraHistorico.fromJson(h))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['numero'] = numero;
    data['fornecedorId'] = fornecedorId;
    data['fornecedorNome'] = fornecedorNome;
    data['centroCustoId'] = centroCustoId;
    data['centroCustoNome'] = centroCustoNome;
    data['dataEmissao'] = dataEmissao;
    data['dataEntrega'] = dataEntrega;
    data['observacao'] = observacao;
    data['descontoGeral'] = descontoGeral;
    data['totalGeral'] = totalGeral;
    data['status'] = status;
    if (itens != null) {
      data['itens'] = itens!.map((i) => i.toJson()).toList();
    }
    if (historico != null) {
      data['historico'] = historico!.map((h) => h.toJson()).toList();
    }
    return data;
  }

  static List<PedidoCompra> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => PedidoCompra.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
