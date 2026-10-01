import 'package:flutter/material.dart';
import '../../services/conta_bancaria_caller.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import 'financial_lookup_loader.dart';

/// Resultado escolhido pelo usuário ao confirmar a geração de Contas a Pagar
/// a partir de uma NF-e de entrada. Ambos os campos são opcionais — o
/// backend aceita categoriaFinanceiraId/contaBancariaId nulos e mantém o
/// comportamento anterior (lançamentos sem categoria/conta pré-definida).
class GerarContasPagarResultado {
  final int? categoriaFinanceiraId;
  final int? contaBancariaId;

  const GerarContasPagarResultado({
    this.categoriaFinanceiraId,
    this.contaBancariaId,
  });
}

typedef _CategoriasLoader = Future<List<Map<String, dynamic>>> Function();
typedef _ContasLoader = Future<List<Map<String, dynamic>>> Function();

/// Dialog exibido antes de gerar Contas a Pagar a partir das duplicatas de
/// uma NF-e de entrada. Deixa Categoria Financeira e Conta Bancária como
/// seleção opcional (nenhuma é obrigatória), reaproveitando os mesmos
/// carregadores/estilo já usados em [BaixaDialog] e no cadastro de
/// ContaPagar, em vez de inventar um novo padrão visual.
class GerarContasPagarDialog extends StatefulWidget {
  final int nfeId;
  final int quantidadeDuplicatas;

  // Injeção por function typedef (testabilidade) — em produção usa os
  // carregadores reais; testes podem substituir por fakes sem rede.
  final _CategoriasLoader _loadCategorias;
  final _ContasLoader _loadContas;

  const GerarContasPagarDialog({
    super.key,
    required this.nfeId,
    required this.quantidadeDuplicatas,
  })  : _loadCategorias = FinancialLookupLoader.loadCategoriasFinanceiras,
        _loadContas = ContaBancariaCaller.loadContas;

  @visibleForTesting
  const GerarContasPagarDialog.testavel({
    super.key,
    required this.nfeId,
    required this.quantidadeDuplicatas,
    required _CategoriasLoader loadCategorias,
    required _ContasLoader loadContas,
  })  : _loadCategorias = loadCategorias,
        _loadContas = loadContas;

  @override
  State<GerarContasPagarDialog> createState() => _GerarContasPagarDialogState();
}

class _GerarContasPagarDialogState extends State<GerarContasPagarDialog> {
  bool _carregando = true;
  bool _erroAoCarregar = false;
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _contas = [];
  int? _categoriaFinanceiraId;
  int? _contaBancariaId;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final categorias = await widget._loadCategorias();
      final contas = await widget._loadContas();
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _contas = contas;
        _carregando = false;
      });
    } catch (e) {
      // Categoria/Conta sao opcionais: se a lista nao carregar (rede,
      // timeout, erro do backend), o usuario ainda pode gerar as Contas a
      // Pagar sem elas, em vez de ficar preso no spinner para sempre.
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erroAoCarregar = true;
      });
    }
  }

  InputDecoration _decoracao(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone, size: 20),
      prefixIconColor: GridColors.primary,
      floatingLabelStyle: const TextStyle(color: GridColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GridColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GridColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: GridColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerar Contas a Pagar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 380,
        child: _carregando
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirma a geração de Contas a Pagar para a NF-e #${widget.nfeId}?\n'
                    'Serão criadas ${widget.quantidadeDuplicatas} conta(s) baseadas nas duplicatas.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (_erroAoCarregar) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Não foi possível carregar categorias/contas bancárias agora. '
                      'Você ainda pode gerar as contas sem essa classificação.',
                      style: TextStyle(fontSize: 12, color: GridColors.primary),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _categoriaFinanceiraId,
                    decoration: _decoracao('Categoria Financeira (opcional)', Icons.category),
                    isExpanded: true,
                    items: _categorias
                        .map<DropdownMenuItem<int>>(
                          (c) => DropdownMenuItem<int>(
                            value: int.tryParse(c['value'].toString()),
                            child: Text(c['label'].toString(), overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _categoriaFinanceiraId = v),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _contaBancariaId,
                    decoration: _decoracao('Conta Bancária (opcional)', Icons.account_balance),
                    isExpanded: true,
                    items: _contas
                        .map<DropdownMenuItem<int>>(
                          (c) => DropdownMenuItem<int>(
                            value: c['value'] is int ? c['value'] as int : int.tryParse(c['value'].toString()),
                            child: Text(c['label'].toString(), overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _contaBancariaId = v),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.secondary, foregroundColor: Colors.white),
          onPressed: _carregando
              ? null
              : () => Navigator.pop(
                    context,
                    GerarContasPagarResultado(
                      categoriaFinanceiraId: _categoriaFinanceiraId,
                      contaBancariaId: _contaBancariaId,
                    ),
                  ),
          child: const Text('Gerar'),
        ),
      ],
    );
  }
}
