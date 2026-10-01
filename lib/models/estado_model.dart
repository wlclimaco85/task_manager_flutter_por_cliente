import '../models/pais_model.dart';

class EstadoModel {
  int? id;
  String? nome;
  String? uf;
  int? ibge;
  PaisModel? pais;
  String? ddd;

  EstadoModel({
    this.id,
    this.nome,
    this.uf,
    this.ibge,
    this.pais,
    this.ddd,
  });

  factory EstadoModel.fromJson(Map<String, dynamic> json) {
    return EstadoModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      nome: json['nome'],
      uf: json['uf'],
      ibge: json['ibge'] is int
          ? json['ibge']
          : int.tryParse(json['ibge']?.toString() ?? ''),
      pais: json['pais'] != null ? PaisModel.fromJson(json['pais']) : null,
      ddd: json['ddd'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'uf': uf,
      'ibge': ibge,
      if (pais != null) 'pais': pais!.toJson(),
      'ddd': ddd,
    };
  }

  @override
  String toString() => '$nome (${uf ?? ""})';
}
