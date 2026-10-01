import 'package:flutter/material.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';

import '../customization/generic_grid_card.dart';

class FileAttachment {
  int? id;
  String fileName;
  String fileType;
  DateTime uploadDate;
  int? diretorioId;
  int empresaId;

  FileAttachment({
    this.id,
    required this.fileName,
    required this.fileType,
    required this.uploadDate,
    this.diretorioId,
    required this.empresaId,
  });

  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    return FileAttachment(
      id: json['id'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      uploadDate: DateTime.parse(json['uploadDate']) ?? DateTime.now(),
      diretorioId: json['diretorioId'],
      empresaId: json['empresaId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileType': fileType,
      'uploadDate': uploadDate.toIso8601String(),
      'diretorioId': diretorioId,
      'empresaId': empresaId,
    };
  }

  static Future<List<Map<String, dynamic>>> loadCategorias() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.getCategorias,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['account'] ?? [];
      return data
          .map(
            (item) => {
              'value': item['id'].toString(),
              'label': item['descricao'],
            },
          )
          .toList();
    }
    return [];
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome do Arquivo",
      fieldName: "fileName",
      icon: Icons.file_present,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Tipo",
      fieldName: "fileType",
      icon: Icons.type_specimen,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Data de Upload",
      fieldName: "uploadDate",
      icon: Icons.calendar_today,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Diretório",
      fieldName: "diretorioId",
      displayFieldName: "diretorio.nome",
      icon: Icons.folder,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return await loadDiretorios();
      },
      dropdownValueField: 'id',
      dropdownDisplayField: 'nome',
      isRequired: false,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Empresa",
      fieldName: "empresaId",
      displayFieldName: "empresa.nome",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return await loadCategorias();
      },
      dropdownValueField: 'id',
      dropdownDisplayField: 'nome',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
  ];

  static Future<List<Map<String, dynamic>>> loadDiretorios() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allDiretorios,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'].toString(), 'label': item['nome']},
          )
          .toList();
    }
    return [];
  }
}
