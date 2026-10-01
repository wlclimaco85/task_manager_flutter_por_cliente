import 'package:task_manager_flutter/features/agendamento/domain/entities/agendamento_entity.dart';

/// Model para serialização JSON
class AgendamentoModel extends AgendamentoEntity {
  const AgendamentoModel({
    String? id,
    required String nfeId,
    required String rrule,
    required List<DateTime> proximasOcorrencias,
    required String status,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) : super(
    id: id,
    nfeId: nfeId,
    rrule: rrule,
    proximasOcorrencias: proximasOcorrencias,
    status: status,
    criadoEm: criadoEm,
    atualizadoEm: atualizadoEm,
  );

  factory AgendamentoModel.fromJson(Map<String, dynamic> json) {
    return AgendamentoModel(
      id: json['id'] as String?,
      nfeId: json['nfeId'] as String? ?? '',
      rrule: json['rrule'] as String? ?? '',
      proximasOcorrencias: _parseProximasOcorrencias(json['proximasOcorrencias']),
      status: json['status'] as String? ?? 'PENDING',
      criadoEm: json['criadoEm'] != null ? DateTime.parse(json['criadoEm']) : null,
      atualizadoEm: json['atualizadoEm'] != null ? DateTime.parse(json['atualizadoEm']) : null,
    );
  }

  factory AgendamentoModel.fromEntity(AgendamentoEntity entity) {
    return AgendamentoModel(
      id: entity.id,
      nfeId: entity.nfeId,
      rrule: entity.rrule,
      proximasOcorrencias: entity.proximasOcorrencias,
      status: entity.status,
      criadoEm: entity.criadoEm,
      atualizadoEm: entity.atualizadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nfeId': nfeId,
      'rrule': rrule,
      'proximasOcorrencias': proximasOcorrencias
          .map((date) => date.toIso8601String())
          .toList(),
      'status': status,
      'criadoEm': criadoEm?.toIso8601String(),
      'atualizadoEm': atualizadoEm?.toIso8601String(),
    };
  }

  static List<DateTime> _parseProximasOcorrencias(dynamic data) {
    if (data is List) {
      return data
          .map((e) {
            try {
              return DateTime.parse(e.toString());
            } catch (e) {
              return DateTime.now();
            }
          })
          .toList();
    }
    return [];
  }

  AgendamentoModel copyWith({
    String? id,
    String? nfeId,
    String? rrule,
    List<DateTime>? proximasOcorrencias,
    String? status,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return AgendamentoModel(
      id: id ?? this.id,
      nfeId: nfeId ?? this.nfeId,
      rrule: rrule ?? this.rrule,
      proximasOcorrencias: proximasOcorrencias ?? this.proximasOcorrencias,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
