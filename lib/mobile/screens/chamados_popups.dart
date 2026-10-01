import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/constants/custom_colors.dart';
import 'package:task_manager_flutter/models/chamado_model.dart';
import '../../utils/grid_texts.dart';

class PegarChamadoDialog {
  static Future<void> show(BuildContext context, Chamado chamado) {
    return _baseDialog(
      context,
      title: "Pegar Chamado",
      content: "Deseja assumir o chamado '${chamado.titulo}'?",
      confirmText: "Confirmar",
      color: GridColors.success,
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chamado assumido com sucesso!")),
        );
      },
    );
  }
}

class TransferirChamadoDialog {
  static Future<void> show(BuildContext context, Chamado chamado) {
    final TextEditingController destino = TextEditingController();
    return _baseDialog(
      context,
      title: "Transferir Chamado",
      contentWidget: TextFormField(
        controller: destino,
        decoration: const InputDecoration(
          labelText: "ID ou Nome do Usuário Destino",
          prefixIcon: Icon(Icons.person),
        ),
      ),
      confirmText: "Transferir",
      color: GridColors.info,
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Chamado transferido para ${destino.text.trim()}!")),
        );
      },
    );
  }
}

class AtribuirChamadoDialog {
  static Future<void> show(BuildContext context, Chamado chamado) {
    final TextEditingController usuario = TextEditingController();
    return _baseDialog(
      context,
      title: "Atribuir Chamado",
      contentWidget: TextFormField(
        controller: usuario,
        decoration: const InputDecoration(
          labelText: "Usuário Responsável",
          prefixIcon: Icon(Icons.person_add_alt_1),
        ),
      ),
      confirmText: "Atribuir",
      color: GridColors.secondary,
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Chamado atribuído ao usuário ${usuario.text.trim()}!")),
        );
      },
    );
  }
}

class FecharChamadoDialog {
  static Future<void> show(BuildContext context, Chamado chamado) {
    final TextEditingController motivo = TextEditingController();
    return _baseDialog(
      context,
      title: "Fechar Chamado",
      contentWidget: TextFormField(
        controller: motivo,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: "Motivo do fechamento",
          prefixIcon: Icon(Icons.comment),
        ),
      ),
      confirmText: "Fechar",
      color: GridColors.error,
      onConfirm: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Chamado fechado: ${motivo.text}")),
        );
      },
    );
  }
}

class HistoricoChamadoPopup {
  static Future<void> show(BuildContext context, Chamado chamado) {
    return _baseDialog(
      context,
      title: "Histórico do Chamado",
      contentWidget: SizedBox(
        width: 400,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: 5,
          separatorBuilder: (_, __) => const Divider(height: 8),
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.timeline, color: GridColors.primary),
            title: Text("Evento #${i + 1}"),
            subtitle: Text("Detalhe do evento ${i + 1}"),
          ),
        ),
      ),
      confirmText: "Fechar",
      color: GridColors.warning,
      onConfirm: () => Navigator.pop(context),
    );
  }
}

Future<void> _baseDialog(
  BuildContext context, {
  required String title,
  String? content,
  Widget? contentWidget,
  required String confirmText,
  required Color color,
  required VoidCallback onConfirm,
}) {
  final colors = CustomColors();

  return showGeneralDialog(
    context: context,
    barrierLabel: title,
    barrierDismissible: true,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (_, anim, __, child) {
      final offset = Tween(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: offset,
            child: AlertDialog(
              backgroundColor: GridColors.dialogBackground.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              content: contentWidget ?? Text(content ?? ''),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: colors.getCancelButtonColor(),
                    foregroundColor: colors.getButtonTextColor(),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(GridTexts.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: colors.getButtonTextColor(),
                  ),
                  onPressed: onConfirm,
                  child: Text(confirmText),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
