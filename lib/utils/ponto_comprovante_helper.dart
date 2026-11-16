import 'package:flutter/material.dart';

import '../services/ponto_rep_p_service.dart';
import '../services/ponto_service.dart';
import 'app_logger.dart';
import 'file_saver_compat.dart';

/// Baixa o comprovante de registro (Portaria MTP 671/2021, Art. 79/80) da ultima batida.
Future<void> baixarComprovanteUltimaBatida(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final pontoId = PontoService.ultimoPontoId;
  final empresaId = PontoService.ultimaEmpresaId;
  if (pontoId == null || empresaId == null) {
    messenger.showSnackBar(const SnackBar(content: Text('Nenhuma batida recente para gerar comprovante.')));
    return;
  }
  try {
    final r = await PontoRepPService().baixarComprovante(empresaId, pontoId);
    if (!r.ok) {
      messenger.showSnackBar(SnackBar(content: Text(r.erro!)));
      return;
    }
    final a = r.dado!;
    final destino = await FileSaver.instance
        .saveFile(name: a.nome, bytes: a.bytes, fileExtension: 'pdf', mimeType: MimeType.pdf);
    messenger.showSnackBar(SnackBar(
        content: Text(a.assinado ? 'Comprovante assinado salvo: $destino' : 'Comprovante salvo: $destino')));
  } catch (e, st) {
    AppLogger.i.error('[Ponto] falha ao salvar comprovante: $e', st);
    messenger.showSnackBar(const SnackBar(content: Text('Nao foi possivel salvar o comprovante.')));
  }
}

/// SnackBar de sucesso com a acao "Comprovante".
SnackBar snackBatidaRegistrada(BuildContext context, String msg) => SnackBar(
      content: Text(msg),
      action: SnackBarAction(label: 'Comprovante', onPressed: () => baixarComprovanteUltimaBatida(context)),
    );
