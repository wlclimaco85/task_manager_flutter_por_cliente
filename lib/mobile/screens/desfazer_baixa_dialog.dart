import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/network_response.dart';
import '../../../services/baixa_caller.dart';
import '../../utils/grid_texts.dart';

class DesfazerBaixaDialog extends StatefulWidget {
  final int contaId;
  final String tipo; // "pagar" ou "receber"
  final DateTime dataBaixa;
  final double valorBaixa;
  final String contaLabel;
  final String formaPagamentoLabel;

  const DesfazerBaixaDialog({
    super.key,
    required this.contaId,
    required this.tipo,
    required this.dataBaixa,
    required this.valorBaixa,
    required this.contaLabel,
    required this.formaPagamentoLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required int contaId,
    required String tipo,
    required DateTime dataBaixa,
    required double valorBaixa,
    required String contaLabel,
    required String formaPagamentoLabel,
  }) {
    return showGeneralDialog(
      context: context,
      barrierLabel: "Desfazer Baixa",
      barrierDismissible: true,
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
          color: Colors.transparent,
          child: DesfazerBaixaDialog(
            contaId: contaId,
            tipo: tipo,
            dataBaixa: dataBaixa,
            valorBaixa: valorBaixa,
            contaLabel: contaLabel,
            formaPagamentoLabel: formaPagamentoLabel,
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) {
        final offsetAnim = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: FadeTransition(
            opacity: anim,
            child: SlideTransition(position: offsetAnim, child: child),
          ),
        );
      },
    );
  }

  @override
  State<DesfazerBaixaDialog> createState() => _DesfazerBaixaDialogState();
}

class _DesfazerBaixaDialogState extends State<DesfazerBaixaDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      title: Row(
        children: [
          Icon(Icons.undo, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Desfazer Baixa',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoTile('Data da Baixa', _fmtDate(widget.dataBaixa)),
                _infoTile('Valor', _fmtCurrency(widget.valorBaixa)),
                _infoTile('Conta', widget.contaLabel),
                _infoTile('Forma Pagamento', widget.formaPagamentoLabel),
                const Divider(height: 24),
                const Text(
                  'Tem certeza que deseja desfazer esta baixa?\nEsta ação não pode ser desfeita.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.undo),
          label: const Text('Desfazer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: _isLoading ? null : _confirmDesfazer,
        ),
      ],
    );
  }

  Future<void> _confirmDesfazer() async {
    setState(() => _isLoading = true);

    final NetworkResponse res = await BaixaCaller.desfazerBaixa(
      tipo: widget.tipo,
      id: widget.contaId,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res.isSuccess
          ? 'Baixa desfeita com sucesso!'
          : 'Erro ao desfazer baixa: ${res.statusCode}'),
      backgroundColor:
          res.isSuccess ? Colors.green.shade700 : Colors.red.shade700,
    ));

    if (res.isSuccess && mounted) Navigator.pop(context, true);
  }

  Widget _infoTile(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtCurrency(double v) => 'R\$ ${v.toStringAsFixed(2)}';
}
