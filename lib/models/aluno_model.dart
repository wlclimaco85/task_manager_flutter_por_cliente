class AlunoModel {
  final int? id;
  AlunoModel({this.id});
  factory AlunoModel.fromJson(Map<String, dynamic> json) => AlunoModel(id: json['id'] as int?);
  Map<String, dynamic> toJson() => {if (id != null) 'id': id};
}
