import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/services/nfe_saida_service.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/nfe_totais_calculator.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_item_form_dialog.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_items_table.dart';
import 'package:task_manager_flutter/widgets/nfe/responsive_scaffold.dart';
import 'package:task_manager_flutter/widgets/searchable_dropdown.dart';

/// Tela de criação/edição de NFe com layout responsivo
///
/// Layouts:
/// - Mobile (<600px): 1 coluna, campos apilados
/// - Tablet (600-1024px): 2 colunas (dados esquerda, itens direita)
/// - Desktop (≥1024px): 3 colunas (dados, itens expandíveis, resumo)
///
/// Card de unificação (2026-08-27): os campos e o payload de envio agora
/// seguem a MESMA estrutura de Web/Windows (nfe_saida_create_screen.dart) —
/// Parceiro/Destinatário separados (antes: campo único "Cliente"), Série
/// como dropdown de séries existentes (antes: texto livre auto-incremento),
/// Natureza da Operação derivada do TOP selecionado (antes: dropdown
/// independente), botão "Salvar NF-e" (antes: "Criar NFe"). O layout
/// responsivo em 3 breakpoints (ausente em Web/Windows) foi preservado.
class NfeFormScreen extends StatefulWidget {
  const NfeFormScreen({super.key});

  @override
  State<NfeFormScreen> createState() => _NfeFormScreenState();
}

class _NfeFormScreenState extends State<NfeFormScreen> {
  final _nfeSaidaService = NfeSaidaService();

  late GlobalKey<FormState> _formKey;
  late TextEditingController _observacoesController;
  late TextEditingController _numeroController;

  // Estado local dos itens
  final List<NfeItemModel> _items = [];

  // Totais calculados a partir dos itens (ver NfeTotaisCalculator)
  NfeTotais _totais = NfeTotais.zero;

  // Estados
  bool _isSubmitting = false;
  String? _validationError;

  // Empresa/Parceiro do usuário logado (somente leitura) — mesma fonte de
  // dados usada em Web/Windows (AuthUtility.userInfo?.login).
  String? _empresaId;
  String? _parceiroId;

  // Destinatário selecionado — mesma semântica de Web/Windows: campo
  // separado do parceiro do próprio usuário, obrigatório.
  String? _destinatarioId;
  List<Map<String, dynamic>> _parceiros = [];
  List<Map<String, dynamic>> _destinatarios = [];

  // Tipo de Operação (TOP) — mesma fonte usada em Web/Windows
  List<Map<String, dynamic>> _topList = [];
  Map<String, dynamic>? _topSelecionado;

  // Série — dropdown de séries já cadastradas para a empresa (antes: texto
  // livre com auto-incremento, divergente de Web/Windows).
  List<Map<String, dynamic>> _series = [];
  String? _serieVal;

  // Ambiente de emissão — default seguro: Homologação
  String _ambienteSelecionado = 'HOMOLOGACAO';

  // Finalidade e forma de pagamento
  List<Map<String, dynamic>> _finalidades = [];
  String? _finalidadeSelecionada;
  List<Map<String, dynamic>> _formasPagamento = [];
  String? _formaPagamentoSelecionada;

  bool _loadingDados = true;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _observacoesController = TextEditingController();
    _numeroController = TextEditingController();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final login = AuthUtility.userInfo?.login;
    final empId = login?.empresa?.id?.toString();
    final parcId = login?.parceiro?.id?.toString();
    _empresaId = empId;
    _parceiroId = parcId;

    try {
      final results = await Future.wait([
        TenantContext.get(
            '${ApiLinks.baseUrl}/api/parceiro?tamanho=500${empId != null ? '&empId=$empId' : ''}'),
        TenantContext.get('${ApiLinks.baseUrl}/api/nfe-finalidade?tamanho=50'),
        TenantContext.get('${ApiLinks.baseUrl}/api/forma_pagamento?tamanho=100'),
        TenantContext.get(
            '${ApiLinks.baseUrl}/api/nfe-serie?tamanho=100${empId != null ? '&empId=$empId' : ''}'),
      ]);
      final tops = await _nfeSaidaService.carregarTiposOperacao();
      if (!mounted) return;
      final parceiros = _parseList(results[0].body);
      final finalidades = _parseList(results[1].body);
      final formasPagamento = _parseList(results[2].body);
      final series = _dedupeByValue(_parseList(results[3].body), _serieValue);
      final currentSerie = _validDropdownValue(_serieVal, series.map(_serieValue));
      setState(() {
        _parceiros = parceiros;
        _destinatarios = parceiros;
        _topList = tops;
        _finalidades = finalidades;
        _formasPagamento = formasPagamento;
        _series = series;
        _serieVal = currentSerie;
        _loadingDados = false;
      });
    } catch (e) {
      debugPrint('[NfeFormScreen] Erro ao carregar dados: $e');
      if (mounted) setState(() => _loadingDados = false);
    }
  }

  List<Map<String, dynamic>> _parseList(String body) {
    final b = jsonDecode(body);
    if (b is List) return b.cast<Map<String, dynamic>>();
    if (b is Map && b['data'] is List) return (b['data'] as List).cast<Map<String, dynamic>>();
    if (b is Map && b['content'] is List) return (b['content'] as List).cast<Map<String, dynamic>>();
    return [];
  }

  /// Série: mesma extração usada em Web/Windows (campo 'serie'/'numero'/'id').
  String _serieValue(Map<String, dynamic> serie) =>
      (serie['serie'] ?? serie['numero'] ?? serie['id'] ?? '').toString();

  String _serieLabel(Map<String, dynamic> serie) {
    final numero = (serie['serie'] ?? serie['numero'])?.toString();
    final descricao = serie['descricao']?.toString();
    if (numero != null && numero.isNotEmpty) {
      return descricao != null && descricao.isNotEmpty ? '$numero - $descricao' : numero;
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
    return itemValues.where((itemValue) => itemValue == value).length == 1 ? value : null;
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  /// Recalcula totais com base nos itens
  void _recalcularTotais() {
    setState(() {
      _totais = NfeTotaisCalculator.calcular(_items);
    });
  }

  /// Abre o dialog para adicionar um novo item
  Future<void> _adicionarItem() async {
    final item = await NfeItemFormDialog.show(
      context,
      proximoSequencial: _items.length + 1,
    );
    if (item == null) return;
    setState(() => _items.add(item));
    _recalcularTotais();
  }

  /// Remove item pelo índice
  void _removerItem(int index) {
    if (index >= 0 && index < _items.length) {
      setState(() {
        _items.removeAt(index);
      });
      _recalcularTotais();
    }
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
    setState(() => _items[index] = item);
    _recalcularTotais();
  }

  /// Submete o formulário
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios corretamente')),
      );
      return;
    }

    final erros = <String>[];
    if (_topSelecionado == null) erros.add('Tipo de Operação');
    if (_destinatarioId == null || _destinatarioId!.isEmpty) erros.add('Destinatário');
    if (_serieVal == null || _serieVal!.isEmpty) erros.add('Série');
    if (_items.isEmpty) erros.add('Itens (adicione ao menos 1)');
    if (erros.isNotEmpty) {
      setState(() => _validationError = 'Campos obrigatórios: ${erros.join(', ')}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Campos obrigatórios: ${erros.join(', ')}')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationError = null;
    });

    try {
      // Payload alinhado ao contrato real de NfeCriacaoDTO (backend) — mesmos
      // campos enviados por Web/Windows (nfe_saida_create_screen.dart).
      final dados = <String, dynamic>{
        'numero': _numeroController.text,
        'serie': _serieVal,
        'natOp': _topSelecionado!['natOp'],
        'indFinal': _topSelecionado!['indFinal'],
        'indPres': _topSelecionado!['indPres'],
        'ambiente': _ambienteSelecionado,
        if (_empresaId != null) 'empresaId': int.tryParse(_empresaId!),
        if (_destinatarioId != null) 'destinatarioId': int.tryParse(_destinatarioId!),
        'nfeTipoOperacaoId': _topSelecionado!['id'] is int
            ? _topSelecionado!['id']
            : int.tryParse(_topSelecionado!['id'].toString()),
        if (_observacoesController.text.isNotEmpty) 'observacoes': _observacoesController.text,
        if (_finalidadeSelecionada != null) 'finalidade': _finalidadeSelecionada,
        if (_formaPagamentoSelecionada != null) 'formaPagamentoId': _formaPagamentoSelecionada,
      };

      debugPrint('[NfeFormScreen] Enviando cabeçalho: $dados');

      // Chama notifier para criar o cabeçalho da NFe
      final nfeNotifier = context.read<NfeNotifier>();
      final nfeCriada = await nfeNotifier.criarNfe(dados);

      // Persiste cada item separadamente (endpoint de criação da NFe não
      // aceita itens embutidos — ver NfeSaidaService.criarItem)
      var itensComFalha = 0;
      for (final item in _items) {
        final ok = await _nfeSaidaService.criarItem(nfeCriada.id, item);
        if (!ok) itensComFalha++;
      }

      if (mounted) {
        if (itensComFalha > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'NFe #${nfeCriada.numero} criada, mas $itensComFalha item(ns) falharam ao salvar. Verifique antes de emitir.',
              ),
              backgroundColor: DesignTokens.warning,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('NFe #${nfeCriada.numero} criada com sucesso!'),
              backgroundColor: DesignTokens.success,
            ),
          );
        }

        // Navega para detail screen
        Navigator.of(context).pushReplacementNamed(
          '/nfe/detail',
          arguments: nfeCriada.id,
        );
      }
    } catch (e) {
      debugPrint('[NfeFormScreen] Erro ao criar NFe: $e');
      if (mounted) {
        setState(() => _validationError = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar NFe: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Retorna widget baseado no breakpoint
  Widget _buildForm(Breakpoint breakpoint) {
    return switch (breakpoint) {
      Breakpoint.mobile => _buildMobileLayout(),
      Breakpoint.tablet => _buildTabletLayout(),
      Breakpoint.desktop => _buildDesktopLayout(),
    };
  }

  /// Layout mobile (1 coluna)
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingSm),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildParceiroDestinatarioSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildSerieSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildConfigFiscalSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildObservacoesSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildItemsSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildTotaisSection(),
              const SizedBox(height: DesignTokens.spacingLg),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Layout tablet (2 colunas)
  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna esquerda: dados gerais
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildParceiroDestinatarioSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildSerieSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildConfigFiscalSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildObservacoesSection(),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spacingMd),
              // Coluna direita: itens
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItemsSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildTotaisSection(),
                    const SizedBox(height: DesignTokens.spacingLg),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Layout desktop (3 colunas)
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coluna 1: Dados gerais
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildParceiroDestinatarioSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildSerieSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildConfigFiscalSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildObservacoesSection(),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spacingLg),
              // Coluna 2: Itens expandíveis
              Expanded(
                flex: 2,
                child: _buildItemsSection(),
              ),
              const SizedBox(width: DesignTokens.spacingLg),
              // Coluna 3: Resumo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotaisSection(),
                    const SizedBox(height: DesignTokens.spacingLg),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Seção de Parceiro (somente leitura, do usuário logado) e Destinatário
  /// (selecionável, obrigatório) — mesma semântica de Web/Windows. Antes:
  /// campo único "Cliente" com modelo próprio (NfeTomadorModel).
  Widget _buildParceiroDestinatarioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parceiro / Destinatário',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SearchableDropdownField(
          label: 'Parceiro',
          value: _parceiroId,
          items: _parceiros,
          valueField: 'id',
          displayField: 'nome',
          enabled: false,
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
        SearchableDropdownField(
          label: 'Destinatário',
          value: _destinatarioId,
          items: _destinatarios,
          valueField: 'id',
          displayField: 'nome',
          onChanged: (v) => setState(() => _destinatarioId = v),
          nullable: true,
          isRequired: true,
          hintText: 'Selecione o destinatário...',
        ),
      ],
    );
  }

  /// Seção de Tipo de Operação (TOP), Empresa (somente leitura), Ambiente e
  /// Natureza da Operação (derivada do TOP, somente leitura — mesma
  /// semântica de Web/Windows; antes era um dropdown independente no Mobile).
  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Operação (TOP) *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _topSelecionado,
          isExpanded: true,
          hint: const Text('Selecione um TOP'),
          items: _topList.map((top) {
            return DropdownMenuItem(
              value: top,
              child: Text(
                '${top['codigo'] ?? ''} - ${top['descricao'] ?? ''}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (top) => setState(() => _topSelecionado = top),
          validator: (value) => value == null ? 'TOP obrigatório' : null,
          decoration: InputDecoration(
            hintText: 'Selecione um TOP',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        if (_topSelecionado != null) ...[
          const SizedBox(height: 12),
          Text(
            'Natureza da Operação: ${_topSelecionado!['natOp'] ?? ''}',
            style: const TextStyle(fontSize: 13, color: DesignTokens.textSecondary),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          initialValue: AuthUtility.userInfo?.login?.empresa?.nome ?? '',
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Empresa',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _ambienteSelecionado,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Ambiente',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(value: 'HOMOLOGACAO', child: Text('Homologação')),
            DropdownMenuItem(value: 'PRODUCAO', child: Text('Produção')),
          ],
          onChanged: (v) => setState(() => _ambienteSelecionado = v ?? 'HOMOLOGACAO'),
        ),
      ],
    );
  }

  /// Seção de Finalidade e Forma de Pagamento (Config. Fiscal).
  Widget _buildConfigFiscalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuração Fiscal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _finalidadeSelecionada,
          isExpanded: true,
          hint: const Text('Selecione a finalidade'),
          items: _finalidades.map((f) {
            final id = f['id']?.toString() ?? '';
            return DropdownMenuItem(
              value: id,
              child: Text(f['descricao']?.toString() ?? id, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) => setState(() => _finalidadeSelecionada = v),
          decoration: InputDecoration(
            labelText: 'Finalidade',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _formaPagamentoSelecionada,
          isExpanded: true,
          hint: const Text('Selecione a forma de pagamento'),
          items: _formasPagamento.map((f) {
            final id = f['id']?.toString() ?? '';
            return DropdownMenuItem(
              value: id,
              child: Text(f['descricao']?.toString() ?? id, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) => setState(() => _formaPagamentoSelecionada = v),
          decoration: InputDecoration(
            labelText: 'Forma de Pagamento',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Seção de série (dropdown de séries existentes) e número — mesma
  /// semântica de Web/Windows. Antes: campo de texto livre auto-incremento.
  Widget _buildSerieSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Série *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SearchableDropdownField(
          label: 'Série *',
          value: _validDropdownValue(_serieVal, _series.map(_serieValue)),
          items: _series.map((s) => {'id': _serieValue(s), 'nome': _serieLabel(s)}).toList(),
          valueField: 'id',
          displayField: 'nome',
          onChanged: (v) => setState(() => _serieVal = v),
          nullable: true,
          hintText: 'Selecione a série...',
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _numeroController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Número',
            helperText: 'Deixe em branco para auto-incrementar',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Seção de observações
  Widget _buildObservacoesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observações',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _observacoesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Adicione observações se necessário',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Seção de itens (tabela/cards)
  Widget _buildItemsSection() {
    final width = MediaQuery.of(context).size.width;
    final breakpoint = width < 600
        ? Breakpoint.mobile
        : width < 1024
            ? Breakpoint.tablet
            : Breakpoint.desktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Achado durante o card de unificação mobile (X6onSLzo, replicado
        // para merged_final): Row com spaceBetween e sem Expanded/Wrap não
        // encolhe o botão em telas realmente estreitas (<400px) --
        // "Itens *" + "Adicionar Item" ultrapassa a largura disponível e
        // gera RenderFlex overflow (confirmado via widget test em
        // merged_final). Wrap deixa o botão cair pra linha de baixo nesse
        // caso, sem afetar telas maiores.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const Text(
              'Itens *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              onPressed: _adicionarItem,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Item'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: DesignTokens.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Nenhum item adicionado. Clique em "Adicionar Item"'),
            ),
          )
        else
          NfeItemsTable(
            items: _items,
            breakpoint: breakpoint,
            editable: true,
            onEdit: (index) => _editarItem(index),
            onDelete: _removerItem,
          ),
      ],
    );
  }

  /// Seção de totais (read-only)
  Widget _buildTotaisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: DesignTokens.divider),
        borderRadius: BorderRadius.circular(8),
        color: DesignTokens.surfaceMuted,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo de Totais',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DesignTokens.textSecondary),
          ),
          const Divider(color: DesignTokens.divider),
          _buildTotalRow('Subtotal', _totais.subtotal),
          _buildTotalRow('ICMS', _totais.icms),
          _buildTotalRow('PIS', _totais.pis),
          _buildTotalRow('COFINS', _totais.cofins),
          _buildTotalRow('Desconto', -_totais.desconto, isDiscount: true),
          const Divider(color: DesignTokens.divider),
          _buildTotalRow('TOTAL', _totais.total, isTotal: true),
        ],
      ),
    );
  }

  /// Row de total formatado
  Widget _buildTotalRow(String label, double value, {bool isDiscount = false, bool isTotal = false}) {
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
              color: DesignTokens.textSecondary,
            ),
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount || isTotal ? DesignTokens.success : DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Botão de submissão — rótulo unificado com Web/Windows ("Salvar NF-e",
  /// antes "Criar NFe").
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primary,
          disabledBackgroundColor: DesignTokens.textMuted,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.textPrimary),
                ),
              )
            : const Text(
                'Salvar NF-e',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: DesignTokens.textPrimary),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final breakpoint = width < 600
        ? Breakpoint.mobile
        : width < 1024
            ? Breakpoint.tablet
            : Breakpoint.desktop;

    return ResponsiveScaffold(
      title: 'Nova Nota Fiscal Eletrônica',
      breakpoint: breakpoint,
      body: _loadingDados
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(breakpoint),
    );
  }
}
