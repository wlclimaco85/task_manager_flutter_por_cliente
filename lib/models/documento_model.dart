class Documento {
  final int id;
  final DateTime dataDocumento;
  final String descricao;
  final double valor;
  final String status;
  bool lido;

  Documento({
    required this.id,
    required this.dataDocumento,
    required this.descricao,
    required this.valor,
    this.status = 'PENDENTE',
    this.lido = false,
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      id: json['id'],
      dataDocumento: DateTime.parse(json['dataDocumento']),
      descricao: json['descricao'],
      valor: json['valor'].toDouble(),
      status: json['status'] ?? 'PENDENTE',
      lido: json['lido'] ?? false,
    );
  }

  // Método para converter uma lista de JSON para uma lista de objetos Data
  static List<Documento> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Documento.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dataDocumento': dataDocumento.toIso8601String(),
      'descricao': descricao,
      'valor': valor,
      'status': status,
      'lido': lido,
    };
  }
}

class DocumentoModel {
  String? status;
  String? token;
  List<Documento>? data;

  DocumentoModel({this.status, this.token, this.data});

  DocumentoModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];

    // Verifica se 'data' é uma lista de listas
    if (json['data'] != null) {
      /*  data = [];
    // Itera sobre cada lista no 'data'
    for (var list in json['data']) {
      // Adiciona à lista de 'data' uma lista de Map<String, dynamic>
      data.add(List<Map<String, dynamic>>.from(list.map((item) => Map<String, dynamic>.from(item))));
    } */
      //  List<Data> dataList = Data.fromJsonList2(json['data']['noticiasDTO']);
      List<Documento> dataList = Documento.fromJsonList(json['data']['dados']);
      data =
          dataList; //json['data'] != null ? Data.fromJson(json['data']) : null;
    } else {
      data = null;
    }

    //data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  /* Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }*/

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (this.data != null) {
      // Mapeia cada item da lista 'data' para o formato JSON
      data['data'] = this.data!.map((item) => item.toJson()).toList();
    }
    return data;
  }
}
