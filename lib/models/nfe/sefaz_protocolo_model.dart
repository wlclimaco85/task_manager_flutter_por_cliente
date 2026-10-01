/// Modelo que representa a resposta/protocolo da SEFAZ
class SefazProtocoloModel {
  final String protocolo;
  final String statusSefaz; // Código de status SEFAZ (100, 101, 102, etc)
  final String statusMensagem;
  final DateTime? dataHoraSefaz;
  final String? xmlResposta;

  const SefazProtocoloModel({
    required this.protocolo,
    required this.statusSefaz,
    required this.statusMensagem,
    this.dataHoraSefaz,
    this.xmlResposta,
  });

  /// Cria instância a partir de JSON
  factory SefazProtocoloModel.fromJson(Map<String, dynamic> json) {
    return SefazProtocoloModel(
      protocolo: json['protocolo']?.toString() ?? '',
      statusSefaz: json['statusSefaz']?.toString() ?? json['cStat']?.toString() ?? '',
      statusMensagem: json['statusMensagem']?.toString() ?? json['xMotivo']?.toString() ?? '',
      dataHoraSefaz: _parseDateTime(json['dataHoraSefaz']?.toString() ?? json['dhRecbto']?.toString()),
      xmlResposta: json['xmlResposta']?.toString(),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'protocolo': protocolo,
    'statusSefaz': statusSefaz,
    'statusMensagem': statusMensagem,
    if (dataHoraSefaz != null) 'dataHoraSefaz': dataHoraSefaz?.toIso8601String(),
    if (xmlResposta != null) 'xmlResposta': xmlResposta,
  };

  /// Verifica se protocolo foi autorizado (código 100)
  bool get isAutorizado => statusSefaz == '100';

  /// Verifica se há rejeição
  bool get isRejeitado => statusSefaz.startsWith('1') && statusSefaz != '100';

  /// Extrai helper para parsing de data
  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }
}
