class DevolucaoItem {
  int? id;
  int? produtoId;
  String? produtoNome;
  double? quantidade;
  double? valorUnitario;
  String? motivo;

  DevolucaoItem({
    this.id,
    this.produtoId,
    this.produtoNome,
    this.quantidade,
    this.valorUnitario,
    this.motivo,
  });

  DevolucaoItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    produtoId = json['produtoId'];
    produtoNome = json['produtoNome'];
    quantidade = (json['quantidade'] as num?)?.toDouble();
    valorUnitario = (json['valorUnitario'] as num?)?.toDouble();
    motivo = json['motivo'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['produtoId'] = produtoId;
    data['produtoNome'] = produtoNome;
    data['quantidade'] = quantidade;
    data['valorUnitario'] = valorUnitario;
    data['motivo'] = motivo;
    return data;
  }
}

class Devolucao {
  int? id;
  String? numero;
  String? data;
  String? tipo;
  int? documentoOrigemId;
  String? documentoOrigemNumero;
  String? documentoOrigemTipo;
  int? clienteFornecedorId;
  String? clienteFornecedorNome;
  String? motivo;
  String? observacao;
  String? status;
  List<DevolucaoItem>? itens;

  Devolucao({
    this.id,
    this.numero,
    this.data,
    this.tipo,
    this.documentoOrigemId,
    this.documentoOrigemNumero,
    this.documentoOrigemTipo,
    this.clienteFornecedorId,
    this.clienteFornecedorNome,
    this.motivo,
    this.observacao,
    this.status,
    this.itens,
  });

  Devolucao.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    numero = json['numero'];
    data = json['data'];
    tipo = json['tipo'];
    documentoOrigemId = json['documentoOrigemId'];
    documentoOrigemNumero = json['documentoOrigemNumero'];
    documentoOrigemTipo = json['documentoOrigemTipo'];
    clienteFornecedorId = json['clienteFornecedorId'];
    clienteFornecedorNome = json['clienteFornecedorNome'];
    motivo = json['motivo'];
    observacao = json['observacao'];
    status = json['status'];
    if (json['itens'] != null) {
      itens = (json['itens'] as List)
          .map((i) => DevolucaoItem.fromJson(i))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['numero'] = numero;
    data['data'] = this.data;
    data['tipo'] = tipo;
    data['documentoOrigemId'] = documentoOrigemId;
    data['documentoOrigemNumero'] = documentoOrigemNumero;
    data['documentoOrigemTipo'] = documentoOrigemTipo;
    data['clienteFornecedorId'] = clienteFornecedorId;
    data['clienteFornecedorNome'] = clienteFornecedorNome;
    data['motivo'] = motivo;
    data['observacao'] = observacao;
    data['status'] = status;
    if (itens != null) {
      data['itens'] = itens!.map((i) => i.toJson()).toList();
    }
    return data;
  }

  static List<Devolucao> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Devolucao.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
