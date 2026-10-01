import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_receber_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/grid_texts.dart';
import '../../../widgets/finance/billing_charge_dialog.dart';
import '../../../widgets/boleto_importacao_lote_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows, FieldType;
import '../../../windows/screens/baixa_dialog_receber.dart';
import '../../../windows/dialogs/parcelar_receber_dialog.dart';
import '../../../windows/dialogs/recorrencia_receber_dialog.dart';
import '../../../windows/dialogs/renegociacao_receber_dialog.dart';
import '../../../widgets/anexo_financeiro_widget.dart';
import '../../../widgets/finance/financeiro_parceiro_field_rules.dart';
import 'package:http/http.dart' as http;

class WindowsContaReceberGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  // Fix card #453: filtro fixo de categoria financeira (tela Mensalidades).
  final int? categoriaFinanceiraIdFixa;
  // Fix card #470: titulo do cabeçalho vem do backend a partir de telaNome
  // ("conta_receber" -> "Conta Receber"), mas a tela Mensalidades reaproveita
  // essa mesma grid filtrada e precisa exibir "Mensalidades".
  final String? tituloOverride;

  const WindowsContaReceberGridScreen({
    super.key,
    required this.hasPermission,
    this.categoriaFinanceiraIdFixa,
    this.tituloOverride,
  });

  @override
  State<WindowsContaReceberGridScreen> createState() =>
      _WindowsContaReceberGridScreenState();
}

class _WindowsContaReceberGridScreenState
    extends State<WindowsContaReceberGridScreen> {
  bool _importing = false;

  String _statusFilter = GridTexts.all;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  int? _parceiroId;
  String _tipoFilter = GridTexts.all;
  final _statusOptions = [
    GridTexts.all,
    GridTexts.accountStatusOpen,
    GridTexts.accountStatusPaid,
    GridTexts.accountStatusOverdue,
    GridTexts.accountStatusPartial,
    GridTexts.accountStatusCancelled,
  ];
  final _tipoOptions = [
    GridTexts.all,
    GridTexts.accountTypeSingle,
    GridTexts.accountTypeRecurring,
    GridTexts.accountTypeInstallment,
  ];

  Key _gridKey = UniqueKey();

  Map<String, dynamic> get _filterParams {
    final params = <String, dynamic>{};
    if (_statusFilter != GridTexts.all) params['status'] = _statusFilter;
    if (_dataInicio != null)
      params['dataInicio'] = _dataInicio!.toIso8601String().substring(0, 10);
    if (_dataFim != null)
      params['dataFim'] = _dataFim!.toIso8601String().substring(0, 10);
    if (_parceiroId != null) params['parceiroId'] = _parceiroId.toString();
    if (_tipoFilter != GridTexts.all) params['tipo'] = _tipoFilter;
    if (widget.categoriaFinanceiraIdFixa != null) {
      params['categoriaFinanceiraId'] =
          widget.categoriaFinanceiraIdFixa.toString();
    }
    return params;
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = GridTexts.all;
      _dataInicio = null;
      _dataFim = null;
      _parceiroId = null;
      _tipoFilter = GridTexts.all;
      _gridKey = UniqueKey();
    });
  }

  void _applyFilters() {
    setState(() => _gridKey = UniqueKey());
  }

  Future<void> _importarBoleto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'rem', 'ret', 'txt'],
      withData: true,
    );
    if (result == null || !mounted) return;

    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      _snack(GridTexts.fileReadError, error: true);
      return;
    }

    setState(() => _importing = true);
    try {
      final importUrl = TenantContext.empresaId == null
          ? ApiLinks.importacaoContaReceber
          : '${ApiLinks.importacaoContaReceber}?empId=${TenantContext.empresaId}';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(importUrl),
      );
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
        _snack(GridTexts.importCompletedCount(importados));
      } else {
        _snack(GridTexts.errorWithStatus(response.statusCode), error: true);
      }
    } catch (e) {
      if (mounted) _snack(GridTexts.genericError(e.toString()), error: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  Future<void> _pickDate({required bool isInicio}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInicio)
          _dataInicio = picked;
        else
          _dataFim = picked;
      });
    }
  }

  List<Widget> _buildFilterBar() {
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GridColors.filterBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(GridTexts.statusLabel,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            SizedBox(
              width: 140,
              height: 36,
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                isDense: true,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _statusFilter = v!),
              ),
            ),
            const SizedBox(width: 12),
            const Text(GridTexts.periodLabel,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            InkWell(
              onTap: () => _pickDate(isInicio: true),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: GridColors.divider),
                    borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(
                      _dataInicio != null
                          ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}'
                          : GridTexts.start,
                      style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ),
            const Text(' ${GridTexts.until} ', style: TextStyle(fontSize: 13)),
            InkWell(
              onTap: () => _pickDate(isInicio: false),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: GridColors.divider),
                    borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(
                      _dataFim != null
                          ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}'
                          : GridTexts.end,
                      style: const TextStyle(fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            const Text(GridTexts.typeLabel,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            SizedBox(
              width: 130,
              height: 36,
              child: DropdownButtonFormField<String>(
                value: _tipoFilter,
                isDense: true,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  border: OutlineInputBorder(),
                ),
                items: _tipoOptions
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _tipoFilter = v!),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.search, size: 18),
                label: const Text(GridTexts.filter,
                    style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear, size: 18),
                label:
                    const Text(GridTexts.clear, style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final parceiroIdContexto =
        FinanceiroParceiroFieldRules.normalizarParceiroId(
      TenantContext.parceiroId,
    );
    final parceiroSelecionado = parceiroIdContexto?.toString();
    final parceiroHabilitado = FinanceiroParceiroFieldRules.parceiroHabilitado(
      parceiroId: parceiroIdContexto,
    );
    final fornecedorHabilitado =
        FinanceiroParceiroFieldRules.fornecedorHabilitado(
      parceiroId: parceiroIdContexto,
    );

    return Column(
      children: [
        ..._buildFilterBar(),
        const SizedBox(height: 8),
        Expanded(
          child: DynamicGridWindowsScreen<ContaReceber>(
            key: _gridKey,
            telaNome: 'conta_receber',
            tituloOverride: widget.tituloOverride,
            hasPermission: widget.hasPermission,
            fromJson: (json) => ContaReceber.fromJson(json),
            toJson: (a) => a.toJson(),
            fetchEndpointOverride: ApiLinks.allContasReceber,
            createEndpointOverride: ApiLinks.createContaReceber,
            updateEndpointOverride: ApiLinks.updateContaReceber(':id'),
            deleteEndpointOverride: ApiLinks.deleteContaReceber(':id'),
            extraParams: _filterParams,
            fieldOverrides: [
              // Fornecedor (parceiroDev): 2o campo, dropdown com todos os parceiros
              FieldConfigWindows(
                  fieldName: 'parceiroDev',
                  label: 'Cliente',
                  isInForm: true,
                  isInGrid: false,
                  isVisibleByDefault: false,
                  fieldType: FieldType.dropdown,
                  enabled: fornecedorHabilitado,
                  fieldOrder: 11,
                  dropdownRemoteSearch: DropdownHelpers.parceirosBusca,
                  dropdownResolveLabel: DropdownHelpers.parceiroLabelPorId,
                  dropdownValueField: 'id',
                  dropdownDisplayField: 'nome'),
              // Parceiro: travado apenas quando existe parceiro no login.
              FieldConfigWindows(
                  fieldName: 'parceiro',
                  label: 'Parceiro',
                  isInForm: true,
                  isInGrid: false,
                  isVisibleByDefault: false,
                  fieldType: FieldType.dropdown,
                  enabled: parceiroHabilitado,
                  fieldOrder: 12,
                  dropdownSelectedValue: parceiroSelecionado,
                  dropdownRemoteSearch: DropdownHelpers.parceirosBusca,
                  dropdownResolveLabel: DropdownHelpers.parceiroLabelPorId,
                  dropdownValueField: 'id',
                  dropdownDisplayField: 'nome'),
              // Parceiro Rec: pré-marcado com parceiro do login (editável)
              FieldConfigWindows(
                  fieldName: 'parceiroRec',
                  label: 'Parceiro Rec',
                  isInForm: TenantContext.hasParceiro,
                  isInGrid: false,
                  isVisibleByDefault: false,
                  fieldType: FieldType.dropdown,
                  enabled: true,
                  fieldOrder: 13,
                  dropdownSelectedValue: parceiroSelecionado,
                  dropdownRemoteSearch: DropdownHelpers.parceirosBusca,
                  dropdownResolveLabel: DropdownHelpers.parceiroLabelPorId,
                  dropdownValueField: 'id',
                  dropdownDisplayField: 'nome'),
              // Competência Obrigação: dropdown de obrigações fiscais, envia descricao como string
              FieldConfigWindows(
                  fieldName: 'competenciaObrigacao',
                  label: 'Competência Obrigação',
                  isInForm: true,
                  isInGrid: false,
                  isVisibleByDefault: false,
                  fieldType: FieldType.dropdown,
                  enabled: true,
                  visibleWhenField: 'obrigacaoFiscal',
                  visibleWhenValue: true,
                  dropdownFutureBuilder: () async {
                    final token = AuthUtility.userInfo?.token;
                    final resp = await http.get(
                      Uri.parse('${ApiLinks.baseUrl}/api/obrigacao_fiscal'),
                      headers: {'Authorization': 'Bearer $token'},
                    );
                    if (resp.statusCode == 200) {
                      final decoded = jsonDecode(resp.body);
                      final raw = decoded is List
                          ? decoded
                          : (decoded is Map ? decoded['data'] : null);
                      final list = (raw is List) ? raw : <dynamic>[];
                      return list
                          .map<Map<String, dynamic>>((e) => {
                                'value': e['descricao'] ?? e['nome'] ?? '',
                                'label': e['descricao'] ?? e['nome'] ?? '',
                              })
                          .toList();
                    }
                    return <Map<String, dynamic>>[];
                  },
                  dropdownValueField: 'value',
                  dropdownDisplayField: 'label'),
              // Tipo Recorrência: só aparece quando recorrenciaAtiva está marcado
              FieldConfigWindows(
                  fieldName: 'tipoRecorrencia',
                  label: 'Tipo Recorrência',
                  isInForm: true,
                  isInGrid: false,
                  isVisibleByDefault: false,
                  fieldType: FieldType.dropdown,
                  enabled: true,
                  visibleWhenField: 'recorrenciaAtiva',
                  visibleWhenValue: true,
                  fieldOrder: 56,
                  dropdownFutureBuilder: () async {
                    final token = AuthUtility.userInfo?.token;
                    final resp = await http.get(
                      Uri.parse(
                          '${ApiLinks.baseUrl}/api/enums/TipoRecorrenciaEnum'),
                      headers: {'Authorization': 'Bearer $token'},
                    );
                    if (resp.statusCode == 200) {
                      final decoded = jsonDecode(resp.body);
                      final raw = decoded is List
                          ? decoded
                          : (decoded is Map ? decoded['data'] : null);
                      final list = (raw is List) ? raw : <dynamic>[];
                      return list
                          .map<Map<String, dynamic>>((e) => {
                                'value': e['value'] ?? e,
                                'label':
                                    e['label'] ?? e['value'] ?? e.toString(),
                              })
                          .toList();
                    }
                    return <Map<String, dynamic>>[];
                  },
                  dropdownValueField: 'value',
                  dropdownDisplayField: 'label'),
              // Quantidade Recorrência
              FieldConfigWindows(
                  fieldName: 'quantidadeRecorrencia',
                  label: 'Quantidade Recorrência',
                  isInForm: true,
                  isInGrid: false,
                  isVisibleByDefault: false,
                  fieldType: FieldType.number,
                  enabled: true,
                  visibleWhenField: 'recorrenciaAtiva',
                  visibleWhenValue: true,
                  fieldOrder: 57),
              // Dia Vencimento
              FieldConfigWindows(
                  fieldName: 'diaVencimento',
                  label: 'Dia Vencimento',
                  isInForm: true,
                  isInGrid: false,
                  isVisibleByDefault: false,
                  fieldType: FieldType.number,
                  enabled: true,
                  visibleWhenField: 'recorrenciaAtiva',
                  visibleWhenValue: true,
                  fieldOrder: 58),
            ],
            headerActions: [
              // Fix card #470: este botão importava arquivo de retorno
              // bancário (CSV/REM/RET/TXT via /api/importacao/conta-receber),
              // mas estava rotulado como boleto -- confundia com importação
              // de PDF (ver botão "Importar Boletos (PDF)" abaixo). Renomeado
              // para refletir o que ele de fato faz.
              OutlinedButton.icon(
                onPressed: _importing ? null : _importarBoleto,
                icon: _importing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: GridColors.secondary),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: const Text('Importar Retorno CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GridColors.secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: const BorderSide(color: GridColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
              // Fix card #470: import multi-arquivo de boletos PDF com
              // leitura automática (CNPJ/valor/vencimento) e preview antes de
              // confirmar -- reaproveita BoletoImportacaoLoteScreen já
              // existente (antes só acessível pelo menu "Importação Boletos
              // Lote"), agora também disponível direto na tela de Mensalidades.
              OutlinedButton.icon(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 900, maxHeight: 700),
                        child: Stack(
                          children: [
                            const BoletoImportacaoLoteScreen(),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Fechar',
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  if (mounted) setState(() => _gridKey = UniqueKey());
                },
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Importar Boletos (PDF)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GridColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: const BorderSide(color: GridColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
            customActions: () => [
              CustomAction<ContaReceber>(
                icon: Icons.receipt_long,
                label: GridTexts.charge,
                onPressed: (context, object) =>
                    _showBillingDialog(context, object),
                isVisible: (c) => c.status == StatusConta.ABERTA,
              ),
              CustomAction<ContaReceber>(
                icon: Icons.price_check,
                label: GridTexts.lower,
                onPressed: (context, object) =>
                    _showBaixaDialog(context, object),
                isVisible: (c) => c.status == StatusConta.ABERTA,
              ),
              CustomAction<ContaReceber>(
                icon: Icons.credit_card,
                label: GridTexts.installment,
                onPressed: (context, object) =>
                    _showParcelarDialog(context, object),
                isVisible: (c) => c.status == StatusConta.ABERTA,
              ),
              CustomAction<ContaReceber>(
                icon: Icons.repeat,
                label: GridTexts.recurrence,
                onPressed: (context, object) =>
                    _showRecorrenciaDialog(context, object),
                isVisible: (c) => c.status == StatusConta.ABERTA,
              ),
              CustomAction<ContaReceber>(
                icon: Icons.swap_horiz,
                label: GridTexts.renegotiate,
                onPressed: (context, object) =>
                    _showRenegociacaoDialog(context, object),
                isVisible: (c) => c.status == StatusConta.ABERTA,
              ),
              CustomAction<ContaReceber>(
                icon: Icons.attach_file,
                label: GridTexts.attachments,
                badgeCount: (obj) => obj.qtdAnexos,
                onPressed: (context, object) =>
                    _showAnexosDialog(context, object),
                isVisible: (obj) => obj.id != null,
              ),
              CustomAction<ContaReceber>(
                icon: Icons.receipt,
                label: GridTexts.billingTicket,
                onPressed: (context, object) =>
                    _showBoletoDialog(context, object),
                isVisible: (obj) => obj.id != null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBaixaDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) => BaixaDialogReceber(conta: conta),
    ).then((result) {
      if (result == true && mounted) {
        setState(() => _gridKey = UniqueKey());
      }
    });
  }

  void _showAnexosDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: SizedBox(
          width: 600,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              color: GridColors.dialogBackground,
              elevation: 8,
              shadowColor: GridColors.shadow,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: GridColors.primary,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file,
                            color: GridColors.textPrimary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Anexos',
                            style: TextStyle(
                              color: GridColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close,
                              color: GridColors.textPrimaryMuted, size: 20),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 400,
                    child: AnexoFinanceiroWidget(
                      lancamentoId: conta.id!,
                      lancamentoTipo: 'RECEBER',
                      empresaId: conta.empresa.id,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBoletoDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      // Fix card #426 (Opcao C): "Boleto" era feature orfa (endpoint
      // /rest/boleto/upload nunca existiu). Agora reaproveita o fluxo de
      // Anexo ja funcional. O widget ja tem seu proprio header/close.
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 560),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              color: GridColors.dialogBackground,
              elevation: 8,
              shadowColor: GridColors.shadow,
              child: AnexoFinanceiroWidget(
                lancamentoId: conta.id!,
                lancamentoTipo: 'RECEBER',
                empresaId: conta.empresa.id,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBillingDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) => BillingChargeDialog(conta: conta),
    );
  }

  void _showParcelarDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ParcelarReceberDialog(conta: conta),
    );
  }

  void _showRecorrenciaDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) => RecorrenciaReceberDialog(conta: conta),
    );
  }

  void _showRenegociacaoDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          RenegociacaoReceberDialog(conta: conta),
    );
  }
}
