import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../models/chamado_model.dart';
import '../../../services/chat_caller.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../widgets/chamado_detalhe_screen.dart';
import '../../../web/screens/chatMessageListScreen.dart';
import '../../../web/screens/fechar_chamado_dialog.dart';

class WebChamadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebChamadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final loginId = AuthUtility.userInfo?.login?.id?.toString() ?? AuthUtility.userInfo?.data?.id?.toString() ?? '';

    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'chamado',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      // Card #451: abre a tela de detalhe/timeline do chamado.
      detailScreenBuilder: (item) => ChamadoDetalheScreen(
        chamado: Chamado.fromJson(item),
        // Fix (card #473): navega para a tela real de Chat/Atendimento já
        // com a conversa deste chamado selecionada.
        onAbrirChat: (context, chamado) {
          final chatId = buildChamadoChatId(
              chamado.empresa.id ?? 0, chamado.parceiro!.id ?? 0, chamado.id ?? 0);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WebChatListScreen(
                userName: AuthUtility.userInfo?.login?.email ??
                    AuthUtility.userInfo?.data?.email ??
                    '',
                initialChatId: chatId,
                initialSector: chamado.setor?.nome,
              ),
            ),
          );
        },
      ),
      extraParams: loginId.isNotEmpty ? {'loginId': loginId} : null,
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.check_circle, label: 'Fechar',
          onPressed: (context, chamado) => showDialog(context: context, builder: (ctx) => WebFecharChamadoDialog(chamadoId: chamado['id'] ?? 0)),
          isVisible: (_) => true,
        ),
      ],
    );
  }
}
