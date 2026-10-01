import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Exercicio {
  int? id;
  int? codTipoExerc;
  int? codGrupMusc;
  String? nome;
  String? linkVideo;
  int? nivel;
  String? foto;
  String? linkDoc;
  String? descricao;

  Exercicio({
    this.id,
    this.codTipoExerc,
    this.codGrupMusc,
    this.nome,
    this.linkVideo,
    this.nivel,
    this.foto,
    this.linkDoc,
    this.descricao,
  });

  Exercicio.fromJson(Map<String, dynamic> json) {
    id = _asInt(json['id']);
    codTipoExerc = _asInt(json['codTipoExerc'] ?? json['tipo']);
    codGrupMusc = _asInt(
      json['codGrupMusc'] ??
          json['grupoMuscularId'] ??
          _nestedId(json['grupoMuscular']),
    );
    nome = json['nome'];
    linkVideo = json['linkVideo'];
    nivel = _asInt(json['nivel']);
    foto = json['foto'] ?? json['thumbnail'];
    linkDoc = json['linkDoc'];
    descricao = json['descricao'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codTipoExerc': codTipoExerc,
      'codGrupMusc': codGrupMusc,
      'nome': nome,
      'linkVideo': linkVideo,
      'nivel': nivel,
      'foto': foto,
      'linkDoc': linkDoc,
      'descricao': descricao,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static dynamic _nestedId(dynamic value) {
    if (value is Map) return value['id'];
    return null;
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.fitness_center,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Tipo de Exercicio",
      fieldName: "codTipoExerc",
      icon: Icons.category,
      fieldType: FieldType.number,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Grupo Muscular",
      fieldName: "codGrupMusc",
      icon: Icons.group,
      fieldType: FieldType.number,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Nivel",
      fieldName: "nivel",
      icon: Icons.trending_up,
      fieldType: FieldType.number,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Link do Video",
      fieldName: "linkVideo",
      icon: Icons.play_circle_outline,
      fieldType: FieldType.url,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Link do Documento",
      fieldName: "linkDoc",
      icon: Icons.description_outlined,
      fieldType: FieldType.url,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Foto/Thumbnail",
      fieldName: "foto",
      icon: Icons.image_outlined,
      fieldType: FieldType.url,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Descricao",
      fieldName: "descricao",
      icon: Icons.description,
      fieldType: FieldType.multiline,
      maxLines: 3,
      isInForm: true,
    ),
  ];
}
