import 'empresa_model.dart';

class EmpresaAcesso {
  final int? id;
  final int? loginId;
  final String? loginNome;
  final String? loginEmail;
  final int empresaId;
  final String empresaNome;
  final int? parceiroId;
  final String? parceiroNome;
  final String status;
  final bool ativa;
  final DateTime? solicitadoEm;
  final int? aprovadoPorLoginId;
  final DateTime? aprovadoEm;

  const EmpresaAcesso({
    this.id,
    this.loginId,
    this.loginNome,
    this.loginEmail,
    required this.empresaId,
    required this.empresaNome,
    this.parceiroId,
    this.parceiroNome,
    required this.status,
    required this.ativa,
    this.solicitadoEm,
    this.aprovadoPorLoginId,
    this.aprovadoEm,
  });

  factory EmpresaAcesso.fromJson(Map<String, dynamic> json) {
    return EmpresaAcesso(
      id: _asInt(json['id']),
      loginId: _asInt(json['loginId']),
      loginNome: json['loginNome']?.toString(),
      loginEmail: json['loginEmail']?.toString(),
      empresaId: _asInt(json['empresaId']) ?? 0,
      empresaNome: json['empresaNome']?.toString() ?? '',
      parceiroId: _asInt(json['parceiroId']),
      parceiroNome: json['parceiroNome']?.toString(),
      status: json['status']?.toString() ?? '',
      ativa: json['ativa'] == true,
      solicitadoEm: _asDate(json['solicitadoEm']),
      aprovadoPorLoginId: _asInt(json['aprovadoPorLoginId']),
      aprovadoEm: _asDate(json['aprovadoEm']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'loginId': loginId,
        'loginNome': loginNome,
        'loginEmail': loginEmail,
        'empresaId': empresaId,
        'empresaNome': empresaNome,
        'parceiroId': parceiroId,
        'parceiroNome': parceiroNome,
        'status': status,
        'ativa': ativa,
        'solicitadoEm': solicitadoEm?.toIso8601String(),
        'aprovadoPorLoginId': aprovadoPorLoginId,
        'aprovadoEm': aprovadoEm?.toIso8601String(),
      };

  Empresa toEmpresa() => Empresa(id: empresaId, nome: empresaNome);

  bool get aprovado => status.toUpperCase() == 'APROVADO';
  bool get pendente => status.toUpperCase() == 'PENDENTE';

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
