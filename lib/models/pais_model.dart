class PaisModel {
  int? id;
  String? nome;
  String? nomePt;
  String? iso2;
  String? iso3;
  int? bacen;

  PaisModel({
    this.id,
    this.nome,
    this.nomePt,
    this.iso2,
    this.iso3,
    this.bacen,
  });

  factory PaisModel.fromJson(Map<String, dynamic> json) {
    return PaisModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      nome: json['nome'],
      nomePt: json['nomePt'],
      iso2: json['iso2'],
      iso3: json['iso3'],
      bacen: json['bacen'] is int
          ? json['bacen']
          : int.tryParse(json['bacen']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'nomePt': nomePt,
      'iso2': iso2,
      'iso3': iso3,
      'bacen': bacen,
    };
  }

  @override
  String toString() => nome ?? '-';
}
