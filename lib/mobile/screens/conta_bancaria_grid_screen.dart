import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task_manager_flutter/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/models/conta_bancaria_model.dart';
import 'package:task_manager_flutter/services/conta_bancaria_caller.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/utils.dart';
import 'package:task_manager_flutter/widgets/searchable_dropdown.dart';
import 'package:task_manager_flutter/widgets/finance/extrato_operacional_dialog.dart';
import '../../utils/grid_texts.dart';

class ContaBancariaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;

  const ContaBancariaGridScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
  });

  static String _contaLabel(ContaBancaria conta) {
    final partes = [conta.banco, conta.agencia, conta.numero, conta.descricao]
        .where((item) => item != null && item.trim().isNotEmpty)
        .map((item) => item!.trim())
        .toList();
    return partes.isEmpty ? 'Conta bancária' : partes.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenericMobileGridScreen<ContaBancaria>(
        title: "Gerenciamento de Contas Bancárias",
        fetchEndpoint: ApiLinks.contasBancarias,
        createEndpoint: ApiLinks.createContaBancaria,
        updateEndpoint: ApiLinks.updateContaBancaria(":id"),
        deleteEndpoint: ApiLinks.deleteContaBancaria(":id"),
        dynamicAdditionalFormData: (item) => {
          if (pegarEmpresaLogada() != null) 'empresa.id': pegarEmpresaLogada(),
          if (pegarParceiroLogada() != null)
            'parceiro.id': pegarParceiroLogada(),
        },
        fieldConfigs: ContaBancaria.fieldConfigs,
        idFieldName: 'id',
        useUserBannerAppBar: true,
        onUserBannerTapped: onUserBannerTapped,
        enableSearch: true,
        paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 10,
          availableRowsPerPage: [10, 25, 50],
        ),
        hasPermission: hasPermission,
        fromJson: (json) =>
            ContaBancaria.fromJson(Map<String, dynamic>.from(json)),
        toJson: (obj) => obj.toJson(),
        storageKey: 'contas_bancarias_grid',
        customActions: () => [
          CustomAction<ContaBancaria>(
            icon: Icons.toggle_on,
            label: 'Ativar / Desativar',
            onPressed: (context, item) async {
              final caller = ContaBancariaCaller();
              _showLoadingDialog(context, "Atualizando status...");
              final sucesso = await caller.ativarConta(item.id!, !(item.ativo));
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                sucesso
                    ? _showSuccessDialog(context, "Status atualizado!")
                    : _showSnack(context, "Erro ao atualizar status.");
              }
            },
          ),
          CustomAction<ContaBancaria>(
            icon: Icons.swap_horiz,
            label: 'Transferir Saldo',
            onPressed: (context, item) =>
                _showTransferDialog(context, item, ContaBancariaCaller()),
          ),
          CustomAction<ContaBancaria>(
            icon: Icons.picture_as_pdf,
            label: 'Extrato PDF',
            onPressed: (context, item) =>
                _showExtratoDialog(context, item, ContaBancariaCaller()),
          ),
          CustomAction<ContaBancaria>(
            icon: Icons.assessment,
            label: 'Extrato Consolidado',
            onPressed: (context, item) =>
                _showExtratoConsolidado(context, item),
          ),
          CustomAction<ContaBancaria>(
            icon: Icons.table_view,
            label: 'Extrato Operacional',
            onPressed: (context, item) => ExtratoOperacionalDialog.show(
              context,
              contaId: item.id!,
              contaNome: _contaLabel(item),
            ),
            isVisible: (item) => item.id != null,
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(
      BuildContext context, ContaBancaria conta, ContaBancariaCaller caller) {
    final valorController = TextEditingController();
    final historicoController = TextEditingController();
    int? contaDestinoId;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.swap_horiz,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Transferir Saldo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Corpo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: FutureBuilder(
                  future: ContaBancariaCaller.loadContas(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final contas = snapshot.data ?? [];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SearchableDropdownField(
                          label: 'Conta destino',
                          value: contaDestinoId?.toString(),
                          items: contas
                              .where((c) => c['value'] != conta.id)
                              .map((c) => <String, dynamic>{
                                    'id': c['value']?.toString() ?? '',
                                    'nome': c['label']?.toString() ?? '',
                                  })
                              .toList(),
                          valueField: 'id',
                          displayField: 'nome',
                          isRequired: true,
                          hintText: 'Selecione a conta destino',
                          onChanged: (v) {
                            setStateDialog(
                                () => contaDestinoId = int.tryParse(v ?? ''));
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: valorController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Valor (R\$)',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1565C0), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: historicoController,
                          decoration: InputDecoration(
                            labelText: 'Histórico (opcional)',
                            prefixIcon: const Icon(Icons.notes),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1565C0), width: 2),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Rodapé
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1565C0),
                          side: const BorderSide(color: Color(0xFF1565C0)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancelar',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (contaDestinoId == null ||
                              valorController.text.isEmpty) {
                            _showSnack(
                                ctx, "Preencha todos os campos obrigatórios.");
                            return;
                          }
                          Navigator.pop(ctx);
                          _showLoadingDialog(context, "Transferindo...");
                          final sucesso = await caller.transferirSaldo(
                            contaOrigemId: conta.id!,
                            contaDestinoId: contaDestinoId!,
                            valor: double.parse(
                                valorController.text.replaceAll(',', '.')),
                            empresaId: conta.empresa.id!,
                            parceiroId: conta.parceiro?.id,
                            historico: historicoController.text,
                          );
                          if (context.mounted) Navigator.pop(context);
                          if (context.mounted) {
                            sucesso
                                ? _showSuccessDialog(
                                    context, "Transferência concluída!")
                                : _showSnack(context, "Erro ao transferir.");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Confirmar',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExtratoDialog(
      BuildContext context, ContaBancaria conta, ContaBancariaCaller caller) {
    DateTime? dataDe;
    DateTime? dataAte;

    String formatarData(DateTime? d) {
      if (d == null) return '';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    String paraApi(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Gerar Extrato PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Corpo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Data inicial
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: dataDe ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (d != null) setStateDialog(() => dataDe = d);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data inicial',
                          prefixIcon:
                              const Icon(Icons.calendar_today, size: 18),
                          suffixIcon:
                              const Icon(Icons.arrow_drop_down, size: 22),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF1B5E20), width: 2),
                          ),
                        ),
                        child: Text(
                          dataDe != null
                              ? formatarData(dataDe)
                              : 'Selecione a data',
                          style: TextStyle(
                            color: dataDe != null
                                ? Colors.black87
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Data final
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: dataAte ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (d != null) setStateDialog(() => dataAte = d);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data final',
                          prefixIcon:
                              const Icon(Icons.calendar_today, size: 18),
                          suffixIcon:
                              const Icon(Icons.arrow_drop_down, size: 22),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Color(0xFF1B5E20), width: 2),
                          ),
                        ),
                        child: Text(
                          dataAte != null
                              ? formatarData(dataAte)
                              : 'Selecione a data',
                          style: TextStyle(
                            color: dataAte != null
                                ? Colors.black87
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Rodapé
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancelar',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (dataDe == null || dataAte == null) {
                            _showSnack(ctx, "Selecione as duas datas.");
                            return;
                          }
                          Navigator.pop(ctx);
                          _showLoadingDialog(context, "Gerando PDF...");
                          final pdf = await caller.gerarExtratoPdf(
                            contaId: conta.id!,
                            empresaId: conta.empresa.id!,
                            parceiroId: conta.parceiro?.id,
                            de: paraApi(dataDe!),
                            ate: paraApi(dataAte!),
                          );
                          if (context.mounted) Navigator.pop(context);
                          if (pdf != null && context.mounted) {
                            final dir = await getTemporaryDirectory();
                            final file =
                                File('${dir.path}/extrato_${conta.id}.pdf');
                            await file.writeAsBytes(pdf);
                            final uri = Uri.file(file.path);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                            if (context.mounted) {
                              _showSuccessDialog(
                                  context, "PDF gerado com sucesso!");
                            }
                          } else if (context.mounted) {
                            _showSnack(context, "Erro ao gerar PDF.");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Gerar PDF',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExtratoConsolidado(BuildContext context, ContaBancaria conta) {
    final deController = TextEditingController();
    final ateController = TextEditingController();
    final caller = ContaBancariaCaller();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Extrato Consolidado"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: deController,
                decoration: const InputDecoration(labelText: "Data inicial")),
            TextField(
                controller: ateController,
                decoration: const InputDecoration(labelText: "Data final")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            onPressed: () async {
              final de = deController.text;
              final ate = ateController.text;
              if (de.isEmpty || ate.isEmpty) {
                _showSnack(context, "Informe as duas datas.");
                return;
              }
              _showLoadingDialog(context, "Gerando consolidado...");
              // Usa o mesmo endpoint de extrato PDF para consolidado
              final pdf = await ContaBancariaCaller().gerarExtratoPdf(
                contaId: conta.id!,
                empresaId: conta.empresa.id!,
                parceiroId: conta.parceiro?.id,
                de: de,
                ate: ate,
              );
              if (context.mounted) Navigator.pop(context);
              if (pdf != null && context.mounted) {
                final dir = await getTemporaryDirectory();
                final file =
                    File('${dir.path}/extrato_consolidado_${conta.id}.pdf');
                await file.writeAsBytes(pdf);
                final uri = Uri.file(file.path);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (context.mounted)
                  _showSuccessDialog(context, "Consolidado gerado!");
              } else if (context.mounted) {
                _showSnack(context, "Erro ao gerar consolidado.");
              }
            },
            child: const Text("Gerar Consolidado"),
          )
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showLoadingDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(msg),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(fontSize: 16)),
          ]),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (Navigator.canPop(context)) Navigator.pop(context);
    });
  }
}
