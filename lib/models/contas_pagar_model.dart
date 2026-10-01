class Cotacao {
  int? id;
  String? ativo;
  DateTime? dtCotacao;
  double? valor;

  Cotacao({this.id, this.ativo, this.dtCotacao, this.valor});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cotacaoDTO']['id'] = id;
    data['cotacaoDTO']['ativo'] = ativo;
    data['cotacaoDTO']['dtCotacao'] = dtCotacao?.toIso8601String();
    data['cotacaoDTO']['valor'] = valor;
    return data;
  }

  // Método para converter de JSON para a classe Data
  Cotacao.fromJson(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      id = json['id'];
      ativo = json['ativo'];
      dtCotacao = DateTime.parse(json['dtCotacao']);
      valor = json['valor'];
    }
  }

  // Método para converter uma lista de JSON para uma lista de objetos Data
  static List<Cotacao> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Cotacao.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // Método para converter de JSON para a classe Data
  Cotacao.fromJson2(Map<String, dynamic> json) {
    if (json['cotacaoDTO'] != null && json['cotacaoDTO'].isNotEmpty) {
      var noticiasDTO = json['cotacaoDTO'][0];
      id = noticiasDTO['id'];
      ativo = noticiasDTO['ativo'];
      dtCotacao = DateTime.parse(noticiasDTO['dtCotacao']);
      valor = noticiasDTO['valor'];
    }
  }

  // Método para converter uma lista de JSON para uma lista de objetos Data
  static List<Cotacao> fromJsonList2(List<Map<String, dynamic>> jsonList) {
    List<Cotacao> dataList = [];
    for (var json in jsonList) {
      // dataList.add(Data.fromJson(json));
    }
    return dataList;
  }
}

class CotacaoModel {
  String? status;
  String? token;
  List<Cotacao>? data;

  CotacaoModel({this.status, this.token, this.data});

  CotacaoModel.fromJson(Map<String, dynamic> json) {
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
      List<Cotacao> dataList =
          Cotacao.fromJsonList(json['data']['cotacoesDTO']);
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
