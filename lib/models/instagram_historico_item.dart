class InstagramHistoricoItem {
  final int id;
  final String tipoAcao;
  final String? atorUsername;
  final String? atorFullName;
  final String? alvoUsername;
  final String? postRef;
  final String? texto;
  final String? valorAntes;
  final String? valorDepois;
  final String? ocorridoEm;
  final String origem;
  final int? changeLogId;

  const InstagramHistoricoItem({
    required this.id,
    required this.tipoAcao,
    this.atorUsername,
    this.atorFullName,
    this.alvoUsername,
    this.postRef,
    this.texto,
    this.valorAntes,
    this.valorDepois,
    this.ocorridoEm,
    required this.origem,
    this.changeLogId,
  });

  factory InstagramHistoricoItem.fromJson(Map<String, dynamic> j) =>
      InstagramHistoricoItem(
        id: j['id'] as int,
        tipoAcao: j['tipoAcao'] as String? ?? '',
        atorUsername: j['atorUsername'] as String?,
        atorFullName: j['atorFullName'] as String?,
        alvoUsername: j['alvoUsername'] as String?,
        postRef: j['postRef'] as String?,
        texto: j['texto'] as String?,
        valorAntes: j['valorAntes'] as String?,
        valorDepois: j['valorDepois'] as String?,
        ocorridoEm: j['ocorridoEm'] as String?,
        origem: j['origem'] as String? ?? 'event',
        changeLogId: j['changeLogId'] as int?,
      );
}
