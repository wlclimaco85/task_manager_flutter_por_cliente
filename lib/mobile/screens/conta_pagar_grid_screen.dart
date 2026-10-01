import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/security_matrix.dart';
import '../../customization/generic_grid_card.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../widgets/anexo_financeiro_widget.dart';
import '../screens/baixa_dialog.dart';
import '../screens/desfazer_baixa_dialog.dart';
import '../screens/parcelar_conta_dialog.dart';
import '../screens/recorrencia_conta_dialog.dart';
import '../screens/renegociacao_conta_dialog.dart';

class ContaPagarGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;

  const ContaPagarGridScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
  });

  @override
  State<ContaPagarGridScreen> createState() => _ContaPagarGridScreenState();
}

class _ContaPagarGridScreenState extends State<ContaPagarGridScreen> {
  bool _importing = false;

  bool get _isFinanceiroLimitado =>
      !ModuloAccess.isModuloContratado('Financeiro') &&
      ModuloAccess.isModuloContratado('Financeiro Limitado');

  Widget _buildBannerLimitado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: GridColors.pageBackground,
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: GridColors.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estas contas são lançadas pelo seu escritório contábil. '
              'Você pode consultá-las e registrar a baixa.',
              style: TextStyle(fontSize: 12, color: GridColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            if (_isFinanceiroLimitado) _buildBannerLimitado(),
            Expanded(
              child: GenericMobileGridScreen<ContaPagar>(
          title: "Contas a Pagar",
          fetchEndpoint: ApiLinks.allContasPagar,
          createEndpoint: ApiLinks.createContaPagar,
          updateEndpoint: ApiLinks.updateContaPagar(":id"),
          deleteEndpoint: ApiLinks.deleteContaPagar(":id"),
          fromJson: (json) => ContaPagar.fromJson(json),
          toJson: (obj) => obj.toJson(),
          hasPermission: widget.hasPermission,
          fieldConfigs: ContaPagar.fieldConfigs,
          idFieldName: 'id',
          dateFieldName: 'audit.createdAt',
          customActions: () => [
            CustomAction<ContaPagar>(
              icon: Icons.price_check,
              label: 'Baixar',
              onPressed: (context, object) => _showBaixaDialog(context, object),
              isVisible: (object) =>
                  object.status == StatusConta.ABERTA &&
                  widget.hasPermission('baixar'),
            ),
            CustomAction<ContaPagar>(
              icon: Icons.undo,
              label: 'Desfazer Baixa',
              isVisible: (obj) => obj.status == StatusConta.BAIXADA,
              onPressed: (context, object) {
                DesfazerBaixaDialog.show(
                  context,
                  tipo: 'pagar',
                  contaId: object.id!,
                  dataBaixa: object.dataBaixa ?? DateTime.now(),
                  valorBaixa: object.valorBaixa ?? object.valor,
                  contaLabel:
                      object.contaBaixa?.descricao ?? 'Conta nao informada',
                  formaPagamentoLabel:
                      object.formaPagamento?.nome ?? 'Forma nao informada',
                );
              },
            ),
            CustomAction<ContaPagar>(
              icon: Icons.attach_file,
              label: 'Anexos',
              isVisible: (obj) => obj.id != null,
              onPressed: (context, object) => _showAnexos(context, object),
            ),
            // Pedido do usuario: mobile tem que ter as mesmas opcoes do web
            // (ver web/screens/conta_pagar_grid_screen.dart) -- Parcelar,
            // Recorrencia, Renegociar e Clonar so existiam no web/windows.
            CustomAction<ContaPagar>(
              icon: Icons.credit_card,
              label: 'Parcelar',
              onPressed: (context, object) => showDialog(
                context: context,
                builder: (_) => ParcelarContaDialog(conta: object),
              ),
              isVisible: (obj) => obj.status == StatusConta.ABERTA,
            ),
            CustomAction<ContaPagar>(
              icon: Icons.repeat,
              label: 'Recorrência',
              onPressed: (context, object) => showDialog(
                context: context,
                builder: (_) => RecorrenciaContaDialog(conta: object),
              ),
              isVisible: (obj) => obj.status == StatusConta.ABERTA,
            ),
            CustomAction<ContaPagar>(
              icon: Icons.swap_horiz,
              label: 'Renegociar',
              onPressed: (context, object) => showDialog(
                context: context,
                builder: (_) => RenegociacaoContaDialog(conta: object),
              ),
              isVisible: (obj) => obj.status == StatusConta.ABERTA,
            ),
            CustomAction<ContaPagar>(
              icon: Icons.copy,
              label: 'Clonar',
              onPressed: (context, object) => _clonarLancamento(context, object.id),
              isVisible: (_) => true,
            ),
          ],
          useUserBannerAppBar: true,
          onUserBannerTapped: widget.onUserBannerTapped,
          paginationConfig: const PaginationConfig(
            defaultRowsPerPage: 10,
            availableRowsPerPage: [10, 25, 50],
          ),
          enableSearch: true,
        ),
        ),
        ],
        ),
        // FAB de importacao (cria contas) — só com permissão de inserir; some no
        // modo Financeiro limitado.
        if (widget.hasPermission('create'))
          Positioned(
          bottom: 88,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'fab_import_conta_pagar',
            tooltip: 'Importar extrato (CSV/REM/RET)',
            backgroundColor: GridColors.primary,
            onPressed: _importing ? null : _importarBoleto,
            child: _importing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Future<void> _importarBoleto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'rem', 'ret', 'txt'],
      withData: true,
    );
    if (result == null || !mounted) return;

    final file = result.files.first;
    var bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      _snack('Nao foi possivel ler o arquivo', error: true);
      return;
    }

    setState(() => _importing = true);
    try {
      final importUrl = TenantContext.empresaId == null
          ? ApiLinks.importacaoContaPagar
          : '${ApiLinks.importacaoContaPagar}?empId=${TenantContext.empresaId}';
      final request = http.MultipartRequest('POST', Uri.parse(importUrl));
      request.headers.addAll(TenantContext.headers);
      request.files.add(
        http.MultipartFile.fromBytes('arquivo', bytes, filename: file.name),
      );
      if (TenantContext.empresaId != null) {
        request.fields['empId'] = TenantContext.empresaId.toString();
        request.fields['empresaId'] = TenantContext.empresaId.toString();
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        final importados = data['importados'] ?? data['count'] ?? '?';
        _snack('Importacao concluida: $importados registros');
      } else {
        _snack('Erro ao importar: status ${response.statusCode}', error: true);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  void _showAnexos(BuildContext context, ContaPagar conta) {
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
            lancamentoTipo: 'PAGAR',
            empresaId: conta.empresa.id,
          ),
        ),
      ),
    );
  }

  void _showBaixaDialog(BuildContext context, ContaPagar conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BaixaDialog(conta: conta);
      },
    );
  }

  /// Clona um lançamento — mesma ação já existente no Web (ver
  /// web/screens/conta_pagar_grid_screen.dart).
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
        Uri.parse(ApiLinks.clonarContaPagar('$id')),
        headers: TenantContext.headers,
      );
      if (!context.mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        _snack('Lançamento #$id clonado com sucesso!');
      } else {
        _snack('Erro ao clonar: ${response.statusCode}', error: true);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    }
  }
}
