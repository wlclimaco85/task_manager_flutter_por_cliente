import 'package:flutter/material.dart';
import 'package:task_manager_flutter/repositories/nfe_draft_repository.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/utils/network_failure_detector.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_drafts_banner.dart';

/// Handler compartilhado para a ação "Emitir" de NFe (mobile + windows,
/// card W3R3): quando a falha é de conectividade real, salva rascunho local
/// em vez de só mostrar erro genérico. Extraído para não duplicar a mesma
/// lógica entre `lib/mobile/screens/nfe_grid_screen.dart` e
/// `lib/windows/screens/nfe_grid_screen.dart`.
class NfeOfflineDraftHandler {
  NfeOfflineDraftHandler._();

  /// Retorna `true` se a falha foi tratada como rascunho offline (o chamador
  /// deve parar ali, sem mostrar o erro genérico). Retorna `false` se não
  /// era falha de conectividade — o chamador deve seguir com seu próprio
  /// tratamento de erro.
  static Future<bool> tratarFalhaEmitir({
    required BuildContext context,
    required Object erro,
    required String nfeId,
    required Map<String, dynamic> item,
    required NfeDraftRepository draftRepository,
    required GlobalKey<NfeDraftsBannerState> bannerKey,
  }) async {
    if (!NetworkFailureDetector.isConnectivityError(erro)) return false;

    await draftRepository.salvarRascunho(
      nfeIdReferencia: nfeId,
      // 'emitir' sempre manda corpo vazio — o reenvio automático precisa
      // ser fiel a isso, não ao mapa da linha da grid (que é só exibição).
      dadosFormulario: const {},
      contextoExibicao: item,
      acao: 'emitir',
    );
    bannerKey.currentState?.recarregar();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Sem conexão. NF-e salva como rascunho — será enviada quando a conexão voltar.'),
        backgroundColor: GridColors.warning,
      ));
    }
    return true;
  }
}
