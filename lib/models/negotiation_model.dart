import 'dart:convert';

class Negotiation {
  final int id;
  final int compradorId;
  final int vendedorId;
  final int qtdSacos;
  final double vlrSacos;
  final String dataNegociacao;
  final String status;
  final String tipo;
  final String bairroEntr;
  final String cidadeEntr;
  final String estadoEntr;
  final String bairroSaida;
  final String cidadeSaida;
  final String estadoSaida;

  Negotiation({
    required this.id,
    required this.compradorId,
    required this.vendedorId,
    required this.qtdSacos,
    required this.vlrSacos,
    required this.dataNegociacao,
    required this.status,
    required this.tipo,
    required this.bairroEntr,
    required this.cidadeEntr,
    required this.estadoEntr,
    required this.bairroSaida,
    required this.cidadeSaida,
    required this.estadoSaida,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse fields with default values
    T safeParse<T>(dynamic value, T defaultValue) {
      if (value == null || value is! T) {
        return defaultValue;
      }
      return value;
    }

    return Negotiation(
      id: safeParse<int>(json['id'], 0),
      compradorId: safeParse<int>(json['compradorId'], 0),
      vendedorId: safeParse<int>(json['vendedorId'], 0),
      qtdSacos: safeParse<int>(json['qtdSacos'], 0),
      vlrSacos: safeParse<double>(json['vlrSacos'], 0.0),
      dataNegociacao: safeParse<String>(json['dataNegociacao'], ''),
      status: safeParse<String>(json['status'], ''),
      tipo: safeParse<String>(json['tipo'], ''),
      bairroEntr:
          safeParse<String>(utf8.decode(latin1.encode(json['bairroEntr'])), ''),
      cidadeEntr:
          safeParse<String>(utf8.decode(latin1.encode(json['cidadeEntr'])), ''),
      estadoEntr: safeParse<String>(json['estadoEntr'], ''),
      bairroSaida: safeParse<String>(
          utf8.decode(latin1
              .encode(json['bairroSaida'] ?? '')),
          ''),
      cidadeSaida: safeParse<String>(
          utf8.decode(latin1.encode(json['cidadeSaida'] ?? '')), ''),
      estadoSaida: safeParse<String>(json['estadoSaida'] ?? '', ''),
    );
  }

  // Método para converter Produto para JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['compradorId'] = compradorId;
    data['vendedorId'] = vendedorId;
    data['qtdSacos'] = qtdSacos;
    data['vlrSacos'] = vlrSacos;
    data['dataNegociacao'] = dataNegociacao;
    data['status'] = status;
    data['tipo'] = tipo;
    data['bairroEntr'] = bairroEntr;
    data['cidadeEntr'] = cidadeEntr;
    data['estadoEntr'] = estadoEntr;
    data['bairroSaida'] = bairroSaida;
    data['cidadeSaida'] = cidadeSaida;
    data['estadoSaida'] = estadoSaida;
    return data;
  }

  // Método para converter uma lista de JSON para uma lista de objetos Produto
  static List<Negotiation> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Negotiation.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class Product {
  final int id;
  final String tipo;
  final String descricao;
  final double vlrSacos;
  final int qtdSacos;
  final String? dtRetirada;
  final String? foto;
  final List<Negotiation> negociacoes;

  Product({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.vlrSacos,
    required this.qtdSacos,
    this.dtRetirada,
    this.foto,
    required this.negociacoes,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      tipo: json['tipo'],
      descricao: utf8.decode(latin1.encode(json['descricao'])),
      vlrSacos: json['vlrSacos'],
      qtdSacos: json['qtdSacos'],
      dtRetirada: json['dtRetirada'],
      foto: json['foto'],
      negociacoes: (json['negociacoes'] as List)
          .map((n) => Negotiation.fromJson(n))
          .toList(),
    );
  }

  // Método para converter uma lista de JSON para uma lista de objetos Produto
  static List<Product> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // Método para converter Produto para JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['tipo'] = tipo;
    data['descricao'] = descricao;
    data['vlrSacos'] = vlrSacos;
    data['qtdSacos'] = qtdSacos;
    data['dtRetirada'] = dtRetirada;
    data['foto'] = foto;
    data['negociacoes'] = negociacoes.map((item) => item.toJson()).toList();
      return data;
  }
}

class ProductResponse {
  final List<Product> account;
  final ResponseStatus response;

  ProductResponse({
    required this.account,
    required this.response,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      account: (json['data']['account'] as List)
          .map((p) => Product.fromJson(p))
          .toList(),
      response: ResponseStatus.fromJson(json['response']),
    );
  }
}

// Classe principal para agrupar a lista de produtos e outros dados
class ProductModel {
  String? status;
  String? token;
  List<Product>? produtos;

  ProductModel({this.status, this.token, this.produtos});

  ProductModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    produtos = json['data'] != null
        ? Product.fromJsonList(json['data']['account'])
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

class ResponseStatus {
  final bool error;
  final String message;
  final int status;

  ResponseStatus({
    required this.error,
    required this.message,
    required this.status,
  });

  factory ResponseStatus.fromJson(Map<String, dynamic> json) {
    return ResponseStatus(
      error: json['error'],
      message: json['message'],
      status: json['status'],
    );
  }
}

class RenegotiationModel {
  String? status;
  String? token;
  List<Negotiation>? negotiation;

  RenegotiationModel({this.status, this.token, this.negotiation});

  RenegotiationModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    negotiation = json['data'] != null
        ? Negotiation.fromJsonList(json['data']['account'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (negotiation != null) {
      data['data'] =
          negotiation!.map((negotiation) => negotiation.toJson()).toList();
    }
    return data;
  }
}
