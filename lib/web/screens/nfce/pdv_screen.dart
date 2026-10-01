import 'dart:async';

import 'package:flutter/material.dart';
import '../../../utils/grid_colors.dart';
import 'package:flutter/services.dart';

import '../../../models/nfce/item_venda_model.dart';
import '../../../services/nfce_provider.dart';
import '../../../services/nfce_service.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/nfce/nfce_notice_banner.dart';
import 'config_fiscal_screen.dart';
import 'nfce_finalizacao_screen.dart';

/// Tela principal de venda / PDV NFC-e.
/// Funciona em web, windows e mobile (layout responsivo).
class PdvScreen extends StatefulWidget {
  const PdvScreen({super.key});

  @override
  State<PdvScreen> createState() => _PdvScreenState();
}

class _PdvScreenState extends State<PdvScreen> {
  final NfceProvider _provider = NfceProvider();
  final NfceService _service = NfceService();

  final TextEditingController _buscaCtrl = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _resultadosBusca = [];
  bool _buscando = false;

  final TextEditingController _clienteCtrl = TextEditingController();
  String? _erroCliente;

  String _formaPagamentoSelecionada = 'DINHEIRO';
  final TextEditingController _valorPagtoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider.addListener(() {
      if (mounted) setState(() {});
    });
    _buscaCtrl.addListener(_onBuscaChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaCtrl.dispose();
    _clienteCtrl.dispose();
    _valorPagtoCtrl.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _onBuscaChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _buscarProdutos);
  }

  Future<void> _buscarProdutos() async {
    final q = _buscaCtrl.text.trim();
    if (q.length < 2) {
      setState(() => _resultadosBusca = []);
      return;
    }
    final empresaId = TenantContext.empresaId ?? 0;
    setState(() => _buscando = true);
    try {
      final res = await _service.buscarProdutos(query: q, empresaId: empresaId);
      if (mounted) setState(() => _resultadosBusca = res);
    } catch (_) {
      if (mounted) setState(() => _resultadosBusca = []);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  bool _validarCpfCnpj(String valor) {
    final digits = valor.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 || digits.length == 14 || digits.isEmpty;
  }

  void _adicionarPagamento() {
    final valor = double.tryParse(_valorPagtoCtrl.text.replaceAll(',', '.')) ?? 0;
    if (valor <= 0) return;
    _provider.adicionarPagamento(_formaPagamentoSelecionada, valor);
    _valorPagtoCtrl.clear();
  }

  Future<void> _emitirNfce() async {
    final cpfCnpj = _clienteCtrl.text.trim();
    if (cpfCnpj.isNotEmpty && !_validarCpfCnpj(cpfCnpj)) {
      setState(() => _erroCliente = 'CPF/CNPJ inválido');
      return;
    }
    setState(() => _erroCliente = null);
    _provider.clienteCpfCnpj = cpfCnpj.isEmpty ? null : cpfCnpj;

    if (_provider.carrinho.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um produto ao carrinho.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NfceFinalizacaoScreen(provider: _provider),
      ),
    );
  }

  Widget _buildNoticeBanner() {
    final empresaId = TenantContext.empresaId;
    final isConfigured = empresaId != null;
    final backgroundColor = isConfigured ? const Color(0xFFEAF4FF) : const Color(0xFFFFF3CD);
    final borderColor = isConfigured ? const Color(0xFFB6D4FE) : const Color(0xFFFFD54F);
    final textColor = isConfigured ? const Color(0xFF0B5CAD) : const Color(0xFF7A4B00);
    final title = isConfigured ? 'Configuração NFC-e' : 'Configuração fiscal pendente';
    final message = isConfigured
        ? 'Confirme UF, ambiente, CSC, certificado e saúde da SEFAZ na configuração fiscal antes de emitir. Cancelamento e inutilização já fazem parte do fluxo fiscal atual.'
        : 'Nenhuma empresa foi identificada para este usuário. Verifique o vínculo da conta e configure a NFC-e antes de emitir.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: NfceNoticeBanner(
        icon: isConfigured ? Icons.info_outline : Icons.warning_amber_rounded,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        textColor: textColor,
        title: title,
        message: message,
        trailing: TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfigFiscalScreen()),
            );
          },
          style: TextButton.styleFrom(foregroundColor: textColor),
          child: const Text('Abrir configuração'),
        ),
      ),
    );
  }

  Widget _buildResumoFiscalCard() {
    final faltando = _provider.total - _provider.totalPago;
    final pagamentosValidos = _provider.pagamentos.isNotEmpty && faltando <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pronto para os eventos fiscais',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: GridColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatusChip(
                    label: _provider.carrinho.isEmpty ? 'Sem itens' : '${_provider.carrinho.length} item(ns)',
                    color: _provider.carrinho.isEmpty ? Colors.orange : Colors.green,
                  ),
                  _StatusChip(
                    label: pagamentosValidos ? 'Pagamento coberto' : 'Pagamento pendente',
                    color: pagamentosValidos ? Colors.green : Colors.orange,
                  ),
                  _StatusChip(
                    label: _clienteCtrl.text.trim().isEmpty ? 'Consumidor não identificado' : 'CPF/CNPJ informado',
                    color: Colors.blueGrey,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                pagamentosValidos
                    ? 'A venda já pode seguir para emissão. Se a SEFAZ ficar indisponível, o fluxo de contingência local será acionado e a regularização ficará na fila.'
                    : 'Revise itens e pagamento antes da emissão para evitar rejeições e retrabalho no cancelamento.',
                style: const TextStyle(height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDV / NFC-e'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (TenantContext.empresaId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  'Empresa: ${TenantContext.empresaId}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildNoticeBanner(),
          const SizedBox(height: 12),
          _buildResumoFiscalCard(),
          Expanded(child: isWide ? _buildWideLayout() : _buildNarrowLayout()),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _buildPainelBusca()),
        const VerticalDivider(width: 1),
        Expanded(flex: 4, child: _buildPainelCarrinho()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: 'Buscar Produto'), Tab(text: 'Carrinho')],
            labelColor: GridColors.secondary,
          ),
          Expanded(
            child: TabBarView(
              children: [_buildPainelBusca(), _buildPainelCarrinho()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelBusca() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _buscaCtrl,
            decoration: InputDecoration(
              labelText: 'Buscar produto por nome ou código',
              prefixIcon: _buscando
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _resultadosBusca.isEmpty && _buscaCtrl.text.trim().length >= 2
                ? const Center(child: Text('Nenhum produto encontrado.'))
                : ListView.builder(
                    itemCount: _resultadosBusca.length,
                    itemBuilder: (_, i) {
                      final p = _resultadosBusca[i];
                      final preco = (p['preco'] ?? p['precoVenda'] ?? 0).toDouble();
                      return ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(p['nome']?.toString() ?? '—'),
                        subtitle: Text('${p['codigo'] ?? ''} — R\$ ${preco.toStringAsFixed(2)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: GridColors.secondary),
                          onPressed: () {
                            _provider.adicionarItem(p);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${p['nome']} adicionado ao carrinho.'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        onTap: () => _provider.adicionarItem(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelCarrinho() {
    return Column(
      children: [
        Expanded(
          child: _provider.carrinho.isEmpty
              ? const Center(
                  child: Text('Carrinho vazio', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  itemCount: _provider.carrinho.length,
                  itemBuilder: (_, i) => _ItemCarrinhoTile(
                    item: _provider.carrinho[i],
                    onRemover: () => _provider.removerItem(i),
                    onDecrementar: () => _provider.atualizarQuantidade(i, _provider.carrinho[i].quantidade - 1),
                    onIncrementar: () => _provider.atualizarQuantidade(i, _provider.carrinho[i].quantidade + 1),
                  ),
                ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ResumoCampo(label: 'Subtotal', valor: _provider.subtotal, cor: Colors.black87),
              _ResumoCampo(label: 'Desconto', valor: _provider.descontoTotal, cor: Colors.orange),
              _ResumoCampo(
                label: 'TOTAL',
                valor: _provider.total,
                cor: GridColors.secondary,
                bold: true,
              ),
              if (_provider.pagamentos.isNotEmpty)
                _ResumoCampo(label: 'Troco', valor: _provider.troco, cor: Colors.blue),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _clienteCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'CPF/CNPJ do cliente (opcional)',
              border: const OutlineInputBorder(),
              errorText: _erroCliente,
              suffixIcon: const Icon(Icons.person_outline),
            ),
          ),
        ),
        _PainelPagamento(
          formasSelecionadas: _provider.pagamentos,
          formaSelecionada: _formaPagamentoSelecionada,
          valorCtrl: _valorPagtoCtrl,
          onFormaChanged: (f) => setState(() => _formaPagamentoSelecionada = f),
          onAdicionarPagamento: _adicionarPagamento,
          onRemoverPagamento: (i) => _provider.removerPagamento(i),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Cancelar venda?'),
                      content: const Text('O carrinho será limpo. Confirma?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Não'),
                        ),
                        TextButton(
                          onPressed: () {
                            _provider.limparCarrinho();
                            Navigator.pop(context);
                          },
                          child: const Text('Sim'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('CANCELAR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: _provider.emProcessamento
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('EMITIR NFC-e'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _provider.emProcessamento ? null : _emitirNfce,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemCarrinhoTile extends StatelessWidget {
  final ItemVendaModel item;
  final VoidCallback onRemover;
  final VoidCallback onDecrementar;
  final VoidCallback onIncrementar;

  const _ItemCarrinhoTile({
    required this.item,
    required this.onRemover,
    required this.onDecrementar,
    required this.onIncrementar,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(item.nomeProduto, style: const TextStyle(fontSize: 13)),
      subtitle: Text('R\$ ${item.precoUnitario.toStringAsFixed(2)} un.'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: onDecrementar,
          ),
          Text('${item.quantidade}', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: onIncrementar,
          ),
          Text(
            'R\$ ${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: GridColors.secondary),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: onRemover,
          ),
        ],
      ),
    );
  }
}

class _ResumoCampo extends StatelessWidget {
  final String label;
  final double valor;
  final Color cor;
  final bool bold;

  const _ResumoCampo({
    required this.label,
    required this.valor,
    required this.cor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cor,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              color: cor,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PainelPagamento extends StatelessWidget {
  final List<PagamentoModel> formasSelecionadas;
  final String formaSelecionada;
  final TextEditingController valorCtrl;
  final ValueChanged<String> onFormaChanged;
  final VoidCallback onAdicionarPagamento;
  final ValueChanged<int> onRemoverPagamento;

  static const _formas = [
    ('DINHEIRO', 'Dinheiro'),
    ('CARTAO_CREDITO', 'Cartão Crédito'),
    ('CARTAO_DEBITO', 'Cartão Débito'),
    ('PIX', 'PIX'),
    ('OUTRO', 'Outro'),
  ];

  const _PainelPagamento({
    required this.formasSelecionadas,
    required this.formaSelecionada,
    required this.valorCtrl,
    required this.onFormaChanged,
    required this.onAdicionarPagamento,
    required this.onRemoverPagamento,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pagamento:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: _formas
                .map(
                  (f) => ChoiceChip(
                    label: Text(f.$2, style: const TextStyle(fontSize: 12)),
                    selected: formaSelecionada == f.$1,
                    onSelected: (_) => onFormaChanged(f.$1),
                    selectedColor: GridColors.secondary,
                    labelStyle: TextStyle(
                      color: formaSelecionada == f.$1 ? Colors.white : Colors.black87,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAdicionarPagamento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('+ Adicionar'),
              ),
            ],
          ),
          if (formasSelecionadas.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...formasSelecionadas.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${e.value.formaPagamento}: R\$ ${e.value.valor.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => onRemoverPagamento(e.key),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
