import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../services/ai_analise_service.dart';
import '../../../services/lancamento_contabil_service.dart';
import '../../../services/periodo_contabil_service.dart';
import '../../../utils/grid_colors.dart';

class WebAiDashboardScreen extends StatefulWidget {
  const WebAiDashboardScreen({super.key});
  @override
  State<WebAiDashboardScreen> createState() => _WebAiDashboardScreenState();
}

class _WebAiDashboardScreenState extends State<WebAiDashboardScreen> {
  final _aiService = AiAnaliseService();
  final _periodoService = PeriodoContabilService();
  final _lancamentoService = LancamentoContabilService();
  final String _periodo = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  Map<String, dynamic>? _dre;
  List<Map<String, dynamic>>? _anomalias;
  Map<String, dynamic>? _obrigacoes;
  Map<String, dynamic>? _fechamento;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final login = AuthUtility.userInfo?.login;
    final empId = int.tryParse(login?.empresa?.id?.toString() ?? '');
    if (empId == null) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _aiService.analisarDre(empId, _periodo),
        _aiService.anomaliasFiscais(empId, periodo: _periodo),
        _aiService.preverObrigacoes(empId),
        _periodoService.analisarFechamento(empId, _periodo),
      ]);
      if (mounted) setState(() {
        _dre = results[0] as Map<String, dynamic>?;
        _anomalias = results[1] as List<Map<String, dynamic>>?;
        _obrigacoes = results[2] as Map<String, dynamic>?;
        _fechamento = results[3] as Map<String, dynamic>?;
      });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.filterBackground,
      appBar: AppBar(
        title: const Text('Dashboard Contábil IA'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Período: $_periodo', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Wrap(runSpacing: 12, spacing: 12, children: [
                    _metricCard('Score Saúde', '${_fechamento?['score'] ?? '?'}/100', GridColors.info, Icons.health_and_safety),
                    _metricCard('Receita', _fmt(_dre?['receita']), GridColors.success, Icons.trending_up),
                    _metricCard('Despesa', _fmt(_dre?['despesa']), GridColors.error, Icons.trending_down),
                    _metricCard('Margem', '${_dre?['margemLiquidaPct'] ?? '?'}%', GridColors.info, Icons.pie_chart),
                    _metricCard('Anomalias', '${_anomalias?.length ?? 0}', GridColors.warning, Icons.warning_amber),
                    _metricCard('Obrigações', '${_obrigacoes?['total'] ?? '?'}', GridColors.primary, Icons.assignment),
                  ]),
                  const SizedBox(height: 24),
                  if (_anomalias != null && _anomalias!.isNotEmpty) ...[
                    const Text('Alertas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._anomalias!.map((a) => Card(
                      color: a['severidade'] == 'ALTA' ? GridColors.error.withOpacity(0.1) : GridColors.warning.withOpacity(0.1),
                      child: ListTile(
                        leading: Icon(a['severidade'] == 'ALTA' ? Icons.error : Icons.warning, color: GridColors.error),
                        title: Text(a['descricao']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                        subtitle: a['sugestao'] != null ? Text(a['sugestao'].toString(), style: const TextStyle(fontSize: 11)) : null,
                      ),
                    )),
                  ],
                  if (_dre?['insights'] is List && (_dre!['insights'] as List).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Insights DRE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...(_dre!['insights'] as List).map((i) => Card(child: ListTile(
                      leading: const Icon(Icons.lightbulb, color: GridColors.warning),
                      title: Text(i.toString(), style: const TextStyle(fontSize: 13)),
                    ))),
                  ],
                ]),
              ),
            ),
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '0,00';
    if (v is double || v is int) return v.toStringAsFixed(2).replaceAll('.', ',');
    return v.toString();
  }
}
