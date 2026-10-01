import 'package:intl/intl.dart';

class Audit {
  final DateTime? dataCreated;
  final DateTime? dataUpdated;

  Audit({this.dataCreated, this.dataUpdated});

  factory Audit.fromJson(Map<String, dynamic> json) {
    return Audit(
      dataCreated: json['dataCreated'] != null
          ? DateTime.tryParse(json['dataCreated'])
          : null,
      dataUpdated: json['dataUpdated'] != null
          ? DateTime.tryParse(json['dataUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataCreated': dataCreated?.toIso8601String(),
      'dataUpdated': dataUpdated?.toIso8601String(),
    };
  }

  /// 🔹 Métodos auxiliares para exibir formatado (dd/MM/yyyy HH:mm)
  String get dataCreatedFormatada {
    return dataCreated != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dataCreated!)
        : '';
  }

  String get dataUpdatedFormatada {
    return dataUpdated != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dataUpdated!)
        : '';
  }
}
