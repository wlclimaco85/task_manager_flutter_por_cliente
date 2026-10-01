import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/pedido_venda_model.dart';
import '../../../services/pedido_venda_service.dart';
import '../../../utils/grid_colors.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../windows/dialogs/pedido_venda_historico_dialog.dart';
import '../../../windows/dialogs/faturar_dialog.dart';
import '../../utils/grid_texts.dart';

class WindowsPedidoVendaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsPedidoVendaGridScreen({super.key, required this.hasPermission});
  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<PedidoVenda>(
      telaNome: 'pedido_venda',
      hasPermission: hasPermission,
      fromJson: (json) => PedidoVenda.fromJson(json),
      toJson: (a) => a.toJson(),
      customActions: () => [
        CustomAction<PedidoVenda>(
          icon: Icons.check_circle,
          label: GridTexts.approve,
          isVisible: (item) => item.id != null && item.status == 'RASCUNHO',
          onPressed: (context, item) => _showConfirm(
            context,
            GridTexts.approveOrderTitle,
            GridTexts.approveOrderQuestion,
            () => PedidoVendaService.aprovar(item.id!),
          ),
        ),
        CustomAction<PedidoVenda>(
          icon: Icons.cancel,
          label: GridTexts.reject,
          isVisible: (item) => item.id != null && item.status == 'RASCUNHO',
          onPressed: (context, item) => _showConfirm(
            context,
            GridTexts.rejectOrderTitle,
            GridTexts.rejectOrderQuestion,
            () => PedidoVendaService.rejeitar(item.id!),
          ),
        ),
        CustomAction<PedidoVenda>(
          icon: Icons.payment,
          label: GridTexts.partialBilling,
          isVisible: (item) => item.id != null && item.status == 'APROVADO',
          onPressed: (context, item) => _showFaturarDialog(context, item),
        ),
        CustomAction<PedidoVenda>(
          icon: Icons.done_all,
          label: GridTexts.totalBilling,
          isVisible: (item) => item.id != null && (item.status == 'APROVADO' || item.status == 'FATURADO_PARCIAL'),
          onPressed: (context, item) => _showConfirm(
            context,
            GridTexts.totalBilling,
            GridTexts.totalBillingQuestion,
            () => PedidoVendaService.faturarTotal(item.id!),
          ),
        ),
        CustomAction<PedidoVenda>(
          icon: Icons.block,
          label: GridTexts.cancel,
          isVisible: (item) => item.id != null,
          onPressed: (context, item) => _showConfirm(
            context,
            GridTexts.cancelOrderTitle,
            GridTexts.cancelOrderQuestion,
            () => PedidoVendaService.cancelar(item.id!),
          ),
        ),
        CustomAction<PedidoVenda>(
          icon: Icons.history,
          label: GridTexts.viewHistory,
          isVisible: (item) => item.historico != null && item.historico!.isNotEmpty,
          onPressed: (context, item) => showDialog(
            context: context,
            builder: (_) => PedidoVendaHistoricoDialog(historico: item.historico ?? []),
          ),
        ),
      ],
    );
  }
  Future<void> _showConfirm(
    BuildContext context,
    String title,
    String message,
    Future<bool> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(GridTexts.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final success = await action();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? GridTexts.completedAction(title)
            : GridTexts.actionFailure(title)),
        backgroundColor: success ? GridColors.success : GridColors.error,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(GridTexts.actionFailure('$title: $e')),
        backgroundColor: GridColors.error,
      ));
    }
  }
  void _showFaturarDialog(BuildContext context, PedidoVenda pedido) {
    if (pedido.id == null) return;
    final itens = pedido.itens?.map((i) => i.toJson()).toList() ?? [];
    try {
      showDialog(
        context: context,
        builder: (_) => FaturarDialog(
          pedidoId: pedido.id!,
          itens: itens,
          onSaved: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(GridTexts.completedAction('Faturamento')),
                backgroundColor: GridColors.success,
              ),
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao faturar parcialmente: $e'),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }
}
