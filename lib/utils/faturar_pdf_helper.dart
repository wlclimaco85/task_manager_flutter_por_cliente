import 'app_logger.dart';

typedef ObterDanfse = Future<List<int>?> Function(int nfseId);
typedef SalvarPdf = Future<void> Function(String nome, List<int> bytes);

/// O PDF (DANFSe) ja nasce no faturamento: baixa o de cada nota autorizada para nao precisar ir a
/// tela de NFS-e so para imprimir. Falha de PDF nunca desfaz o faturamento (so loga e segue).
/// Retorna quantos PDFs foram salvos.
Future<int> baixarPdfsDasNotas(
  List resultados, {
  required ObterDanfse obter,
  required SalvarPdf salvar,
}) async {
  var baixados = 0;
  for (final item in resultados.whereType<Map>()) {
    final id = (item['nfseId'] as num?)?.toInt();
    if (item['sucesso'] != true || id == null) continue;
    try {
      final bytes = await obter(id);
      if (bytes == null) continue;
      await salvar('danfse_$id', bytes);
      baixados++;
    } catch (e, st) {
      AppLogger.i.error('Faturar: erro ao baixar o DANFSE #$id: $e', st);
    }
  }
  return baixados;
}
