import 'package:flutter/material.dart';
import '../../../../web/screens/nfce/nfce_danfe_widget.dart' as web;
import '../../../../models/nfce/nfce_resultado_model.dart';

class MobileNfceDanfeWidget extends StatelessWidget {
  final NfceResultadoModel? resultado;
  final Map<String, dynamic>? dadosDanfe;

  const MobileNfceDanfeWidget({super.key, this.resultado, this.dadosDanfe});

  @override
  Widget build(BuildContext context) {
    final res = resultado ??
        (dadosDanfe != null
            ? NfceResultadoModel.fromJson(dadosDanfe!)
            : const NfceResultadoModel(
                id: 0,
                chaveAcesso: '',
                protocolo: '',
                statusSefaz: 'AUTORIZADA',
              ));
    return web.LegacyNfceDanfeWidget(resultado: res);
  }
}
