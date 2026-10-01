class Academia {
  int? id;
  String? observacao;

  Academia({this.id, this.observacao});

  Academia.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    observacao = json['observacao'];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'observacao': observacao,
  };
}
