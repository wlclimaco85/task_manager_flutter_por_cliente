import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/responsive/responsive_helper.dart';
import '../../models/auth_utility.dart';
import '../../models/nfe/nfe_item_model.dart';
import '../../services/nfe_saida_service.dart';
import '../../utils/api_links.dart';
import '../../utils/nfe_totais_calculator.dart';
import '../../utils/tenant_context.dart';
import '../../utils/grid_colors.dart';
import '../../widgets/nfe/nfe_item_form_dialog.dart';
import '../../widgets/nfe/nfe_items_table.dart';
import '../../widgets/searchable_dropdown.dart';

const _primary = GridColors.primary;
const _success = GridColors.success;
const _error = GridColors.error;
const _bg = GridColors.pageBackground;
const _cardBg = GridColors.card;
const _border = GridColors.borderSubtle;
const _taxBoxBg = GridColors.secondarySoft;
const _taxBoxBorder = GridColors.divider;

class NfeSaidaCreateScreen extends StatefulWidget {
  const NfeSaidaCreateScreen({super.key});

  @override
  State<NfeSaidaCreateScreen> createState() => _NfeSaidaCreateScreenState();
}

class _NfeSaidaCreateScreenState extends State<NfeSaidaCreateScreen> {
  final _service = NfeSaidaService();

  List<Map<String, dynamic>> _topList = [];
  final List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _parceiros = [];
  List<Map<String, dynamic>> _destinatarios = [];
  List<Map<String, dynamic>> _formasPagamento = [];
  List<Map<String, dynamic>> _finalidades = [];
  List<Map<String, dynamic>> _series = [];

  Map<String, dynamic>? _topSelected;
  String? _empresaId;
  String? _parceiroId;
  String? _destinatarioId;
  String? _formaPagId;
  String? _finalidadeId;
  String? _serieVal;

  final _formKey = GlobalKey<FormState>();
  final _numeroCtrl = TextEditingController();
  String? _ambienteVal = 'HOMOLOGACAO';

  bool _saving = false;
  bool _isLoading = true;

  // Itens da NFe (antes ausentes nesta tela — ver NfeItemFormDialog)
  final List<NfeItemModel> _items = [];
  NfeTotais _totais = NfeTotais.zero;

  @override
  void initState() {
    super.initState();
    _loadDados();
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDados() async {
    final login = AuthUtility.userInfo?.login;
    final empId = login?.empresa?.id?.toString();
    final parcId = login?.parceiro?.id?.toString();

    _empresaId = empId;
    _parceiroId = parcId;

    final results = await Future.wait([
      _service.carregarTiposOperacao(),
      _loadList('${ApiLinks.baseUrl}/api/forma_pagamento?tamanho=100'),
      _loadList('${ApiLinks.baseUrl}/api/nfe-finalidade?tamanho=50'),
      _loadList(
          '${ApiLinks.baseUrl}/api/nfe-serie?tamanho=100${empId != null ? '&empId=$empId' : ''}'),
      _loadList(
          '${ApiLinks.baseUrl}/api/parceiro?tamanho=500${empId != null ? '&empId=$empId' : ''}'),
    ]);

    if (!mounted) return;
    final series = _dedupeByValue(
      results[3],
      _serieValue,
    );
    final currentSerie =
        _validDropdownValue(_serieVal, series.map(_serieValue));
    setState(() {
      _topList = results[0];
      _formasPagamento = results[1];
      _finalidades = results[2];
      _series = series;
      _serieVal = currentSerie;
      _parceiros = results[4];
      _destinatarios = results[4];
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _loadList(String url) async {
    try {
      final r = await TenantContext.get(url);
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        List raw = [];
        if (b is List) {
          raw = b;
        } else if (b is Map) {
          final data = b['data'];
          if (data is List) {
            raw = data;
          } else if (data is Map) {
            raw = data['dados'] ?? data['content'] ?? [];
          } else {
            raw = b['dados'] ?? b['content'] ?? [];
          }
        }
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  String _serieValue(Map<String, dynamic> serie) =>
      (serie['serie'] ?? serie['numero'] ?? serie['id'] ?? '').toString();

  String _serieLabel(Map<String, dynamic> serie) {
    final numero = (serie['serie'] ?? serie['numero'])?.toString();
    final descricao = serie['descricao']?.toString();
    if (numero != null && numero.isNotEmpty) {
      return descricao != null && descricao.isNotEmpty
          ? '$numero - $descricao'
          : numero;
    }
    return serie['id']?.toString() ?? '';
  }

  List<Map<String, dynamic>> _dedupeByValue(
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic>) valueOf,
  ) {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final item in items) {
      final value = valueOf(item);
      if (value.isEmpty || !seen.add(value)) continue;
      unique.add(item);
    }
    return unique;
  }

  String? _validDropdownValue(String? value, Iterable<String> itemValues) {
    if (value == null || value.isEmpty) return null;
    return itemValues.where((itemValue) => itemValue == value).length == 1
        ? value
        : null;
  }

  void _onTopSelected(Map<String, dynamic>? top) {
    setState(() => _topSelected = top);
  }

  /// Abre o dialog para adicionar um novo item
  Future<void> _adicionarItem() async {
    final item = await NfeItemFormDialog.show(
      context,
      proximoSequencial: _items.length + 1,
    );
    if (item == null) return;
    setState(() {
      _items.add(item);
      _totais = NfeTotaisCalculator.calcular(_items);
    });
  }

  /// Abre o dialog para editar um item existente
  Future<void> _editarItem(int index) async {
    if (index < 0 || index >= _items.length) return;
    final item = await NfeItemFormDialog.show(
      context,
      item: _items[index],
      proximoSequencial: _items[index].sequencial,
    );
    if (item == null) return;
    setState(() {
      _items[index] = item;
      _totais = NfeTotaisCalculator.calcular(_items);
    });
  }

  void _removerItem(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      _items.removeAt(index);
      _totais = NfeTotaisCalculator.calcular(_items);
    });
  }

  Future<void> _salvar() async {
    final erros = <String>[];
    if (_topSelected == null) erros.add('Tipo de Operação');
    if (_empresaId == null || _empresaId!.isEmpty) erros.add('Empresa');
    if (_serieVal == null || _serieVal!.isEmpty) erros.add('Série');
    if (_items.isEmpty) erros.add('Itens (adicione ao menos 1)');
    if (erros.isNotEmpty) {
      _snack('Campos obrigatórios: ${erros.join(', ')}', _error);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Criar NF-e'),
        content: const Text('Confirma a criação desta NF-e de Saída?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      // Campos alinhados ao contrato real de NfeCriacaoDTO (backend).
      // 'ambiente' segue enviado para compatibilidade futura, mas hoje o
      // DTO do backend não possui esse campo — não é persistido ainda
      // (gap de backend, fora do escopo desta tela Flutter).
      final body = <String, dynamic>{
        'numero': _numeroCtrl.text,
        'serie': _serieVal,
        'natOp': _topSelected!['natOp'],
        'indFinal': _topSelected!['indFinal'],
        'indPres': _topSelected!['indPres'],
        'ambiente': _ambienteVal,
        if (_empresaId != null) 'empresaId': int.tryParse(_empresaId!),
        if (_destinatarioId != null) 'destinatarioId': int.tryParse(_destinatarioId!),
        'nfeTipoOperacaoId': _topSelected!['id'] is int
            ? _topSelected!['id']
            : int.tryParse(_topSelected!['id'].toString()),
      };

      final result = await _service.criarNfe(body);
      if (!mounted) return;

      if (result != null && result['id'] != null) {
        final nfeId = result['id'] is int
            ? result['id'] as int
            : int.tryParse(result['id'].toString());
        var itensComFalha = 0;
        if (nfeId != null) {
          for (final item in _items) {
            final ok = await _service.criarItem(nfeId, item);
            if (!ok) itensComFalha++;
          }
        }

        if (!mounted) return;
        if (itensComFalha > 0) {
          _snack('NF-e criada, mas $itensComFalha item(ns) falharam ao salvar. Verifique antes de emitir.', _error);
        } else {
          _snack('NF-e criada com sucesso!', _success);
        }
        Navigator.pop(context, true);
      } else {
        _snack('Erro ao criar NF-e', _error);
      }
    } catch (e) {
      if (mounted) _snack('Erro ao processar. Tente novamente.', _error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      color: _cardBg,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _border)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: _primary)),
          const Divider(height: 20),
          ...children,
        ]),
      ),
    );
  }

  Widget _twoCol(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return Column(children: [left, const SizedBox(height: 12), right]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Nova NF-e Saída'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _saving ? null : _salvar,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(_saving ? 'Salvando...' : 'Salvar',
                  style: const TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                  backgroundColor: _success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6))),
            ),
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Tipo de Operação', [
                _twoCol(
                  SearchableDropdownField(
                    label: 'Tipo de Operação *',
                    value: _topSelected?['id']?.toString(),
                    items: _topList
                        .map((e) => {
                              'id': e['id']?.toString() ?? '',
                              'nome':
                                  '${e['codigo'] ?? ''} - ${e['descricao'] ?? ''}',
                            })
                        .toList(),
                    valueField: 'id',
                    displayField: 'nome',
                    onChanged: (v) {
                      final found = _topList
                          .where((e) => e['id'].toString() == v)
                          .firstOrNull;
                      _onTopSelected(found);
                    },
                    isRequired: true,
                    hintText: 'Selecione um TOP...',
                  ),
                  const SizedBox.shrink(),
                ),
                if (_topSelected != null) ...[
                  const SizedBox(height: 12),
                  _infoRow('Natureza da Operação',
                      _topSelected!['natOp']?.toString() ?? ''),
                  const SizedBox(height: 8),
                  _twoCol(
                    _infoRow('CFOP', _topSelected!['cfop']?.toString() ?? ''),
                    _infoRow('UF Origem → Destino',
                        '${_topSelected!['ufOrigem'] ?? ''} → ${_topSelected!['ufDestino'] ?? ''}'),
                  ),
                ],
              ]),
              _section('Dados da NF-e', [
                _twoCol(
                  SearchableDropdownField(
                    label: 'Empresa *',
                    value: _empresaId,
                    items: _empresas,
                    valueField: 'id',
                    displayField: 'nome',
                    enabled: false,
                    onChanged: (v) {},
                  ),
                  Column(children: [
                    DropdownButtonFormField<String>(
                      value: _ambienteVal,
                      decoration: const InputDecoration(
                          labelText: 'Ambiente', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: 'HOMOLOGACAO', child: Text('Homologação')),
                        DropdownMenuItem(
                            value: 'PRODUCAO', child: Text('Produção')),
                      ],
                      onChanged: (v) => setState(() => _ambienteVal = v),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _twoCol(
                  SearchableDropdownField(
                    label: 'Parceiro',
                    value: _parceiroId,
                    items: _parceiros,
                    valueField: 'id',
                    displayField: 'nome',
                    enabled: false,
                    onChanged: (v) {},
                  ),
                  SearchableDropdownField(
                    label: 'Destinatário',
                    value: _destinatarioId,
                    items: _destinatarios,
                    valueField: 'id',
                    displayField: 'nome',
                    onChanged: (v) => setState(() => _destinatarioId = v),
                    nullable: true,
                    hintText: 'Selecione o destinatário...',
                  ),
                ),
                const SizedBox(height: 16),
                _twoCol(
                  SearchableDropdownField(
                    label: 'Série *',
                    value: _validDropdownValue(
                        _serieVal, _series.map(_serieValue)),
                    items: _series
                        .map((s) => {
                              'id': _serieValue(s),
                              'nome': _serieLabel(s),
                            })
                        .toList(),
                    valueField: 'id',
                    displayField: 'nome',
                    onChanged: (v) => setState(() => _serieVal = v),
                    nullable: true,
                    hintText: 'Selecione a série...',
                  ),
                  TextField(
                    controller: _numeroCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Número', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
              _section('Configuração Fiscal', [
                _twoCol(
                  SearchableDropdownField(
                    label: 'Finalidade',
                    value: _finalidadeId,
                    items: _finalidades,
                    valueField: 'id',
                    displayField: 'descricao',
                    onChanged: (v) => setState(() => _finalidadeId = v),
                    nullable: true,
                    hintText: 'Selecione...',
                  ),
                  SearchableDropdownField(
                    label: 'Forma de Pagamento',
                    value: _formaPagId,
                    items: _formasPagamento,
                    valueField: 'id',
                    displayField: 'descricao',
                    onChanged: (v) => setState(() => _formaPagId = v),
                    nullable: true,
                    hintText: 'Selecione...',
                  ),
                ),
                if (_topSelected != null) ...[
                  const SizedBox(height: 16),
                  _twoCol(
                    _infoRow('Indicador Consumidor Final',
                        _topSelected!['indFinal'] == '1' ? 'Sim' : 'Não'),
                    _infoRow('Presença do Comprador',
                        _topSelected!['indPres']?.toString() ?? ''),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _taxBoxBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _taxBoxBorder),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Impostos (do TOP)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          _taxRow(
                              'ICMS',
                              'CST: ${_topSelected!['cstIcms'] ?? '-'}',
                              'Alíq: ${_topSelected!['aliqIcms'] ?? '-'}%'),
                          _taxRow(
                              'IPI',
                              'CST: ${_topSelected!['cstIpi'] ?? '-'}',
                              'Alíq: ${_topSelected!['aliqIpi'] ?? '-'}%'),
                          _taxRow(
                              'PIS',
                              'CST: ${_topSelected!['cstPis'] ?? '-'}',
                              'Alíq: ${_topSelected!['pPis'] ?? '-'}%'),
                          _taxRow(
                              'COFINS',
                              'CST: ${_topSelected!['cstCofins'] ?? '-'}',
                              'Alíq: ${_topSelected!['pCofins'] ?? '-'}%'),
                        ]),
                  ),
                ],
              ]),
              _section('Itens *', [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _adicionarItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Nenhum item adicionado. Clique em "Adicionar Item"'),
                    ),
                  )
                else
                  NfeItemsTable(
                    items: _items,
                    breakpoint: Breakpoint.desktop,
                    editable: true,
                    onEdit: _editarItem,
                    onDelete: _removerItem,
                  ),
              ]),
              _section('Resumo de Totais', [
                _totalRow('Subtotal', _totais.subtotal),
                _totalRow('ICMS', _totais.icms),
                _totalRow('PIS', _totais.pis),
                _totalRow('COFINS', _totais.cofins),
                const Divider(),
                _totalRow('TOTAL', _totais.total, isTotal: true),
              ]),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      side: const BorderSide(color: _border),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _salvar,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Salvando...' : 'Salvar NF-e'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: GridColors.textMuted)),
        ),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  /// Row de total formatado (compartilha o mesmo cálculo de
  /// [NfeTotaisCalculator] usado nas telas Mobile e Windows).
  Widget _totalRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? _success : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taxRow(String name, String cst, String aliq) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(
            width: 80,
            child: Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13))),
        const SizedBox(width: 16),
        Text(cst, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 24),
        Text(aliq, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}
