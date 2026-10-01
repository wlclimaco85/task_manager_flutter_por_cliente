class Dollar {
  int? id;
  DateTime? date;
  double? rate;

  Dollar({this.id, this.date, this.rate});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['DollarDTO']['id'] = id;
    data['DollarDTO']['date'] = date?.toIso8601String();
    data['DollarDTO']['rate'] = rate;
    return data;
  }

  // Método para converter de JSON para a classe Data
  Dollar.fromJson(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      id = json['id'];
      date = DateTime.parse(json['date']);
      rate = json['rate'];
    }
  }

  // Método para converter uma lista de JSON para uma lista de objetos Data
  static List<Dollar> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Dollar.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // Método para converter de JSON para a classe Data
  Dollar.fromJson2(Map<String, dynamic> json) {
    if (json['DollarDTO'] != null && json['DollarDTO'].isNotEmpty) {
      var noticiasDTO = json['DollarDTO'][0];
      id = noticiasDTO['id'];
      date = DateTime.parse(noticiasDTO['date']);
      rate = noticiasDTO['rate'];
    }
  }

  // Método para converter uma lista de JSON para uma lista de objetos Data
  static List<Dollar> fromJsonList2(List<Map<String, dynamic>> jsonList) {
    List<Dollar> dataList = [];
    for (var json in jsonList) {
      // dataList.add(Data.fromJson(json));
    }
    return dataList;
  }
}

class DollarModel {
  String? status;
  String? token;
  List<Dollar>? data;

  DollarModel({this.status, this.token, this.data});

  DollarModel.fromJson(Map<String, dynamic> json) {
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
      List<Dollar> dataList = Dollar.fromJsonList(json['data']['cotacoesDTO']);
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
