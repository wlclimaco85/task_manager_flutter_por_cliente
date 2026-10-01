import 'package:flutter/material.dart';
import '../models/backtest_models.dart';
import '../services/backtest_repository.dart';


class BacktestScreen extends StatefulWidget {
  final BacktestRepository repository;
  const BacktestScreen({super.key, required this.repository});

  @override
  State<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> {
  final _assetController = TextEditingController();
  final _strategyController = TextEditingController(text: 'SCORE_THRESHOLD');
  final _paramsController = TextEditingController(text: '{"threshold":0.6}');
  final _periodStartController = TextEditingController();
  final _periodEndController = TextEditingController();
  DateTime? _periodStart;
  DateTime? _periodEnd;

  List<BacktestRunResponse> _runs = [];
  bool _loading = false;
  bool _running = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    setState(() { _loading = true; _error = null; });
    try {
      _runs = await widget.repository.listRuns();
    } catch (e) {
      setState(() { _error = 'Erro ao carregar histórico: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _runBacktest() async {
    final asset = _assetController.text.trim();
    if (asset.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o ativo')));
      return;
    }
    setState(() { _running = true; _error = null; });
    try {
      final resp = await widget.repository.runBacktest(
        assetSymbol: asset,
        strategyName: _strategyController.text.trim(),
        ruleParams: _paramsController.text.trim().isEmpty ? null : _paramsController.text.trim(),
        periodStart: _periodStart == null
            ? null
            : DateTime.utc(
                _periodStart!.year,
                _periodStart!.month,
                _periodStart!.day,
              ).toIso8601String(),
        periodEnd: _periodEnd == null
            ? null
            : DateTime.utc(
                _periodEnd!.year,
                _periodEnd!.month,
                _periodEnd!.day,
                23,
                59,
                59,
              ).toIso8601String(),
      );
      setState(() { _runs.insert(0, resp); });
    } catch (e) {
      setState(() { _error = 'Erro ao rodar backtesting: $e'; });
    } finally {
      setState(() { _running = false; });
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? (_periodStart ?? DateTime.now()) : (_periodEnd ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final formatted = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _periodStart = picked;
        _periodStartController.text = formatted;
      } else {
        _periodEnd = picked;
        _periodEndController.text = formatted;
      }
    });
  }

  @override
  void dispose() {
    _assetController.dispose();
    _strategyController.dispose();
    _paramsController.dispose();
    _periodStartController.dispose();
    _periodEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backtesting')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildForm(),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    TextButton(onPressed: _loadRuns, child: const Text('Tentar novamente')),
                  ],
                ),
              ),
            const Text('Histórico de Simulações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildRunList()),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nova Simulação', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _assetController,
              decoration: const InputDecoration(labelText: 'Ativo (ex: PETR4)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _strategyController,
              decoration: const InputDecoration(labelText: 'Estratégia', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _paramsController,
              decoration: const InputDecoration(labelText: 'Parâmetros (JSON)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _periodStartController,
                    readOnly: true,
                    onTap: () => _pickDate(isStart: true),
                    decoration: const InputDecoration(labelText: 'Período início', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today, size: 18)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _periodEndController,
                    readOnly: true,
                    onTap: () => _pickDate(isStart: false),
                    decoration: const InputDecoration(labelText: 'Período fim', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today, size: 18)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _running ? null : _runBacktest,
              child: _running
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Rodar Simulação'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunList() {
    if (_runs.isEmpty) return const Center(child: Text('Nenhuma simulação ainda'));
    return ListView.builder(
      itemCount: _runs.length,
      itemBuilder: (_, i) {
        final item = _runs[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${item.assetSymbol} — ${item.strategyName}'),
            subtitle: item.numTrades == 0
                ? Text('Status: ${item.status}')
                : Text(
                    'Trades: ${item.numTrades} | Win: ${item.winRate.toStringAsFixed(1)}% | Lucro: ${item.totalProfit.toStringAsFixed(2)} | Perda: ${item.totalLoss.toStringAsFixed(2)} | Net: ${item.netResult.toStringAsFixed(2)} | Drawdown: ${item.maxDrawdown.toStringAsFixed(2)}'),
            trailing: _statusChip(item.status),
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'DONE' ? Colors.green : status == 'RUNNING' ? Colors.orange : Colors.grey;
    return Chip(label: Text(status, style: const TextStyle(fontSize: 11)), backgroundColor: color.withOpacity(0.15));
  }
}
