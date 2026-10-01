import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_receber_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/finance/billing_charge_dialog.dart';
import '../../../widgets/boleto_importacao_lote_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows, FieldType;
import '../../../web/screens/baixa_dialog_receber.dart';
import '../../../web/dialogs/baixa_lote_dialog.dart';
import '../../../web/dialogs/parcelar_receber_dialog.dart';
import '../../../web/dialogs/recorrencia_receber_dialog.dart';
import '../../../web/dialogs/renegociacao_receber_dialog.dart';
import 'package:http/http.dart' as http;

import '../../../web/dialogs/anexo_upload_dialog.dart';
import '../../../web/dialogs/export_power_bi_dialog.dart';
import '../../../widgets/anexo_financeiro_widget.dart';
import '../../../utils/grid_texts.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../models/auth_utility.dart';
import '../../../widgets/finance/financeiro_parceiro_field_rules.dart';

class WebContaReceberGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  // Fix card #453: permite instanciar esta grid ja filtrada por categoria
  // financeira fixa (ex.: 'Receita de Assinatura' para a tela Mensalidades),
  // reaproveitando toda a infraestrutura existente (listagem, dar baixa,
  // anexos) em vez de duplicar uma tela nova do zero.
  final int? categoriaFinanceiraIdFixa;
  // Fix card #470: titulo do cabeçalho vem do backend a partir de telaNome
  // ("conta_receber" -> "Conta Receber"), mas a tela Mensalidades reaproveita
  // essa mesma grid filtrada e precisa exibir "Mensalidades".
  final String? tituloOverride;
  const WebContaReceberGridScreen({
    super.key,
    required this.hasPermission,
    this.categoriaFinanceiraIdFixa,
    this.tituloOverride,
  });

  @override
  State<WebContaReceberGridScreen> createState() =>
      _WebContaReceberGridScreenState();
}

class _WebContaReceberGridScreenState extends State<WebContaReceberGridScreen> {
  bool _importing = false;

  String _statusFilter = 'Todos';
  DateTime? _dataInicio;
  DateTime? _dataFim;
  int? _parceiroId;
  String _tipoFilter = 'Todos';
  final _statusOptions = [
    'Todos',
    'ABERTA',
    'BAIXADA',
    'VENCIDO',
    'PARCIAL',
    'CANCELADA'
  ];
  final _tipoOptions = ['Todos', 'AVULSO', 'RECORRENTE', 'PARCELADO'];

  Key _gridKey = UniqueKey();
  Set<String> _selectedRows = {};
  List<Map<String, dynamic>> _selectedRowData = [];

  Map<String, dynamic> get _filterParams {
    final params = <String, dynamic>{};
    if (_statusFilter != 'Todos') params['status'] = _statusFilter;
    if (_dataInicio != null)
      params['dataInicio'] = _dataInicio!.toIso8601String().substring(0, 10);
    if (_dataFim != null)
      params['dataFim'] = _dataFim!.toIso8601String().substring(0, 10);
    if (_parceiroId != null) params['parceiroId'] = _parceiroId.toString();
    if (_tipoFilter != 'Todos') params['tipo'] = _tipoFilter;
    if (widget.categoriaFinanceiraIdFixa != null) {
      params['categoriaFinanceiraId'] =
          widget.categoriaFinanceiraIdFixa.toString();
    }
    return params;
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = 'Todos';
      _dataInicio = null;
      _dataFim = null;
      _parceiroId = null;
      _tipoFilter = 'Todos';
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
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      _snack('Não foi possível ler o arquivo', error: true);
      return;
    }

    setState(() => _importing = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.importacaoContaReceber),
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
        _snack('Importação concluída: $importados registro(s)');
      } else {
        _snack('Erro na importação (${response.statusCode})', error: true);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
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

  void _onSelectedRowsChanged(
      Set<String> rows, List<Map<String, dynamic>> rowData) {
    setState(() {
      _selectedRows = rows;
      _selectedRowData = rowData;
    });
  }

  void _abrirBaixaLote() {
    if (_selectedRows.isEmpty) return;
    final ids = _selectedRows.map((id) => int.parse(id)).toList();
    // Use the actual row data from the grid instead of dummy maps
    final contas = List<Map<String, dynamic>>.from(_selectedRowData);
    showDialog(
      context: context,
      builder: (_) => BaixaLoteDialog(
        isPagar: false,
        selectedIds: ids,
        selectedContas: contas,
      ),
    ).then((result) {
      if (result == true) {
        setState(() => _gridKey = UniqueKey());
        _selectedRows.clear();
        _selectedRowData = [];
      }
    });
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

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GridColors.filterBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Status:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          SizedBox(
            width: 140,
            height: 36,
            child: DropdownButtonFormField<String>(
              value: _statusFilter,
              isDense: true,
              isExpanded: true,
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
          const Text('Período:',
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
                        : 'Início',
                    style: const TextStyle(fontSize: 13)),
              ]),
            ),
          ),
          const Text(' até ', style: TextStyle(fontSize: 13)),
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
                        : 'Fim',
                    style: const TextStyle(fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Tipo:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          SizedBox(
            width: 160,
            height: 36,
            child: DropdownButtonFormField<String>(
              value: _tipoFilter,
              isDense: true,
              isExpanded: true,
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
              label: const Text('Filtrar', style: TextStyle(fontSize: 13)),
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
              label: const Text('Limpar', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
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
        _buildFilterBar(),
        const SizedBox(height: 8),
        Expanded(
          child: DynamicGridWindowsScreen<Map<String, dynamic>>(
            key: _gridKey,
            telaNome: 'conta_receber',
            tituloOverride: widget.tituloOverride,
            hasPermission: widget.hasPermission,
            fromJson: (json) => json,
            toJson: (a) => a,
            fetchEndpointOverride: ApiLinks.allContasReceber,
            createEndpointOverride: ApiLinks.createContaReceber,
            updateEndpointOverride: ApiLinks.updateContaReceber(':id'),
            deleteEndpointOverride: ApiLinks.deleteContaReceber(':id'),
            extraParams: _filterParams,
            fieldOverrides: [
              // Cliente (parceiroDev): 2o campo, dropdown com todos os parceiros (quem nos deve)
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
              // Parceiro Rec: dropdown com todos os parceiros, pré-marcado com o parceiro do login (editável)
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
              // Só aparece quando obrigacaoFiscal está marcado
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
              // Quantidade Recorrência: só aparece quando recorrenciaAtiva está marcado
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
              // Dia Vencimento: só aparece quando recorrenciaAtiva está marcado
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
              // mas estava rotulado "Importar Boleto" -- confundia com
              // importação de PDF de boleto (fluxo diferente, ver botão
              // "Importar Boletos (PDF)" abaixo). Renomeado para refletir o
              // que ele de fato faz.
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
              // confirmar -- reaproveita a tela BoletoImportacaoLoteScreen já
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
                  // Recarrega a grid ao fechar o dialog -- barato mesmo se
                  // nada foi confirmado, e garante que mensalidades recem
                  // criadas apareçam sem precisar de refresh manual.
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
              if (_selectedRows.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _abrirBaixaLote,
                  icon: const Icon(Icons.playlist_add_check, size: 18),
                  label: Text('Baixa em Lote (${_selectedRows.length})'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GridColors.secondary,
                    backgroundColor: GridColors.secondarySoft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    side: const BorderSide(color: GridColors.secondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) =>
                      const ExportPowerBiDialog(tipoInicial: 'conta_receber'),
                ),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exportar'),
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
            onSelectedRowsChanged: _onSelectedRowsChanged,
            customActions: () => [
              CustomAction<Map<String, dynamic>>(
                icon: Icons.receipt_long,
                label: GridTexts.charge,
                onPressed: (context, object) => showDialog(
                  context: context,
                  builder: (_) => BillingChargeDialog(
                    conta: ContaReceber.fromJson(object),
                  ),
                ),
                isVisible: (m) =>
                    ContaReceber.fromJson(m).status == StatusConta.ABERTA,
              ),
              CustomAction<Map<String, dynamic>>(
                icon: Icons.price_check,
                label: GridTexts.lower,
                onPressed: (context, object) {
                  showDialog(
                    context: context,
                    builder: (_) => WebBaixaDialogReceber(
                        conta: ContaReceber.fromJson(object)),
                  ).then((result) {
                    if (result == true && context.mounted) {
                      setState(() => _gridKey = UniqueKey());
                    }
                  });
                },
                isVisible: (m) =>
                    ContaReceber.fromJson(m).status == StatusConta.ABERTA,
              ),
              CustomAction<Map<String, dynamic>>(
                icon: Icons.credit_card,
                label: GridTexts.installment,
                onPressed: (context, object) => showDialog(
                  context: context,
                  builder: (_) => WebParcelarReceberDialog(
                      conta: ContaReceber.fromJson(object)),
                ),
                isVisible: (m) =>
                    ContaReceber.fromJson(m).status == StatusConta.ABERTA,
              ),
              CustomAction<Map<String, dynamic>>(
                icon: Icons.repeat,
                label: GridTexts.recurrence,
                onPressed: (context, object) => showDialog(
                  context: context,
                  builder: (_) => WebRecorrenciaReceberDialog(
                      conta: ContaReceber.fromJson(object)),
                ),
                isVisible: (m) =>
                    ContaReceber.fromJson(m).status == StatusConta.ABERTA,
              ),
              CustomAction<Map<String, dynamic>>(
                icon: Icons.swap_horiz,
                label: GridTexts.renegotiate,
                onPressed: (context, object) => showDialog(
                  context: context,
                  builder: (_) => WebRenegociacaoReceberDialog(
                      conta: ContaReceber.fromJson(object)),
                ),
                isVisible: (m) =>
                    ContaReceber.fromJson(m).status == StatusConta.ABERTA,
              ),
              CustomAction<Map<String, dynamic>>(
                icon: Icons.attach_file,
                label: GridTexts.attachments,
                badgeCount: (obj) => (obj['qtdAnexos'] as num?)?.toInt() ?? 0,
                onPressed: (context, object) {
                  final id = object['id'];
                  showDialog(
                    context: context,
                    builder: (_) => AnexoUploadDialog(
                      lancamentoId: id is int ? id : int.tryParse('$id') ?? 0,
                      lancamentoTipo: 'RECEBER',
                    ),
                  );
                },
                isVisible: (obj) => (obj['id'] as num?)?.toInt() != null,
              ),
              CustomAction<Map<String, dynamic>>(
                icon: Icons.receipt,
                label: GridTexts.billingTicket,
                onPressed: (context, object) {
                  final id = object['id'];
                  showDialog(
                    context: context,
                    // Fix card #426 (Opcao C): "Boleto" era feature orfa
                    // (endpoint /rest/boleto/upload nunca existiu). Agora
                    // reaproveita o fluxo de Anexo ja funcional. O widget
                    // ja tem seu proprio header/close, entao nao duplicamos.
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 500, maxHeight: 560),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Material(
                            color: GridColors.dialogBackground,
                            elevation: 8,
                            shadowColor: GridColors.shadow,
                            child: AnexoFinanceiroWidget(
                              lancamentoId:
                                  id is int ? id : int.tryParse('$id') ?? 0,
                              lancamentoTipo: 'RECEBER',
                              empresaId:
                                  (object['empresa']?['id'] as num?)?.toInt(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                isVisible: (obj) => (obj['id'] as num?)?.toInt() != null,
              ),
              CustomAction<Map<String, dynamic>>(
                icon: Icons.copy,
                label: 'Clonar',
                onPressed: (context, object) async {
                  final id = object['id'];
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
                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lançamento #$id clonado com sucesso!'),
                          backgroundColor: GridColors.success,
                        ),
                      );
                      setState(() => _gridKey = UniqueKey());
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Erro ao clonar: ${response.statusCode}'),
                          backgroundColor: GridColors.error,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro: $e'),
                          backgroundColor: GridColors.error,
                        ),
                      );
                    }
                  }
                },
                isVisible: (_) => true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
