import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../customization/generic_grid_card.dart';
import '../../../models/conta_receber_model.dart';
import '../../../widgets/anexo_financeiro_widget.dart';
import '../../widgets/finance/billing_charge_dialog.dart';
import '../screens/baixa_dialog_receber.dart';
import '../screens/desfazer_baixa_dialog.dart';
import '../screens/parcelar_receber_dialog.dart';
import '../screens/recorrencia_receber_dialog.dart';
import '../screens/renegociacao_receber_dialog.dart';

class ContaReceberGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;
  // Fix card #453: filtro fixo de categoria financeira (tela Mensalidades).
  final int? categoriaFinanceiraIdFixa;
  final String? tituloOverride;

  const ContaReceberGridScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
    this.categoriaFinanceiraIdFixa,
    this.tituloOverride,
  });

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<ContaReceber>(
      title: tituloOverride ?? "Contas a Receber",
      fetchEndpoint: ApiLinks.allContasReceber,
      extraParams: categoriaFinanceiraIdFixa == null
          ? null
          : {'categoriaFinanceiraId': categoriaFinanceiraIdFixa.toString()},
      createEndpoint: ApiLinks.createContaReceber,
      updateEndpoint: ApiLinks.updateContaReceber(":id"),
      deleteEndpoint: ApiLinks.deleteContaReceber(":id"),
      fromJson: (json) => ContaReceber.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: ContaReceber.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'audit.createdAt',
      customActions: () => [
        CustomAction<ContaReceber>(
          icon: Icons.receipt_long,
          label: 'Cobrar',
          onPressed: (context, object) => _showBillingDialog(context, object),
          isVisible: (object) => object.status == StatusConta.ABERTA,
        ),
        CustomAction<ContaReceber>(
          icon: Icons.price_check,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (object) =>
              object.status == StatusConta.ABERTA &&
              hasPermission('baixar'),
        ),
        CustomAction<ContaReceber>(
          icon: Icons.undo,
          label: 'Desfazer Baixa',
          isVisible: (obj) => obj.status == StatusConta.BAIXADA,
          onPressed: (context, object) {
            DesfazerBaixaDialog.show(
              context,
              tipo: 'receber',
              contaId: object.id!,
              dataBaixa: object.dataBaixa ?? DateTime.now(),
              valorBaixa: object.valorBaixa ?? object.valor,
              contaLabel: object.contaBaixa?.descricao ?? 'Conta não informada',
              formaPagamentoLabel:
                  object.formaPagamento?.nome ?? 'Forma não informada',
            );
          },
        ),
        CustomAction<ContaReceber>(
          icon: Icons.attach_file,
              label: 'Anexos',
          isVisible: (obj) => obj.id != null,
          onPressed: (context, object) => _showAnexos(context, object),
        ),
        // Pedido do usuario: mobile tem que ter as mesmas opcoes do web
        // (ver web/screens/conta_receber_grid_screen.dart) -- Parcelar,
        // Recorrencia, Renegociar e Clonar so existiam no web/windows.
        CustomAction<ContaReceber>(
          icon: Icons.credit_card,
          label: 'Parcelar',
          onPressed: (context, object) => showDialog(
            context: context,
            builder: (_) => ParcelarReceberDialog(conta: object),
          ),
          isVisible: (obj) => obj.status == StatusConta.ABERTA,
        ),
        CustomAction<ContaReceber>(
          icon: Icons.repeat,
          label: 'Recorrência',
          onPressed: (context, object) => showDialog(
            context: context,
            builder: (_) => RecorrenciaReceberDialog(conta: object),
          ),
          isVisible: (obj) => obj.status == StatusConta.ABERTA,
        ),
        CustomAction<ContaReceber>(
          icon: Icons.swap_horiz,
          label: 'Renegociar',
          onPressed: (context, object) => showDialog(
            context: context,
            builder: (_) => RenegociacaoReceberDialog(conta: object),
          ),
          isVisible: (obj) => obj.status == StatusConta.ABERTA,
        ),
        CustomAction<ContaReceber>(
          icon: Icons.copy,
          label: 'Clonar',
          onPressed: (context, object) => _clonarLancamento(context, object.id),
          isVisible: (_) => true,
        ),
      ],
      useUserBannerAppBar: true,
      onUserBannerTapped: onUserBannerTapped,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
    );
  }

  void _showAnexos(BuildContext context, ContaReceber conta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AnexoFinanceiroWidget(
            lancamentoId: conta.id!,
            lancamentoTipo: 'RECEBER',
            empresaId: conta.empresa.id,
          ),
        ),
      ),
    );
  }

  void _showBaixaDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BaixaDialogReceber(conta: conta);
      },
    );
  }

  void _showBillingDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BillingChargeDialog(conta: conta);
      },
    );
  }

  /// Clona um lançamento — mesma ação já existente no Web (ver
  /// web/screens/conta_receber_grid_screen.dart).
  Future<void> _clonarLancamento(BuildContext context, int? id) async {
    if (id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clonar Lançamento'),
        content: Text('Deseja clonar o lançamento #$id?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clonar'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      final response = await http.post(
        Uri.parse(ApiLinks.clonarContaReceber('$id')),
        headers: TenantContext.headers,
      );
      if (!context.mounted) return;
      final msg = (response.statusCode == 200 || response.statusCode == 201)
          ? 'Lançamento #$id clonado com sucesso!'
          : 'Erro ao clonar: ${response.statusCode}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }
}
