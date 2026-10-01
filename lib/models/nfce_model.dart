class NfceModel {
  final int id;
  final int? empresaId;
  final String? empresaNome;
  final int? parceiroId;
  final String? chaveAcesso;
  final int? numero;
  final int? serie;
  final String? uf;
  final String? ambiente;
  final String statusSefaz;
  final String? protocolo;
  final String? codigoRetorno;
  final String? motivoRejeicao;
  final bool xmlEnviadoDisponivel;
  final bool xmlAutorizadoDisponivel;
  final String? danfeUrl;
  final int? vendaId;
  final double? valorTotal;
  final DateTime? dataEmissao;
  final DateTime? dataAutorizacao;
  final DateTime? dataContingencia;
  final String? tpEmis;
  final String? justificativaContingencia;
  final String? numeroReciboEpec;
  final String? protocoloEpec;
  final DateTime? dataEpec;
  final String? modelo;

  const NfceModel({
    required this.id,
    this.empresaId,
    this.empresaNome,
    this.parceiroId,
    this.chaveAcesso,
    this.numero,
    this.serie,
    this.uf,
    this.ambiente,
    required this.statusSefaz,
    this.protocolo,
    this.codigoRetorno,
    this.motivoRejeicao,
    this.xmlEnviadoDisponivel = false,
    this.xmlAutorizadoDisponivel = false,
    this.danfeUrl,
    this.vendaId,
    this.valorTotal,
    this.dataEmissao,
    this.dataAutorizacao,
    this.dataContingencia,
    this.tpEmis,
    this.justificativaContingencia,
    this.numeroReciboEpec,
    this.protocoloEpec,
    this.dataEpec,
    this.modelo,
  });

  factory NfceModel.fromJson(Map<String, dynamic> json) {
    return NfceModel(
      id: json['id'] ?? 0,
      empresaId: _toInt(json['empresaId'] ?? json['empresa']?['id']),
      empresaNome: json['empresaNome']?.toString() ?? json['empresa']?['nome']?.toString(),
      parceiroId: _toInt(json['parceiroId']),
      chaveAcesso: json['chaveAcesso'],
      numero: _toInt(json['numero']),
      serie: _toInt(json['serie']),
      uf: json['uf']?.toString(),
      ambiente: json['ambiente']?.toString(),
      statusSefaz: json['statusSefaz'] ?? 'PENDENTE',
      protocolo: json['protocolo'],
      codigoRetorno: json['codigoRetorno']?.toString(),
      motivoRejeicao: json['motivoRejeicao'],
      xmlEnviadoDisponivel: _toBool(json['xmlEnviadoDisponivel']),
      xmlAutorizadoDisponivel: _toBool(json['xmlAutorizadoDisponivel']),
      danfeUrl: json['danfeUrl'],
      vendaId: _toInt(json['vendaId']),
      valorTotal: json['valorTotal'] != null ? double.tryParse(json['valorTotal'].toString()) : null,
      dataEmissao: json['dataEmissao'] != null ? DateTime.tryParse(json['dataEmissao'].toString()) : null,
      dataAutorizacao: json['dataAutorizacao'] != null ? DateTime.tryParse(json['dataAutorizacao'].toString()) : null,
      dataContingencia: json['dataContingencia'] != null ? DateTime.tryParse(json['dataContingencia'].toString()) : null,
      tpEmis: json['tpEmis']?.toString(),
      justificativaContingencia: json['justificativaContingencia']?.toString(),
      numeroReciboEpec: json['numeroReciboEpec']?.toString(),
      protocoloEpec: json['protocoloEpec']?.toString(),
      dataEpec: json['dataEpec'] != null ? DateTime.tryParse(json['dataEpec'].toString()) : null,
      modelo: json['modelo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (empresaId != null) 'empresaId': empresaId,
      if (empresaNome != null) 'empresaNome': empresaNome,
      if (parceiroId != null) 'parceiroId': parceiroId,
      if (chaveAcesso != null) 'chaveAcesso': chaveAcesso,
      if (numero != null) 'numero': numero,
      if (serie != null) 'serie': serie,
      if (uf != null) 'uf': uf,
      if (ambiente != null) 'ambiente': ambiente,
      'statusSefaz': statusSefaz,
      if (protocolo != null) 'protocolo': protocolo,
      if (codigoRetorno != null) 'codigoRetorno': codigoRetorno,
      if (motivoRejeicao != null) 'motivoRejeicao': motivoRejeicao,
      'xmlEnviadoDisponivel': xmlEnviadoDisponivel,
      'xmlAutorizadoDisponivel': xmlAutorizadoDisponivel,
      if (danfeUrl != null) 'danfeUrl': danfeUrl,
      if (vendaId != null) 'vendaId': vendaId,
      if (valorTotal != null) 'valorTotal': valorTotal,
      if (dataEmissao != null) 'dataEmissao': dataEmissao?.toIso8601String(),
      if (dataAutorizacao != null) 'dataAutorizacao': dataAutorizacao?.toIso8601String(),
      if (dataContingencia != null) 'dataContingencia': dataContingencia?.toIso8601String(),
      if (tpEmis != null) 'tpEmis': tpEmis,
      if (justificativaContingencia != null) 'justificativaContingencia': justificativaContingencia,
      if (numeroReciboEpec != null) 'numeroReciboEpec': numeroReciboEpec,
      if (protocoloEpec != null) 'protocoloEpec': protocoloEpec,
      if (dataEpec != null) 'dataEpec': dataEpec?.toIso8601String(),
      if (modelo != null) 'modelo': modelo,
    };
  }

  String get numeroFormatado => numero != null ? numero.toString().padLeft(9, '0') : '';
  String get serieFormatada => serie != null ? serie.toString().padLeft(3, '0') : '';

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'sim';
  }
}
