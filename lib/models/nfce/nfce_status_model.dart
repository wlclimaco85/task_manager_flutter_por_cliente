class NfceStatusModel {
  final int id;
  final String status; // AUTORIZADA, REJEITADA, CONTINGENCIA, PENDENTE
  final String? mensagem;
  final String? protocolo;
  final String? codigoRetorno;
  final String? motivoRejeicao;
  final DateTime? dataConsulta;
  final String? xMotivo;
  final String? dhRecbto;
  final String? tMed;

  const NfceStatusModel({
    required this.id,
    required this.status,
    this.mensagem,
    this.protocolo,
    this.codigoRetorno,
    this.motivoRejeicao,
    this.dataConsulta,
    this.xMotivo,
    this.dhRecbto,
    this.tMed,
  });

  factory NfceStatusModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['nfceId'] ?? 0;
    final rawStatus = json['status'] ?? json['statusSefaz'] ?? 'PENDENTE';
    final motivo = json['motivoRejeicao']?.toString();
    final xMotivo = json['xMotivo']?.toString();
    final rawDhRecbto = json['dhRecbto']?.toString();
    final mensagem = json['mensagem']?.toString() ?? xMotivo ?? motivo;

    return NfceStatusModel(
      id: rawId is num ? rawId.toInt() : int.tryParse(rawId.toString()) ?? 0,
      status: rawStatus.toString().toUpperCase(),
      mensagem: mensagem,
      protocolo: json['protocolo']?.toString(),
      codigoRetorno: json['codigoRetorno']?.toString() ?? json['cStat']?.toString(),
      motivoRejeicao: motivo,
      dataConsulta: _parseDateTime(json['dataConsulta']?.toString()) ??
          _parseDateTime(rawDhRecbto),
      xMotivo: xMotivo,
      dhRecbto: rawDhRecbto,
      tMed: json['tMed']?.toString(),
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  bool get isAutorizada => status == 'AUTORIZADA';
  bool get isRejeitada => status == 'REJEITADA';
  bool get isContingencia => status == 'CONTINGENCIA';
  bool get isPendente => status == 'PENDENTE';
}
