import 'package:equatable/equatable.dart';

/// Entidade de domínio: Agendamento de NFe recorrente
class AgendamentoEntity extends Equatable {
  final String? id;
  final String nfeId;
  final String rrule; // RFC 5545: FREQ=MONTHLY;BYDAY=1MO;...
  final List<DateTime> proximasOcorrencias; // Next 5 dates
  final String status; // PENDING, ENVIADO, FALHA, PROCESSADO
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  const AgendamentoEntity({
    this.id,
    required this.nfeId,
    required this.rrule,
    required this.proximasOcorrencias,
    required this.status,
    this.criadoEm,
    this.atualizadoEm,
  });

  bool get isValid => rrule.isNotEmpty && status.isNotEmpty;

  bool get isPending => status == 'PENDING';

  bool get isSent => status == 'ENVIADO';

  bool get isFailure => status == 'FALHA';

  @override
  List<Object?> get props => [
        id,
        nfeId,
        rrule,
        proximasOcorrencias,
        status,
        criadoEm,
        atualizadoEm,
      ];
}
