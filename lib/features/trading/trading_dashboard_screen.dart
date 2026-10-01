import 'package:flutter/material.dart';
import '../../mobile/screens/market_overview_screen.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import 'trading_models.dart';
import 'trading_repository.dart';

/// Tela principal de Trading com 5 abas:
/// - Dashboard: visão consolidada do mercado (MarketOverviewScreen existente)
/// - Watchlist: lista de ativos monitorados pelo usuário
/// - Alertas: alertas de preço criados pelo usuário
/// - Operações: operações assistidas enviadas ao simulador/broker
/// - Corretora: configuração centralizada de login, conta e ambiente MT5
class TradingDashboardScreen extends StatelessWidget {
  final int initialTabIndex;
  const TradingDashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trading'),
          backgroundColor: GridColors.primary,
          foregroundColor: GridColors.textPrimary,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: 'Dashboard'),
              Tab(icon: Icon(Icons.bookmark_border), text: 'Watchlist'),
              Tab(icon: Icon(Icons.notifications_none), text: 'Alertas'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'Operações'),
              Tab(icon: Icon(Icons.settings_input_antenna), text: 'Corretora'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DashboardTab(),
            _WatchlistTab(),
            _AlertasTab(),
            _OperacoesTab(),
            BrokerConfigTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 — Dashboard
// Reutiliza o MarketOverviewScreen existente sem o AppBar próprio dele,
// pois o AppBar já é fornecido pelo TradingDashboardScreen.
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    // showAppBar: false suprime o AppBar interno do MarketOverviewScreen,
    // pois o AppBar com TabBar já é fornecido pelo TradingDashboardScreen.
    return const MarketOverviewScreen(showAppBar: false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Watchlist
// ─────────────────────────────────────────────────────────────────────────────

class _WatchlistTab extends StatefulWidget {
  const _WatchlistTab();

  @override
  State<_WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends State<_WatchlistTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = TradingRepository();
  List<WatchlistItem> _items = [];
  bool _loading = true;
  bool _analyzing = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // empresa não é obrigatória — backend usa tenantId do JWT ou retorna lista vazia
    try {
      final items = await _repo.fetchWatchlist();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmRemove(WatchlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover ativo'),
        content: Text('Remover ${item.assetSymbol} da watchlist?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(GridTexts.remove,
                  style: TextStyle(color: GridColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.removeFromWatchlist(item.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((i) => i.id == item.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover: $e')),
      );
    }
  }

  Future<void> _showAddDialog() async {
    final symbolCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar ativo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: symbolCtrl,
                decoration: const InputDecoration(
                  labelText: 'Símbolo *',
                  hintText: 'Ex: PETR4, BTC, AAPL',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o símbolo' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Adicionar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final item = await _repo.addToWatchlist(
        symbolCtrl.text.trim().toUpperCase(),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _items.add(item));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar: $e')),
      );
    }
  }

  Future<void> _analyzeWatchlist() async {
    if (_items.isEmpty || _analyzing) return;
    setState(() => _analyzing = true);
    try {
      final sinais = await _repo.analyzeWatchlist();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analise concluida: ${sinais.length} sinal(is) gerado(s)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao analisar watchlist: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _analyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _load);
    }

    return Scaffold(
      body: _items.isEmpty
          ? _WatchlistEmpty(onAdd: _showAddDialog)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          GridColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        item.assetSymbol.length > 2
                            ? item.assetSymbol.substring(0, 2)
                            : item.assetSymbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: GridColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      item.assetSymbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: item.notes != null && item.notes!.isNotEmpty
                        ? Text(item.notes!,
                            style: const TextStyle(fontSize: 13))
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: GridColors.error,
                      tooltip: 'Remover',
                      onPressed: () => _confirmRemove(item),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'trading-analyze-watchlist',
            backgroundColor: GridColors.primary,
            foregroundColor: Colors.white,
            tooltip: 'Analisar watchlist',
            onPressed: _items.isEmpty || _analyzing ? null : _analyzeWatchlist,
            child: _analyzing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_graph),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'trading-add-watchlist',
            backgroundColor: GridColors.primary,
            foregroundColor: Colors.white,
            tooltip: 'Adicionar ativo',
            onPressed: _showAddDialog,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _WatchlistEmpty extends StatelessWidget {
  final VoidCallback onAdd;
  const _WatchlistEmpty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Nenhum ativo na watchlist',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary),
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Adicionar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Alertas
// ─────────────────────────────────────────────────────────────────────────────

class _AlertasTab extends StatefulWidget {
  const _AlertasTab();

  @override
  State<_AlertasTab> createState() => _AlertasTabState();
}

class _AlertasTabState extends State<_AlertasTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = TradingRepository();
  List<TradingAlerta> _alertas = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // empresa não é obrigatória — backend usa tenantId do JWT ou retorna lista vazia
    try {
      final alertas = await _repo.fetchAlertas();
      if (!mounted) return;
      setState(() {
        _alertas = alertas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _cancelarAlerta(TradingAlerta alerta) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar alerta'),
        content: Text(
            'Cancelar alerta de ${alerta.assetSymbol} a ${alerta.priceTarget.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Cancelar alerta',
                  style: TextStyle(color: GridColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.cancelarAlerta(alerta.id);
      if (!mounted) return;
      setState(() {
        final idx = _alertas.indexWhere((a) => a.id == alerta.id);
        if (idx != -1) {
          _alertas[idx] = TradingAlerta(
            id: alerta.id,
            assetSymbol: alerta.assetSymbol,
            priceTarget: alerta.priceTarget,
            direction: alerta.direction,
            status: 'CANCELADO',
            triggeredAt: alerta.triggeredAt,
            message: alerta.message,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar: $e')),
      );
    }
  }

  Future<void> _showCreateDialog() async {
    final symbolCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String direction = 'ABOVE';
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Novo alerta de preço'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: symbolCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Símbolo *',
                      hintText: 'Ex: PETR4, BTC, AAPL',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o símbolo'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Preço alvo *',
                      hintText: 'Ex: 28.50',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o preço';
                      }
                      if (double.tryParse(v.replaceAll(',', '.')) == null) {
                        return 'Preço inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: direction,
                    decoration:
                        const InputDecoration(labelText: 'Direção *'),
                    items: const [
                      DropdownMenuItem(
                        value: 'ABOVE',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward,
                                color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('ABOVE — acima do preço'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'BELOW',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward,
                                color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('BELOW — abaixo do preço'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setDlgState(() => direction = v ?? 'ABOVE'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: messageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mensagem (opcional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(GridTexts.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Criar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    try {
      final alerta = await _repo.createAlerta(
        symbol: symbolCtrl.text.trim().toUpperCase(),
        priceTarget: double.parse(priceCtrl.text.trim().replaceAll(',', '.')),
        direction: direction,
        message: messageCtrl.text.trim().isEmpty
            ? null
            : messageCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _alertas.insert(0, alerta));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar alerta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _load);
    }

    return Scaffold(
      body: _alertas.isEmpty
          ? _AlertasEmpty(onCreate: _showCreateDialog)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _alertas.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) => _AlertaCard(
                  alerta: _alertas[i],
                  onCancelar: () => _cancelarAlerta(_alertas[i]),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Novo alerta',
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final TradingAlerta alerta;
  final VoidCallback onCancelar;

  const _AlertaCard({required this.alerta, required this.onCancelar});

  Color get _statusColor {
    if (alerta.isDisparado) return Colors.orange;
    if (alerta.isCancelado) return Colors.grey;
    return GridColors.secondary;
  }

  String get _statusLabel {
    if (alerta.isDisparado) return 'DISPARADO';
    if (alerta.isCancelado) return 'CANCELADO';
    return 'ATIVO';
  }

  @override
  Widget build(BuildContext context) {
    final isDisparado = alerta.isDisparado;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isDisparado
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone de direção
            Column(
              children: [
                Icon(
                  alerta.direction == 'ABOVE'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: alerta.direction == 'ABOVE'
                      ? Colors.green
                      : Colors.red,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Conteúdo principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        alerta.assetSymbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                          label: _statusLabel, color: _statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${alerta.direction == "ABOVE" ? "Acima de" : "Abaixo de"} '
                    'R\$ ${alerta.priceTarget.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (alerta.message != null &&
                      alerta.message!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      alerta.message!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  if (alerta.triggeredAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Disparado em: ${alerta.triggeredAt}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.orange[700]),
                    ),
                  ],
                ],
              ),
            ),
            // Botão cancelar (somente ATIVO)
            if (alerta.isAtivo)
              IconButton(
                icon: const Icon(Icons.cancel_outlined),
                color: GridColors.error,
                tooltip: 'Cancelar alerta',
                onPressed: onCancelar,
              ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _AlertasEmpty extends StatelessWidget {
  final VoidCallback onCreate;
  const _AlertasEmpty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Nenhum alerta configurado',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary),
            onPressed: onCreate,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Criar alerta',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Operações Assistidas
// ─────────────────────────────────────────────────────────────────────────────

class _OperacoesTab extends StatefulWidget {
  const _OperacoesTab();

  @override
  State<_OperacoesTab> createState() => _OperacoesTabState();
}

class _OperacoesTabState extends State<_OperacoesTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = TradingRepository();
  List<OperacaoAssistida> _operacoes = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // empresa não é obrigatória — backend usa tenantId do JWT ou retorna lista vazia
    try {
      final operacoes = await _repo.fetchOperacoes();
      if (!mounted) return;
      setState(() {
        _operacoes = operacoes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _atualizarStatus(OperacaoAssistida op) async {
    try {
      final atualizada = await _repo.consultarStatusOperacao(op.id);
      if (!mounted) return;
      setState(() {
        final idx = _operacoes.indexWhere((o) => o.id == op.id);
        if (idx != -1) _operacoes[idx] = atualizada;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $e')),
      );
    }
  }

  Future<void> _cancelar(OperacaoAssistida op) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar operação'),
        content: Text(
            'Cancelar operação ${op.direcao} de ${op.quantidade} ${op.assetSymbol}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Cancelar operação',
                  style: TextStyle(color: GridColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.cancelarOperacao(op.id);
      if (!mounted) return;
      await _atualizarStatus(op);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar: $e')),
      );
    }
  }

  Future<void> _showNovaOperacaoDialog() async {
    final result = await showDialog<OperacaoAssistida>(
      context: context,
      builder: (_) => _NovaOperacaoDialog(repo: _repo),
    );
    if (result == null) return;
    if (!mounted) return;
    setState(() => _operacoes.insert(0, result));

    // Auto-refresh após 3s para capturar status do simulador
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    try {
      final atualizada = await _repo.consultarStatusOperacao(result.id);
      if (!mounted) return;
      setState(() {
        final idx = _operacoes.indexWhere((o) => o.id == result.id);
        if (idx != -1) _operacoes[idx] = atualizada;
      });
    } catch (_) {
      // Silencioso — o usuário pode atualizar manualmente
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _load);
    }

    return Scaffold(
      body: _operacoes.isEmpty
          ? const _OperacoesEmpty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _operacoes.length,
                itemBuilder: (_, i) => _OperacaoCard(
                  operacao: _operacoes[i],
                  onAtualizarStatus: () => _atualizarStatus(_operacoes[i]),
                  onCancelar: () => _cancelar(_operacoes[i]),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Nova operação',
        onPressed: _showNovaOperacaoDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nova Operação'),
      ),
    );
  }
}

// ── Card de operação ──────────────────────────────────────────────────────────

class _OperacaoCard extends StatelessWidget {
  final OperacaoAssistida operacao;
  final VoidCallback onAtualizarStatus;
  final VoidCallback onCancelar;

  const _OperacaoCard({
    required this.operacao,
    required this.onAtualizarStatus,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final op = operacao;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha principal: símbolo + direção + status
            Row(
              children: [
                Text(
                  op.assetSymbol,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(width: 8),
                _direcaoChip(op.direcao),
                const Spacer(),
                _statusChip(op.status),
              ],
            ),
            const SizedBox(height: 6),
            // Quantidade
            Text(
              'Qtd: ${op.quantidade.toStringAsFixed(op.quantidade.truncateToDouble() == op.quantidade ? 0 : 2)}',
              style: const TextStyle(fontSize: 13),
            ),
            // Stop Loss / Take Profit
            if (op.stopLoss != null || op.takeProfit != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  if (op.stopLoss != null)
                    Text(
                      'SL: ${op.stopLoss!.toStringAsFixed(2)}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  if (op.stopLoss != null && op.takeProfit != null)
                    const SizedBox(width: 12),
                  if (op.takeProfit != null)
                    Text(
                      'TP: ${op.takeProfit!.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.green),
                    ),
                ],
              ),
            ],
            // External order ID
            if (op.externalOrderId != null &&
                op.externalOrderId!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'ID: ${op.externalOrderId}',
                  style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade700),
                ),
              ),
            ],
            // Mensagem de erro
            if (op.isErro && op.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                op.errorMessage!,
                style:
                    const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ],
            // Botões de ação
            if (op.cancelavel) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onAtualizarStatus,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Atualizar Status',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: onCancelar,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancelar',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: GridColors.error),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _direcaoChip(String direcao) {
    final isBuy = direcao == 'BUY';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isBuy ? Colors.green : Colors.red).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (isBuy ? Colors.green : Colors.red)
                .withValues(alpha: 0.6)),
      ),
      child: Text(
        direcao,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isBuy ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }
}

Widget _statusChip(String status) {
  final Color color;
  switch (status) {
    case 'PENDENTE':
      color = Colors.orange;
      break;
    case 'ENVIADA':
      color = Colors.blue;
      break;
    case 'EXECUTADA':
      color = Colors.green;
      break;
    case 'CANCELADA':
      color = Colors.grey;
      break;
    case 'ERRO':
      color = Colors.red;
      break;
    default:
      color = Colors.grey;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      status,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
  );
}

// ── Dialog nova operação ──────────────────────────────────────────────────────

class _NovaOperacaoDialog extends StatefulWidget {
  final TradingRepository repo;
  const _NovaOperacaoDialog({required this.repo});

  @override
  State<_NovaOperacaoDialog> createState() => _NovaOperacaoDialogState();
}

class _NovaOperacaoDialogState extends State<_NovaOperacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _symbolCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _slCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();
  final _accountIdCtrl = TextEditingController(text: '1');
  String _direcao = 'BUY';
  String _ambiente = 'TESTE';
  bool _loading = false;
  TradingBrokerConfig? _brokerConfig;

  @override
  void initState() {
    super.initState();
    _carregarConfigCorretora();
  }

  Future<void> _carregarConfigCorretora() async {
    try {
      final config = await widget.repo.fetchBrokerConfig();
      if (!mounted || config == null) return;
      setState(() {
        _brokerConfig = config;
        if (config.accountId.isNotEmpty) {
          _accountIdCtrl.text = config.accountId;
        }
        if (config.ambientePadrao.isNotEmpty) {
          _ambiente = config.ambientePadrao;
        }
      });
    } catch (_) {
      // A operação ainda pode ser preenchida manualmente se não houver configuração.
    }
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _qtdCtrl.dispose();
    _slCtrl.dispose();
    _tpCtrl.dispose();
    _accountIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final op = await widget.repo.enviarOperacao(
        assetSymbol: _symbolCtrl.text.trim().toUpperCase(),
        direcao: _direcao,
        quantidade:
            double.parse(_qtdCtrl.text.trim().replaceAll(',', '.')),
        accountId: int.parse(_accountIdCtrl.text.trim()),
        stopLoss: _slCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_slCtrl.text.trim().replaceAll(',', '.')),
        takeProfit: _tpCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_tpCtrl.text.trim().replaceAll(',', '.')),
        ambiente: _ambiente,
      );
      if (!mounted) return;
      Navigator.pop(context, op);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Operação Assistida'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _symbolCtrl,
                decoration: const InputDecoration(
                  labelText: 'Símbolo do ativo *',
                  hintText: 'Ex: PETR4, BTC, EURUSD',
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) {
                  if (v != v.toUpperCase()) {
                    _symbolCtrl.value = _symbolCtrl.value.copyWith(
                      text: v.toUpperCase(),
                      selection: TextSelection.collapsed(
                          offset: v.length),
                    );
                  }
                },
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o símbolo'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _direcao,
                decoration: const InputDecoration(labelText: 'Direção *'),
                items: const [
                  DropdownMenuItem(
                    value: 'BUY',
                    child: Row(children: [
                      Icon(Icons.arrow_upward,
                          color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text('BUY — Compra'),
                    ]),
                  ),
                  DropdownMenuItem(
                    value: 'SELL',
                    child: Row(children: [
                      Icon(Icons.arrow_downward,
                          color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('SELL — Venda'),
                    ]),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _direcao = v ?? 'BUY'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountIdCtrl,
                decoration: InputDecoration(
                  labelText: 'Conta / Account ID *',
                  hintText: 'Ex: 1',
                  helperText: _brokerConfig != null
                      ? 'Preenchido pela configuração salva da corretora. Você pode ajustar se necessário.'
                      : 'Obrigatório para enviar ao simulador ou MetaTrader.',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final parsed = int.tryParse((v ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Informe um accountId válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantidade *',
                  hintText: 'Ex: 100',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe a quantidade';
                  }
                  final parsed =
                      double.tryParse(v.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Quantidade deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slCtrl,
                decoration: const InputDecoration(
                  labelText: 'Stop Loss (opcional)',
                  hintText: 'Ex: 28.50',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim().replaceAll(',', '.')) ==
                      null) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tpCtrl,
                decoration: const InputDecoration(
                  labelText: 'Take Profit (opcional)',
                  hintText: 'Ex: 32.00',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim().replaceAll(',', '.')) ==
                      null) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _ambiente,
                decoration:
                    const InputDecoration(labelText: 'Ambiente *'),
                items: const [
                  DropdownMenuItem(
                      value: 'TESTE', child: Text('TESTE')),
                  DropdownMenuItem(
                      value: 'PRODUCAO', child: Text('PRODUCAO')),
                ],
                onChanged: (v) =>
                    setState(() => _ambiente = v ?? 'TESTE'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.primary),
          onPressed: _loading ? null : _enviar,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Enviar',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ── Estado vazio de operações ─────────────────────────────────────────────────

class BrokerConfigTab extends StatefulWidget {
  final TradingRepository? repository;

  const BrokerConfigTab({super.key, this.repository});

  @override
  State<BrokerConfigTab> createState() => _BrokerConfigTabState();
}

class _BrokerConfigTabState extends State<BrokerConfigTab>
    with AutomaticKeepAliveClientMixin {
  late final TradingRepository _repo;
  final _formKey = GlobalKey<FormState>();
  final _brokerLoginCtrl = TextEditingController();
  final _brokerPasswordCtrl = TextEditingController();
  final _accountIdCtrl = TextEditingController();
  String _ambientePadrao = 'TESTE';
  bool _ativo = true;
  bool _mostrarSenha = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  TradingBrokerConfig? _config;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? TradingRepository();
    _load();
  }

  @override
  void dispose() {
    _brokerLoginCtrl.dispose();
    _brokerPasswordCtrl.dispose();
    _accountIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // empresa não é obrigatória — backend usa tenantId do JWT ou retorna lista vazia
    try {
      final config = await _repo.fetchBrokerConfig();
      if (!mounted) return;
      setState(() {
        _config = config;
        _brokerLoginCtrl.text = config?.brokerLogin ?? '';
        _accountIdCtrl.text = config?.accountId ?? '';
        _ambientePadrao = const {'TESTE', 'PRODUCAO'}
                .contains(config?.ambientePadrao)
            ? config!.ambientePadrao
            : 'TESTE';
        _ativo = config?.ativo ?? true;
        _brokerPasswordCtrl.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final salvo = await _repo.saveBrokerConfig(
        brokerLogin: _brokerLoginCtrl.text.trim(),
        accountId: _accountIdCtrl.text.trim(),
        ambientePadrao: _ambientePadrao,
        ativo: _ativo,
        brokerPassword: _brokerPasswordCtrl.text.trim().isEmpty
            ? null
            : _brokerPasswordCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _config = salvo;
        _brokerPasswordCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuração da corretora salva com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar configuração: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorView(error: _error!, onRetry: _load);
    }

    return SingleChildScrollView(
      key: const Key('broker_config_scroll'),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuração da Corretora / MT5',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Essa configuração fica salva no backend principal da aplicação para a sua empresa. A senha não volta em claro para o app e só é usada no envio das ordens.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _brokerLoginCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Login da corretora *',
                        hintText: 'Ex: 54901332',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o login da corretora'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _brokerPasswordCtrl,
                      obscureText: !_mostrarSenha,
                      decoration: InputDecoration(
                        labelText: _config?.hasBrokerPassword == true
                            ? 'Nova senha da corretora (opcional)'
                            : 'Senha da corretora *',
                        hintText: _config?.hasBrokerPassword == true
                            ? 'Preencha apenas se quiser trocar a senha salva'
                            : GridTexts.tradingBrokerPasswordRequired,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                          icon: Icon(
                            _mostrarSenha ? Icons.visibility_off : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if ((_config?.hasBrokerPassword != true) &&
                            (v == null || v.trim().isEmpty)) {
                          return GridTexts.tradingBrokerPasswordRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Conta / Account ID *',
                        hintText: 'Ex: 54901332',
                      ),
                      validator: (v) {
                        final parsed = int.tryParse((v ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Informe um accountId válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('broker_config_ambiente_dropdown'),
                      value: _ambientePadrao,
                      decoration: const InputDecoration(
                        labelText: 'Ambiente padrão *',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'TESTE', child: Text('TESTE')),
                        DropdownMenuItem(value: 'PRODUCAO', child: Text('PRODUCAO')),
                      ],
                      onChanged: (v) => setState(() => _ambientePadrao = v ?? 'TESTE'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      key: const Key('broker_config_ativo_switch'),
                      value: _ativo,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Configuração ativa'),
                      subtitle: const Text(
                        'Quando ativo, novas operações usam essas credenciais automaticamente.',
                      ),
                      onChanged: (v) => setState(() => _ativo = v),
                    ),
                    if (_config != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: GridColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: GridColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          _config!.hasBrokerPassword
                              ? 'Senha já cadastrada com segurança no servidor. Atualizado em: ${_config!.updatedAt ?? 'data indisponível'}'
                              : 'Ainda não há senha cadastrada no servidor para esta configuração.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        key: const Key('broker_config_salvar_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GridColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saving ? null : _salvar,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_saving ? 'Salvando...' : 'Salvar configuração'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperacoesEmpty extends StatelessWidget {
  const _OperacoesEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma operação enviada',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget de erro compartilhado
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
