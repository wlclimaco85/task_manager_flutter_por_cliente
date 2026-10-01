import 'package:flutter/material.dart';

import '../../utils/grid_colors.dart';
import '../ticket_form_dialog.dart';

/// Card #444: popup de finalizar atendimento com pesquisa de satisfacao
/// (resolvido 100%/50%/nao resolvido), opcao de abrir chamado e nota 1-10.
/// Design: ui-ux-pro-max (specs desta sessao).
enum SatisfacaoAtendimento { resolvido, parcial, naoResolvido }

extension SatisfacaoAtendimentoLabel on SatisfacaoAtendimento {
  String get valor {
    switch (this) {
      case SatisfacaoAtendimento.resolvido:
        return 'RESOLVIDO';
      case SatisfacaoAtendimento.parcial:
        return 'PARCIAL';
      case SatisfacaoAtendimento.naoResolvido:
        return 'NAO_RESOLVIDO';
    }
  }
}

class FinalizarAtendimentoResult {
  final SatisfacaoAtendimento satisfacao;
  final int nota;
  const FinalizarAtendimentoResult(this.satisfacao, this.nota);
}

/// Retorna o resultado (satisfacao + nota) se o usuario confirmar, ou null
/// se cancelar. Nao chama a API -- quem chamou decide o que fazer com o
/// resultado (permite abrir o dialog de chamado antes de finalizar).
Future<FinalizarAtendimentoResult?> showFinalizarAtendimentoDialog(
  BuildContext context, {
  required String sectorDescricao,
  required String historicoConversa,
}) {
  return showDialog<FinalizarAtendimentoResult>(
    context: context,
    builder: (_) => _FinalizarAtendimentoDialog(
      sectorDescricao: sectorDescricao,
      historicoConversa: historicoConversa,
    ),
  );
}

class _FinalizarAtendimentoDialog extends StatefulWidget {
  final String sectorDescricao;
  final String historicoConversa;

  const _FinalizarAtendimentoDialog({
    required this.sectorDescricao,
    required this.historicoConversa,
  });

  @override
  State<_FinalizarAtendimentoDialog> createState() =>
      _FinalizarAtendimentoDialogState();
}

class _FinalizarAtendimentoDialogState
    extends State<_FinalizarAtendimentoDialog> {
  SatisfacaoAtendimento? _satisfacao;
  int? _nota;

  bool get _mostrarAbrirChamado =>
      _satisfacao == SatisfacaoAtendimento.parcial ||
      _satisfacao == SatisfacaoAtendimento.naoResolvido;

  bool get _podeConfirmar => _satisfacao != null && _nota != null;

  Color _corSatisfacao(SatisfacaoAtendimento s) {
    switch (s) {
      case SatisfacaoAtendimento.resolvido:
        return GridColors.secondary;
      case SatisfacaoAtendimento.parcial:
        return GridColors.warning;
      case SatisfacaoAtendimento.naoResolvido:
        return GridColors.primary;
    }
  }

  Color _corSatisfacaoSoft(SatisfacaoAtendimento s) {
    switch (s) {
      case SatisfacaoAtendimento.resolvido:
        return GridColors.secondarySoft;
      case SatisfacaoAtendimento.parcial:
        return GridColors.warning.withValues(alpha: 0.08);
      case SatisfacaoAtendimento.naoResolvido:
        return GridColors.primarySoft;
    }
  }

  IconData _iconeSatisfacao(SatisfacaoAtendimento s, bool selecionado) {
    switch (s) {
      case SatisfacaoAtendimento.resolvido:
        return selecionado
            ? Icons.check_circle
            : Icons.sentiment_satisfied_alt_outlined;
      case SatisfacaoAtendimento.parcial:
        return selecionado ? Icons.info : Icons.sentiment_neutral_outlined;
      case SatisfacaoAtendimento.naoResolvido:
        return selecionado
            ? Icons.cancel
            : Icons.sentiment_dissatisfied_outlined;
    }
  }

  String _labelSatisfacao(SatisfacaoAtendimento s) {
    switch (s) {
      case SatisfacaoAtendimento.resolvido:
        return 'Sim, 100% resolvido';
      case SatisfacaoAtendimento.parcial:
        return 'Parcialmente (50%)';
      case SatisfacaoAtendimento.naoResolvido:
        return 'Não foi resolvido';
    }
  }

  Color _corNota(int nota) {
    if (nota <= 4) return GridColors.primary;
    if (nota <= 7) return GridColors.warning;
    return GridColors.secondary;
  }

  Future<void> _abrirChamado() async {
    await showDialog<void>(
      context: context,
      builder: (_) => TicketFormDialog(
        sectorDescricao: widget.sectorDescricao,
        initialDescricao: widget.historicoConversa,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        color: GridColors.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt, color: GridColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Finalizar Atendimento',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: GridColors.textSecondary),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('O problema foi resolvido?',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: GridColors.textSecondary)),
            const SizedBox(height: 12),
            ...SatisfacaoAtendimento.values.map((s) {
              final selecionado = _satisfacao == s;
              final cor = _corSatisfacao(s);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _satisfacao = s),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selecionado ? _corSatisfacaoSoft(s) : GridColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selecionado ? cor : GridColors.divider,
                        width: selecionado ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_iconeSatisfacao(s, selecionado),
                            color: selecionado ? cor : GridColors.textMuted,
                            size: 24),
                        const SizedBox(width: 12),
                        Text(
                          _labelSatisfacao(s),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selecionado ? cor : GridColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: !_mostrarAbrirChamado
                  ? const SizedBox.shrink()
                  : Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: GridColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: GridColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.support_agent,
                              color: GridColors.primary, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Quer que a gente continue com um chamado formal?',
                              style: TextStyle(
                                  color: GridColors.textSecondary,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GridColors.primary,
                              side:
                                  const BorderSide(color: GridColors.primary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _abrirChamado,
                            child: const Text('Abrir chamado'),
                          ),
                        ],
                      ),
                    ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Avalie o atendimento',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: GridColors.textSecondary)),
            const Text('1 = muito ruim · 10 = excelente',
                style: TextStyle(fontSize: 11, color: GridColors.textMuted)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(10, (i) {
                final valorNota = i + 1;
                final selecionado = _nota == valorNota;
                final cor = _corNota(valorNota);
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _nota = valorNota),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Fix (pedido do usuario): os numeros ja nascem
                      // coloridos por faixa (vermelho/amarelo/verde),
                      // nao so quando selecionados -- reforca a escala
                      // visual de nota ruim -> excelente.
                      color: selecionado ? cor : cor.withValues(alpha: 0.10),
                      border: Border.all(color: cor, width: selecionado ? 0 : 1.5),
                    ),
                    child: Text(
                      '$valorNota',
                      style: TextStyle(
                        color: selecionado ? Colors.white : cor,
                        fontWeight:
                            selecionado ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                      foregroundColor: GridColors.textMuted),
                  child: const Text('CANCELAR'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _podeConfirmar
                      ? () => Navigator.of(context).pop(
                          FinalizarAtendimentoResult(_satisfacao!, _nota!))
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    disabledBackgroundColor: GridColors.divider,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('CONFIRMAR',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
