class NfceResultadoModel {
  final int id;
  final String chaveAcesso;
  final String protocolo;
  final String statusSefaz; // AUTORIZADA, REJEITADA, CONTINGENCIA
  final String? codigoRetorno;
  final String? motivoRejeicao;
  final String? qrCodeUrl;
  final String? danfeUrl;
  final DateTime? dataAutorizacao;
  final String? xMotivo;
  final String? dhRecbto;
  final String? tMed;

  const NfceResultadoModel({
    required this.id,
    required this.chaveAcesso,
    required this.protocolo,
    required this.statusSefaz,
    this.codigoRetorno,
    this.motivoRejeicao,
    this.qrCodeUrl,
    this.danfeUrl,
    this.dataAutorizacao,
    this.xMotivo,
    this.dhRecbto,
    this.tMed,
  });

  factory NfceResultadoModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['nfceId'] ?? 0;
    final rawStatus = json['statusSefaz'] ?? json['status'] ?? '';
    final rawDhRecbto = json['dhRecbto']?.toString();
    final motivo = (json['motivoRejeicao'] ?? json['mensagem']) as String?;
    final xMotivo = json['xMotivo']?.toString();

    return NfceResultadoModel(
      id: rawId is num ? rawId.toInt() : int.tryParse(rawId.toString()) ?? 0,
      chaveAcesso: json['chaveAcesso'] as String? ?? '',
      protocolo: json['protocolo'] as String? ?? '',
      statusSefaz: rawStatus.toString().toUpperCase(),
      codigoRetorno: json['codigoRetorno']?.toString() ?? json['cStat']?.toString(),
      motivoRejeicao: motivo,
      qrCodeUrl: json['qrCodeUrl'] as String?,
      danfeUrl: json['danfeUrl'] as String?,
      dataAutorizacao: _parseDateTime(json['dataAutorizacao']?.toString()) ??
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'chaveAcesso': chaveAcesso,
        'protocolo': protocolo,
        'statusSefaz': statusSefaz,
        if (codigoRetorno != null) 'codigoRetorno': codigoRetorno,
        if (motivoRejeicao != null) 'motivoRejeicao': motivoRejeicao,
        if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
        if (danfeUrl != null) 'danfeUrl': danfeUrl,
        if (dataAutorizacao != null)
          'dataAutorizacao': dataAutorizacao!.toIso8601String(),
        if (xMotivo != null) 'xMotivo': xMotivo,
        if (dhRecbto != null) 'dhRecbto': dhRecbto,
        if (tMed != null) 'tMed': tMed,
      };

  String get chaveAcessoFormatada {
    final raw = chaveAcesso.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  bool get isAutorizada => statusSefaz == 'AUTORIZADA';
  bool get isRejeitada => statusSefaz == 'REJEITADA';
  bool get isContingencia => statusSefaz == 'CONTINGENCIA';
}
