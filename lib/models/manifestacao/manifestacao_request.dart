import 'manifestacao_status.dart';

/// Request DTO para submissão de Manifestação
class ManifestacaoRequest {
  final String nfeId;
  final String statusCodigo;
  final String observacao;
  final int? quantidadeRecebida;
  final String? motivoRecusa;

  ManifestacaoRequest({
    required this.nfeId,
    required this.statusCodigo,
    required this.observacao,
    this.quantidadeRecebida,
    this.motivoRecusa,
  });

  /// Converte para JSON para enviar via API
  Map<String, dynamic> toJson() {
    return {
      'nfeId': nfeId,
      'status': statusCodigo,
      'observacao': observacao,
      if (quantidadeRecebida != null) 'quantidadeRecebida': quantidadeRecebida,
      if (motivoRecusa != null) 'motivoRecusa': motivoRecusa,
    };
  }
}
