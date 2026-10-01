import 'dart:convert';
import '../../../models/parceiro_model.dart';

class Produto {
  int? id;
  int? tipoProdutoId;
  int? produtoId;
  String? descricao;
  List<Foto>? listFotos;
  int? qtdSacos;
  double? vlrSacos;
  int? vendedorId;
  List<Classificacao>? classificacao;
  List<String>? fotos;
  bool? cargaFechada;
  Parceiro? parceiro;
  String? safra;
  String? semente;
  String? tipoGrao;
  String? dataRetirada;
  String? tipoNegociacao;

  Produto({
    this.id,
    this.tipoProdutoId,
    this.produtoId,
    this.descricao,
    this.listFotos,
    this.qtdSacos,
    this.vlrSacos,
    this.vendedorId,
    this.classificacao,
    this.fotos,
    this.cargaFechada,
    this.parceiro,
    this.safra,
    this.semente,
    this.tipoGrao,
    this.dataRetirada,
    this.tipoNegociacao,
  });

  // Método para converter de JSON para a classe Produto
  Produto.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tipoProdutoId = json['tipoProdutoId'];
    produtoId = json['produtoId'];
    descricao = utf8.decode(latin1.encode(json['descricao']));
    qtdSacos = json['qtdSacos'];
    vlrSacos = json['vlrSacos']?.toDouble();
    vendedorId = json['vendedorId'];
    cargaFechada = json['cargaFechada'];
    safra = json['safra'];
    semente = json['semente'] != null
        ? utf8.decode(latin1.encode(json['semente']))
        : "";
    tipoGrao = json['tipoGrao'];
    dataRetirada = json['dtRetirada'];
    tipoNegociacao = json['tiposNegociacoes'] != null
        ? utf8.decode(latin1.encode(json['tiposNegociacoes']))
        : "";
    parceiro = Parceiro.fromJson(json['parceiro']);
    listFotos = json['listFotos'] != null
        ? (json['listFotos'] as List)
            .map((item) => Foto.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : [];
    classificacao = json['classificacao'] != null
        ? (json['classificacao'] as List)
            .map((item) =>
                Classificacao.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : [];
    fotos = json['fotos'] != null
        ? (json['fotos'] as List).map((item) => item.toString()).toList()
        : [];
  }

  // Método para converter Produto para JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['tipoProdutoId'] = tipoProdutoId;
    data['produtoId'] = produtoId;
    data['descricao'] = descricao;
    data['qtdSacos'] = qtdSacos;
    data['vlrSacos'] = vlrSacos;
    data['vendedorId'] = vendedorId;
    data['cargaFechada'] = cargaFechada;
    data['safra'] = safra;
    data['semente'] = semente;
    data['tipoGrao'] = tipoGrao;
    data['dataRetirada'] = dataRetirada;
    data['tipoNegociacao'] = tipoNegociacao;
    if (listFotos != null) {
      data['listFotos'] = listFotos!.map((foto) => foto.toJson()).toList();
    }
    if (classificacao != null) {
      data['classificacao'] =
          classificacao!.map((item) => item.toJson()).toList();
    }
    data['fotos'] = fotos;
    return data;
  }

  // Método para converter uma lista de JSON para uma lista de objetos Produto
  static List<Produto> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Produto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

// Classe para "Foto"
class Foto {
  int? id;
  String? foto;
  bool? principal;

  Foto({this.id, this.foto, this.principal});

  Foto.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    foto = json['foto'];
    principal = json['principal'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['foto'] = foto;
    data['principal'] = principal;
    return data;
  }
}

// Classe para "TipoProduto"
class TipoProduto {
  int? id;
  String? tipoProduto;

  TipoProduto({this.id, this.tipoProduto});

  TipoProduto.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tipoProduto = json['tipoProduto'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['tipoProduto'] = tipoProduto;
    return data;
  }
}

// Classe para "Classificacao"
class Classificacao {
  int? id;
  String? descricao;
  double? valor;
  int? parentId;

  Classificacao({this.id, this.descricao, this.valor, this.parentId});

  Classificacao.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    descricao = json['descricao'];
    valor = json['valor']?.toDouble();
    parentId = json['parentId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['descricao'] = descricao;
    data['valor'] = valor;
    data['parentId'] = parentId;
    return data;
  }

  static List<Classificacao> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Classificacao.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

// Classe para representar a conta principal que contém "tipoProduto" e "valores"
class Account {
  int? id;
  TipoProduto? tipoProduto;
  List<Classificacao>? valores;

  Account({this.id, this.tipoProduto, this.valores});

  Account.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tipoProduto = json['tipoProduto'] != null
        ? TipoProduto.fromJson(json['tipoProduto'])
        : null;
    if (json['valores'] != null) {
      valores = Classificacao.fromJsonList(json['valores']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (tipoProduto != null) {
      data['tipoProduto'] = tipoProduto!.toJson();
    }
    if (valores != null) {
      data['valores'] = valores!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  static List<Account> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((item) => Account.fromJson(item)).toList();
  }
}

// Classe principal para representar a resposta do JSON
class ClassificacaoResponse {
  List<Account>? data;
  bool? error;
  String? message;
  int? status;

  ClassificacaoResponse({this.data, this.error, this.message, this.status});

  ClassificacaoResponse.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null && json['data']['account'] != null) {
      data = Account.fromJsonList(json['data']['account']);
    }
    error = json['response']['error'];
    message = json['response']['message'];
    status = json['response']['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['response'] = {
      'error': error,
      'message': message,
      'status': status,
    };
    return data;
  }
}

// Classe principal para agrupar a lista de produtos e outros dados
class ProdutoModel {
  String? status;
  String? token;
  List<Produto>? produtos;

  ProdutoModel({this.status, this.token, this.produtos});

  ProdutoModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    produtos = json['data'] != null
        ? Produto.fromJsonList(json['data']['account'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (produtos != null) {
      data['data'] = produtos!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}

class ClassificacaoModel {
  String? status;
  String? token;
  List<Classificacao>? classificacao;

  ClassificacaoModel({this.status, this.token, this.classificacao});

  ClassificacaoModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    classificacao = json['data'] != null
        ? Classificacao.fromJsonList(json['data']['account'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (classificacao != null) {
      data['data'] = classificacao!.map((produto) => produto.toJson()).toList();
    }
    return data;
  }
}
