import 'setor_model.dart';

class Comunicado {
  int? id;
  String? titulo;
  String? conteudo;
  String? autor;
  Map<String, dynamic>? empresa;
  Map<String, dynamic>? aplicativo;
  Setor? setor;
  DateTime? dataPublicacao;
  DateTime? dhCreatedAt;

  Comunicado({
    this.id,
    this.titulo,
    this.conteudo,
    this.autor,
    this.empresa,
    this.aplicativo,
    this.setor,
    this.dataPublicacao,
    this.dhCreatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'conteudo': conteudo,
      'autor': autor,
      if (empresa != null) 'empresa': empresa,
      if (aplicativo != null) 'aplicativo': aplicativo,
      if (setor != null) 'setor': setor?.toJson(),
      if (dataPublicacao != null) 'dataPublicacao': dataPublicacao?.toIso8601String(),
    };
  }

  factory Comunicado.fromJson(Map<String, dynamic> json) {
    return Comunicado(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      conteudo: json['conteudo'] ?? '',
      autor: json['autor'] ?? '',
      empresa: json['empresa'] is Map ? Map<String, dynamic>.from(json['empresa']) : null,
      aplicativo: json['aplicativo'] is Map ? Map<String, dynamic>.from(json['aplicativo']) : null,
      setor: json['setor'] != null ? Setor.fromJson(json['setor']) : null,
      dataPublicacao: json['dataPublicacao'] != null
          ? DateTime.tryParse(json['dataPublicacao'])
          : null,
      dhCreatedAt: json['dhCreatedAt'] != null
          ? DateTime.tryParse(json['dhCreatedAt'])
          : null,
    );
  }

  static List<Comunicado> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => Comunicado.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
