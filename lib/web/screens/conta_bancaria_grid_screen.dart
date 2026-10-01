import 'package:flutter/material.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_bancaria_model.dart';
import '../../../services/conta_bancaria_caller.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../widgets/finance/extrato_operacional_dialog.dart';
import '../../../widgets/finance/ajuste_saldo_conta_dialog.dart';

class WebContaBancariaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebContaBancariaGridScreen({super.key, required this.hasPermission});

  static String _contaLabel(ContaBancaria conta) {
    final partes = [conta.banco, conta.agencia, conta.numero, conta.descricao]
        .where((item) => item != null && item.trim().isNotEmpty)
        .map((item) => item!.trim())
        .toList();
    return partes.isEmpty ? 'Conta bancária' : partes.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<ContaBancaria>(
      telaNome: 'conta_bancaria',
      hasPermission: hasPermission,
      fromJson: (json) => ContaBancaria.fromJson(json),
      toJson: (a) => a.toJson(),
      fieldOverrides: [
        DropdownHelpers.empresaField(required: true),
        DropdownHelpers.parceiroFieldScopedOrSelectable(),
      ],
      customActions: () => [
        CustomAction<ContaBancaria>(
          icon: Icons.table_view,
          label: 'Extrato Operacional',
          isVisible: (item) => item.id != null,
          onPressed: (context, item) => ExtratoOperacionalDialog.show(
            context,
            contaId: item.id!,
            contaNome: _contaLabel(item),
          ),
        ),
        CustomAction<ContaBancaria>(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Ajustar Saldo',
          isVisible: (item) => item.id != null,
          onPressed: (context, item) async {
            final alterou = await showDialog<bool>(
              context: context,
              builder: (ctx) => AjusteSaldoContaDialog(
                conta: item,
                onSalvar: ({saldoInicial, saldoFinal}) =>
                    ContaBancariaCaller().ajustarSaldo(
                  contaId: item.id!,
                  saldoInicial: saldoInicial,
                  saldoFinal: saldoFinal,
                ),
              ),
            );
            if (alterou == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saldo ajustado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
