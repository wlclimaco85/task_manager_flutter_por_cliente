import '../models/estado_model.dart';

class CidadeModel {
  int? id;
  String? nome;
  int? ibge;
  String? latLon;
  EstadoModel? estado;

  CidadeModel({
    this.id,
    this.nome,
    this.ibge,
    this.latLon,
    this.estado,
  });

  factory CidadeModel.fromJson(Map<String, dynamic> json) {
    return CidadeModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      nome: json['nome'],
      ibge: json['ibge'] is int
          ? json['ibge']
          : int.tryParse(json['ibge']?.toString() ?? ''),
      latLon: json['latLon'],
      estado:
          json['estado'] != null ? EstadoModel.fromJson(json['estado']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'ibge': ibge,
      'latLon': latLon,
      if (estado != null) 'estado': estado!.toJson(),
    };
  }

  @override
  String toString() => nome ?? '-';
}
