/// Resposta do backend após transmissão de NFe para SEFAZ
class NfeTransmissaoResponse {
  final String protocolo;
  final String status;
  final DateTime dataRecebimento;
  final int? codigoStatus;
  final String? mensagem;

  NfeTransmissaoResponse({
    required this.protocolo,
    required this.status,
    required this.dataRecebimento,
    this.codigoStatus,
    this.mensagem,
  });

  factory NfeTransmissaoResponse.fromJson(Map<String, dynamic> json) {
    return NfeTransmissaoResponse(
      protocolo: json['protocolo'] as String? ?? '',
      status: json['status'] as String? ?? '',
      dataRecebimento: DateTime.tryParse(json['dataRecebimento'] as String? ?? '') ?? DateTime.now(),
      codigoStatus: json['codigoStatus'] as int?,
      mensagem: json['mensagem'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protocolo': protocolo,
      'status': status,
      'dataRecebimento': dataRecebimento.toIso8601String(),
      'codigoStatus': codigoStatus,
      'mensagem': mensagem,
    };
  }

  @override
  String toString() => 'NfeTransmissaoResponse(protocolo: $protocolo, status: $status, '
      'dataRecebimento: $dataRecebimento, codigoStatus: $codigoStatus, mensagem: $mensagem)';
}
