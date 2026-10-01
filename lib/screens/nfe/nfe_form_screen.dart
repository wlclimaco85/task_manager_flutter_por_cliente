import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/services/nfe_saida_service.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/nfe_totais_calculator.dart';
import 'package:task_manager_flutter/utils/tenant_context.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_item_form_dialog.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_items_table.dart';
import 'package:task_manager_flutter/widgets/nfe/responsive_scaffold.dart';


/// Tela de criação/edição de NFe com layout responsivo
///
/// Layouts:
/// - Mobile (<600px): 1 coluna, campos apilados
/// - Tablet (600-1024px): 2 colunas (cliente esquerda, itens direita)
/// - Desktop (≥1024px): 3 colunas (dados, itens expandíveis, resumo)
class NfeFormScreen extends StatefulWidget {
  const NfeFormScreen({super.key});

  @override
  State<NfeFormScreen> createState() => _NfeFormScreenState();
}

class _NfeFormScreenState extends State<NfeFormScreen> {
  final _nfeSaidaService = NfeSaidaService();

  late GlobalKey<FormState> _formKey;
  late TextEditingController _clienteCnpjController;
  late TextEditingController _clienteRazaoSocialController;
  late TextEditingController _naturezaController;
  late TextEditingController _observacoesController;
  late TextEditingController _serieController;

  // Estado local dos itens
  final List<NfeItemModel> _items = [];

  // Totais calculados a partir dos itens (ver NfeTotaisCalculator)
  NfeTotais _totais = NfeTotais.zero;

  // Estados
  bool _isSubmitting = false;
  String? _validationError;

  // Cliente selecionado
  NfeTomadorModel? _clienteSelecionado;

  // Natureza selecionada
  String? _naturezaSelecionada;

  List<NfeTomadorModel> _clientes = [];
  List<String> _naturezas = [];
  bool _loadingDados = true;

  // Tipo de Operação (TOP) — mesma fonte usada em Web/Windows
  List<Map<String, dynamic>> _topList = [];
  Map<String, dynamic>? _topSelecionado;

  // Empresa (somente leitura, vem do usuário logado)
  String? _empresaNome;

  // Ambiente de emissão — default seguro: Homologação
  String _ambienteSelecionado = 'HOMOLOGACAO';

  // Finalidade e forma de pagamento
  List<Map<String, dynamic>> _finalidades = [];
  String? _finalidadeSelecionada;
  List<Map<String, dynamic>> _formasPagamento = [];
  String? _formaPagamentoSelecionada;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _clienteCnpjController = TextEditingController();
    _clienteRazaoSocialController = TextEditingController();
    _naturezaController = TextEditingController();
    _observacoesController = TextEditingController();
    _serieController = TextEditingController(text: '1');
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    _empresaNome = AuthUtility.userInfo?.login?.empresa?.nome;

    try {
      final results = await Future.wait([
        TenantContext.get('${ApiLinks.baseUrl}/api/parceiro?tamanho=500'),
        TenantContext.get('${ApiLinks.baseUrl}/api/nfe-tipo-operacao?tamanho=50'),
        TenantContext.get('${ApiLinks.baseUrl}/api/nfe-finalidade?tamanho=50'),
        TenantContext.get('${ApiLinks.baseUrl}/api/forma_pagamento?tamanho=100'),
      ]);
      final tops = await _nfeSaidaService.carregarTiposOperacao();
      if (!mounted) return;
      final parceiros = _parseList(results[0].body);
      final tipos = _parseList(results[1].body);
      final finalidades = _parseList(results[2].body);
      final formasPagamento = _parseList(results[3].body);
      setState(() {
        _clientes = parceiros.map((p) => NfeTomadorModel(
          cnpjCpf: p['cnpj']?.toString() ?? p['cpf']?.toString() ?? '',
          razaoSocial: p['nome']?.toString() ?? p['razaoSocial']?.toString() ?? '',
          endereco: p['endereco']?.toString() ?? '',
          numero: p['numero']?.toString() ?? '',
          bairro: p['bairro']?.toString() ?? '',
          cep: p['cep']?.toString() ?? '',
          uf: p['uf']?.toString() ?? '',
          municipio: p['municipio']?.toString() ?? '',
          email: p['email']?.toString() ?? '',
          telefone: p['telefone']?.toString() ?? '',
        )).toList();
        _naturezas = tipos.map((t) => t['descricao']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
        if (_naturezas.isEmpty) _naturezas = ['Venda', 'Devolução', 'Transferência', 'Serviço'];
        _topList = tops;
        _finalidades = finalidades;
        _formasPagamento = formasPagamento;
        _loadingDados = false;
      });
    } catch (e) {
      debugPrint('[NfeFormScreen] Erro ao carregar dados: $e');
      if (mounted) setState(() {
        _naturezas = ['Venda', 'Devolução', 'Transferência', 'Serviço'];
        _loadingDados = false;
      });
    }
  }

  List<Map<String, dynamic>> _parseList(String body) {
    final b = jsonDecode(body);
    if (b is List) return b.cast<Map<String, dynamic>>();
    if (b is Map && b['data'] is List) return (b['data'] as List).cast<Map<String, dynamic>>();
    if (b is Map && b['content'] is List) return (b['content'] as List).cast<Map<String, dynamic>>();
    return [];
  }

  @override
  void dispose() {
    _clienteCnpjController.dispose();
    _clienteRazaoSocialController.dispose();
    _naturezaController.dispose();
    _observacoesController.dispose();
    _serieController.dispose();
    super.dispose();
  }

  /// Valida CNPJ/CPF formato básico
  bool _validarCnpjCpf(String cnpjCpf) {
    final clean = cnpjCpf.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      // CPF: validação básica (length)
      return clean.length == 11;
    } else if (clean.length == 14) {
      // CNPJ: validação básica (length) + mod 11
      return _validarCnpjMod11(clean);
    }
    return false;
  }

  /// Algoritmo de validação CNPJ Mod 11
  bool _validarCnpjMod11(String cnpj) {
    if (cnpj.length != 14) return false;

    // Primeiro dígito verificador
    int sum = 0;
    int multiplier = 5;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * multiplier;
      multiplier = multiplier == 2 ? 9 : multiplier - 1;
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;

    // Segundo dígito verificador
    sum = 0;
    multiplier = 6;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * multiplier;
      multiplier = multiplier == 2 ? 9 : multiplier - 1;
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;

    return digit1 == int.parse(cnpj[12]) && digit2 == int.parse(cnpj[13]);
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

  /// Seleciona cliente
  void _selecionarCliente(NfeTomadorModel cliente) {
    setState(() {
      _clienteSelecionado = cliente;
      _clienteCnpjController.text = cliente.cnpjCpfFormatado;
      _clienteRazaoSocialController.text = cliente.razaoSocial;
    });
  }

  /// Submete o formulário
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios corretamente')),
      );
      return;
    }

    if (_clienteSelecionado == null) {
      setState(() => _validationError = 'Selecione um cliente');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente')),
      );
      return;
    }

    if (_items.isEmpty) {
      setState(() => _validationError = 'Adicione pelo menos 1 item');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos 1 item')),
      );
      return;
    }

    if (_naturezaSelecionada == null || _naturezaSelecionada!.isEmpty) {
      setState(() => _validationError = 'Selecione a natureza da operação');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a natureza da operação')),
      );
      return;
    }

    if (_topSelecionado == null) {
      setState(() => _validationError = 'Selecione o Tipo de Operação (TOP)');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o Tipo de Operação (TOP)')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationError = null;
    });

    try {
      // Prepara dados do cabeçalho da NFe (compatível com NfeCriacaoDTO —
      // itens NÃO fazem parte deste payload, ver loop de criação abaixo)
      final dados = {
        'tomadorCnpjCpf': _clienteSelecionado!.cnpjCpf,
        'naturezaOperacao': _naturezaSelecionada,
        'natOp': _topSelecionado!['natOp']?.toString(),
        'serie': int.tryParse(_serieController.text) ?? 1,
        'observacoes': _observacoesController.text.isNotEmpty ? _observacoesController.text : null,
        'ambiente': _ambienteSelecionado,
        'nfeTipoOperacaoId': _topSelecionado!['id'],
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
              _buildClienteSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildTopSection(),
              const SizedBox(height: DesignTokens.spacingMd),
              _buildNaturezaSection(),
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
                    _buildClienteSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildTopSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildNaturezaSection(),
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
                    _buildClienteSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildTopSection(),
                    const SizedBox(height: DesignTokens.spacingMd),
                    _buildNaturezaSection(),
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

  /// Seção de seleção de cliente
  Widget _buildClienteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cliente *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // Dropdown de clientes
        DropdownButtonFormField<NfeTomadorModel>(
          value: _clienteSelecionado,
          hint: const Text('Selecione um cliente'),
          items: _clientes.map((cliente) {
            return DropdownMenuItem(
              value: cliente,
              child: Text('${cliente.razaoSocial} (${cliente.cnpjCpfFormatado})'),
            );
          }).toList(),
          onChanged: (cliente) {
            if (cliente != null) {
              _selecionarCliente(cliente);
            }
          },
          validator: (value) => value == null ? 'Cliente obrigatório' : null,
          decoration: InputDecoration(
            hintText: 'Selecione um cliente',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        // CNPJ/CPF do cliente
        TextFormField(
          controller: _clienteCnpjController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'CNPJ/CPF',
            hintText: '00.000.000/0000-00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        // Razão social
        TextFormField(
          controller: _clienteRazaoSocialController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Razão Social',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Seção de Tipo de Operação (TOP), Empresa (somente leitura) e Ambiente.
  ///
  /// Equivalente ao que já existe em Web/Windows — antes ausente no Mobile.
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
          hint: const Text('Selecione um TOP'),
          items: _topList.map((top) {
            return DropdownMenuItem(
              value: top,
              child: Text('${top['codigo'] ?? ''} - ${top['descricao'] ?? ''}'),
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
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _empresaNome ?? '',
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
  ///
  /// Equivalente ao que já existe em Web/Windows — antes ausente no Mobile.
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
          hint: const Text('Selecione a finalidade'),
          items: _finalidades.map((f) {
            final id = f['id']?.toString() ?? '';
            return DropdownMenuItem(value: id, child: Text(f['descricao']?.toString() ?? id));
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
          hint: const Text('Selecione a forma de pagamento'),
          items: _formasPagamento.map((f) {
            final id = f['id']?.toString() ?? '';
            return DropdownMenuItem(value: id, child: Text(f['descricao']?.toString() ?? id));
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

  /// Seção de natureza da operação
  Widget _buildNaturezaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Natureza da Operação *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _naturezaSelecionada,
          hint: const Text('Selecione a natureza'),
          items: _naturezas.map((natureza) {
            return DropdownMenuItem(value: natureza, child: Text(natureza));
          }).toList(),
          onChanged: (natureza) {
            setState(() => _naturezaSelecionada = natureza);
          },
          validator: (value) => value == null ? 'Natureza obrigatória' : null,
          decoration: InputDecoration(
            hintText: 'Selecione a natureza',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Seção de série
  Widget _buildSerieSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Série',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _serieController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  /// Botão de submissão
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
                'Criar NFe',
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
