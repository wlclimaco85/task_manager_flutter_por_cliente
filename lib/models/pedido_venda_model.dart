class PedidoVendaItem {
  int? id;
  int? produtoId;
  String? produtoNome;
  String? descricao;
  double? quantidade;
  double? valorUnitario;
  double? desconto;
  double? total;

  PedidoVendaItem({
    this.id,
    this.produtoId,
    this.produtoNome,
    this.descricao,
    this.quantidade,
    this.valorUnitario,
    this.desconto,
    this.total,
  });

  PedidoVendaItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    produtoId = json['produtoId'];
    produtoNome = json['produtoNome'];
    descricao = json['descricao'];
    quantidade = (json['quantidade'] as num?)?.toDouble();
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
    data['valorUnitario'] = valorUnitario;
    data['desconto'] = desconto;
    data['total'] = total;
    return data;
  }
}

class PedidoVendaHistorico {
  int? id;
  int? versao;
  String? statusAnterior;
  String? statusNovo;
  String? observacao;
  String? data;

  PedidoVendaHistorico({
    this.id,
    this.versao,
    this.statusAnterior,
    this.statusNovo,
    this.observacao,
    this.data,
  });

  PedidoVendaHistorico.fromJson(Map<String, dynamic> json) {
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

class PedidoVenda {
  int? id;
  String? numero;
  int? clienteId;
  String? clienteNome;
  String? dataEmissao;
  String? dataEntrega;
  int? orcamentoId;
  String? orcamentoNumero;
  String? observacao;
  double? descontoGeral;
  double? totalGeral;
  String? status;
  String? origem;
  bool? reservarEstoque;
  List<PedidoVendaItem>? itens;
  List<PedidoVendaHistorico>? historico;

  PedidoVenda({
    this.id,
    this.numero,
    this.clienteId,
    this.clienteNome,
    this.dataEmissao,
    this.dataEntrega,
    this.orcamentoId,
    this.orcamentoNumero,
    this.observacao,
    this.descontoGeral,
    this.totalGeral,
    this.status,
    this.origem,
    this.reservarEstoque,
    this.itens,
    this.historico,
  });

  PedidoVenda.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    numero = json['numero'];
    clienteId = json['clienteId'];
    clienteNome = json['clienteNome'];
    dataEmissao = json['dataEmissao'];
    dataEntrega = json['dataEntrega'];
    orcamentoId = json['orcamentoId'];
    orcamentoNumero = json['orcamentoNumero'];
    observacao = json['observacao'];
    descontoGeral = (json['descontoGeral'] as num?)?.toDouble();
    totalGeral = (json['totalGeral'] as num?)?.toDouble();
    status = json['status'];
    origem = json['origem'];
    reservarEstoque = json['reservarEstoque'];
    if (json['itens'] != null) {
      itens = (json['itens'] as List)
          .map((i) => PedidoVendaItem.fromJson(i))
          .toList();
    }
    if (json['historico'] != null) {
      historico = (json['historico'] as List)
          .map((h) => PedidoVendaHistorico.fromJson(h))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['numero'] = numero;
    data['clienteId'] = clienteId;
    data['clienteNome'] = clienteNome;
    data['dataEmissao'] = dataEmissao;
    data['dataEntrega'] = dataEntrega;
    data['orcamentoId'] = orcamentoId;
    data['orcamentoNumero'] = orcamentoNumero;
    data['observacao'] = observacao;
    data['descontoGeral'] = descontoGeral;
    data['totalGeral'] = totalGeral;
    data['status'] = status;
    data['origem'] = origem;
    data['reservarEstoque'] = reservarEstoque;
    if (itens != null) {
      data['itens'] = itens!.map((i) => i.toJson()).toList();
    }
    if (historico != null) {
      data['historico'] = historico!.map((h) => h.toJson()).toList();
    }
    return data;
  }

  static List<PedidoVenda> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => PedidoVenda.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
