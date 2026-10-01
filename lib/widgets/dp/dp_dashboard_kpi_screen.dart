import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';

class DpDashboardKpiScreen extends StatefulWidget {
  const DpDashboardKpiScreen({super.key});

  @override
  State<DpDashboardKpiScreen> createState() => _DpDashboardKpiScreenState();
}

class _DpDashboardKpiScreenState extends State<DpDashboardKpiScreen> {
  bool _loading = true;
  Map<String, dynamic> _kpis = {};
  Map<String, dynamic> _benchmarks = {};
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final res = await NetworkCaller().getRequest(ApiLinks.dpDashboardKpi);
      if (res.isSuccess && res.body != null) {
        final data = res.body!['data'];
        if (data is Map) {
          setState(() {
            _kpis = Map<String, dynamic>.from(data);
            _benchmarks = Map<String, dynamic>.from((data['benchmarks'] as Map?) ?? {});
          });
        }
      } else {
        setState(() { _erro = res.errorMessage ?? 'Erro ao carregar KPIs ABRH/FGV'; });
      }
    } catch (e) {
      setState(() { _erro = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F1),
      appBar: AppBar(
        title: const Text('Dashboard de Indicadores RH (Padrões ABRH / FGV)'),
        actions: [
          IconButton(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Indicadores',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Cabeçalho com Período e Benchmark ABRH
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Métricas Estratégicas de Capital Humano',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Período: ${_kpis['periodo'] ?? 'Atual'}  •  Classificação Oficial de Mercado',
                                    style: const TextStyle(color: Colors.black54, fontSize: 13)),
                              ],
                            ),
                            Row(
                              children: [
                                _legendaDot(Colors.green, 'Ideal (ABRH)'),
                                const SizedBox(width: 12),
                                _legendaDot(Colors.amber.shade700, 'Atenção'),
                                const SizedBox(width: 12),
                                _legendaDot(Colors.redAccent, 'Crítico'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Grid de 9 KPIs ABRH/FGV
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _KpiCard(
                            titulo: 'Headcount Total',
                            valor: '${_kpis['headcountTotal'] ?? 0}',
                            subtitulo: 'FTE Equivalente: ${_kpis['fte'] ?? 0}',
                            icone: Icons.people_alt,
                            status: 'VERDE',
                          ),
                          _KpiCard(
                            titulo: 'Turnover Geral',
                            valor: '${_kpis['turnoverPct'] ?? 0}%',
                            subtitulo: 'Meta de mercado: < 3,0%',
                            icone: Icons.swap_horiz,
                            status: _benchmarks['turnoverStatus'] ?? 'VERDE',
                          ),
                          _KpiCard(
                            titulo: 'Taxa de Absenteísmo',
                            valor: '${_kpis['absenteismoPct'] ?? 0}%',
                            subtitulo: 'Padrão OIT/ABRH: < 2,5%',
                            icone: Icons.event_busy,
                            status: _benchmarks['absenteismoStatus'] ?? 'VERDE',
                          ),
                          _KpiCard(
                            titulo: 'Horas Extras / Folha',
                            valor: '${_kpis['horasExtrasPct'] ?? 0}%',
                            subtitulo: 'Limite saudável: < 5,0%',
                            icone: Icons.access_time,
                            status: _benchmarks['horasExtrasStatus'] ?? 'VERDE',
                          ),
                          _KpiCard(
                            titulo: 'Compensação Banco',
                            valor: '${_kpis['compensacaoBancoHorasPct'] ?? 0}%',
                            subtitulo: 'Meta sem passivo: > 85%',
                            icone: Icons.account_balance_wallet,
                            status: _benchmarks['bancoHorasStatus'] ?? 'VERDE',
                          ),
                          _KpiCard(
                            titulo: 'Custo per Capita',
                            valor: 'R\$ ${_formatMoeda(_kpis['custoPerCapita'])}',
                            subtitulo: 'TCOW com encargos e provisões',
                            icone: Icons.monetization_on,
                            status: 'VERDE',
                          ),
                          _KpiCard(
                            titulo: 'IEP Produtividade',
                            valor: '${_kpis['iepProdutividade'] ?? 0}x',
                            subtitulo: 'Retorno sobre a folha salarial',
                            icone: Icons.trending_up,
                            status: _benchmarks['iepStatus'] ?? 'VERDE',
                          ),
                          _KpiCard(
                            titulo: 'Ratio CLT vs PJ',
                            valor: '${_kpis['ratioCltPj'] ?? 0} : 1',
                            subtitulo: 'Equilíbrio trabalhista',
                            icone: Icons.balance,
                            status: 'VERDE',
                          ),
                          _KpiCard(
                            titulo: 'Afastamentos / Saúde',
                            valor: '${(_kpis['afastamentosPorTipo'] as Map?)?.length ?? 0} tipos',
                            subtitulo: 'Doença, maternidade, acidente',
                            icone: Icons.medical_services,
                            status: 'VERDE',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _legendaDot(Color color, String text) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  String _formatMoeda(dynamic val) {
    if (val == null) return '0,00';
    return val.toString();
  }
}

class _KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icone;
  final String status;

  const _KpiCard({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icone,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color corStatus = Colors.green;
    if (status == 'AMARELO') corStatus = Colors.amber.shade700;
    if (status == 'VERMELHO') corStatus = Colors.redAccent;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: corStatus.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: corStatus, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(valor, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: corStatus)),
          const SizedBox(height: 6),
          Text(subtitulo, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
