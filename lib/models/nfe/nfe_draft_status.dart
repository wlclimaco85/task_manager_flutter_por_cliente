/// Estados possíveis de um rascunho offline de NFe (card W3R3).
enum NfeDraftStatus {
  rascunho('RASCUNHO', 'Rascunho'),
  enviando('ENVIANDO', 'Enviando...'),
  enviado('ENVIADO', 'Enviado'),
  conflito('CONFLITO', 'Conflito'),
  erro('ERRO', 'Erro ao enviar');

  final String code;
  final String label;

  const NfeDraftStatus(this.code, this.label);

  factory NfeDraftStatus.fromCode(String? code) {
    if (code == null || code.isEmpty) return NfeDraftStatus.rascunho;
    return values.firstWhere(
      (v) => v.code == code.toUpperCase(),
      orElse: () => NfeDraftStatus.rascunho,
    );
  }
}
