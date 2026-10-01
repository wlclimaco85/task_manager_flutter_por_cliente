import 'package:flutter/widgets.dart';

import '../../../models/nfce/nfce_resultado_model.dart';
import '../../../widgets/nfce/nfce_danfe_panel.dart' as shared;

/// Compatibilidade temporária para imports antigos.
@Deprecated('Use ../../../widgets/nfce/nfce_danfe_panel.dart')
class LegacyNfceDanfeWidget extends StatelessWidget {
  final NfceResultadoModel resultado;

  const LegacyNfceDanfeWidget({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    return shared.NfceDanfeWidget(resultado: resultado);
  }
}
