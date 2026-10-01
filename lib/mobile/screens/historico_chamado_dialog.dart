import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/constants/custom_colors.dart';
import 'package:task_manager_flutter/services/chamado_caller.dart';

class HistoricoChamadoDialog {
  static Future<void> show(BuildContext context, int chamadoId) async {
    final colors = CustomColors();
    bool isLoading = true;
    List<Map<String, dynamic>> historico = [];
    String? erro;

    try {
      historico = await ChamadoCaller().getHistoricoChamado(chamadoId);
    } catch (e) {
      erro = 'Erro ao buscar histórico: $e';
    }

    isLoading = false;

    if (!context.mounted) return;

    showGeneralDialog(
      context: context,
      barrierLabel: "Histórico do Chamado",
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, __, child) {
        final offset =
            Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        );

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: offset,
              child: AlertDialog(
                backgroundColor: GridColors.dialogBackground.withValues(alpha: 0.97),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                titlePadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  children: [
                    const Icon(Icons.timeline_rounded,
                        color: Colors.green, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      "Histórico do Chamado #$chamadoId",
                      style: const TextStyle(
                        color: GridColors.secondaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : erro != null
                          ? Center(
                              child: Text(
                                erro,
                                style: const TextStyle(color: GridColors.error),
                              ),
                            )
                          : historico.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Nenhum evento registrado',
                                    style: TextStyle(
                                      color: GridColors.secondaryDark,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: historico.length,
                                  itemBuilder: (ctx, i) {
                                    final item = historico[i];
                                    final usuarioOrigem =
                                        item['usuarioOrigem'] ?? '---';
                                    final usuarioDestino =
                                        item['usuarioDestino'];
                                    final acao =
                                        (item['acao'] ?? 'Ação desconhecida')
                                            .toString()
                                            .toUpperCase();
                                    final observacao = item['observacao'] ?? '';
                                    final dataStr = item['dataEvento'];
                                    String dataFormatada = '';

                                    if (dataStr != null &&
                                        dataStr.toString().isNotEmpty) {
                                      try {
                                        final dt = DateTime.parse(dataStr);
                                        dataFormatada =
                                            DateFormat('dd/MM/yyyy HH:mm')
                                                .format(dt);
                                      } catch (_) {
                                        dataFormatada = dataStr.toString();
                                      }
                                    }

                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: 1),
                                      duration: Duration(
                                          milliseconds: 250 + (i * 80)),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, (1 - value) * 25),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _timelineItem(
                                        context,
                                        colors,
                                        dataFormatada,
                                        usuarioOrigem,
                                        usuarioDestino,
                                        observacao,
                                        acao,
                                        i == historico.length - 1,
                                      ),
                                    );
                                  },
                                ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  SizedBox(
                    width: 160,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      label: const Text(
                        'Fechar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _timelineItem(
    BuildContext context,
    CustomColors colors,
    String data,
    String usuarioOrigem,
    String? usuarioDestino,
    String observacao,
    String acao,
    bool isLast,
  ) {
    IconData icone;
    Color corIcone;

    switch (acao.toUpperCase()) {
      case 'TRANSFERÊNCIA':
        icone = Icons.swap_horiz_rounded;
        corIcone = Colors.blueAccent;
        break;
      case 'ATRIBUIÇÃO':
        icone = Icons.assignment_ind_rounded;
        corIcone = Colors.deepPurple;
        break;
      case 'FECHAMENTO':
        icone = Icons.check_circle_rounded;
        corIcone = Colors.green;
        break;
      case 'ABERTURA':
        icone = Icons.play_circle_fill_rounded;
        corIcone = Colors.orange;
        break;
      default:
        icone = Icons.history_edu;
        corIcone = Colors.teal;
    }

    return Stack(
      children: [
        Positioned(
          left: 24,
          top: 0,
          bottom: isLast ? 12 : 0,
          child: Container(
            width: 2,
            color: Colors.green.withValues(alpha: 0.6),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 56, right: 8, bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.green.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icone, color: corIcone, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      acao,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: corIcone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      data,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuarioDestino != null
                          ? "De $usuarioOrigem"
                          : "Por $usuarioOrigem",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: GridColors.secondaryDark,
                      ),
                    ),
                    if (usuarioDestino != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          "Para $usuarioDestino",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: GridColors.secondaryDark,
                          ),
                        ),
                      ),
                  ],
                ),
                if (observacao.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    observacao,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          top: 12,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: corIcone,
            child: Icon(icone, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }
}
