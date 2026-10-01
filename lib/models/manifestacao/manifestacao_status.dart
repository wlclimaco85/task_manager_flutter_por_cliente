/// Status de manifestação de recebimento de NFe
enum ManifestacaoStatus {
  aceitar('aceitar', 'Aceitar'),
  recusar('recusar', 'Recusar'),
  parcial('parcial', 'Recebimento Parcial');

  final String codigo;
  final String label;

  const ManifestacaoStatus(this.codigo, this.label);

  static ManifestacaoStatus? fromCodigo(String? codigo) {
    if (codigo == null) return null;
    try {
      return ManifestacaoStatus.values
          .firstWhere((e) => e.codigo == codigo.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}
