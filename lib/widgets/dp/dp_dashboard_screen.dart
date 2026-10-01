import 'dart:convert';

import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';

class DpDashboardScreen extends StatefulWidget {
  const DpDashboardScreen({super.key});

  @override
  State<DpDashboardScreen> createState() => _DpDashboardScreenState();
}

class _DpDashboardScreenState extends State<DpDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await TenantContext.get(ApiLinks.dpDashboard);
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        if (body is Map) {
          _data = Map<String, dynamic>.from(body);
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kpis = Map<String, dynamic>.from((_data['kpis'] as Map?) ?? {});
    final listas = Map<String, dynamic>.from((_data['listas'] as Map?) ?? {});

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F1),
      appBar: AppBar(
        title: const Text('Dashboard DP'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _KpiTile('Funcionarios ativos', kpis['funcionariosAtivos'], Icons.badge),
                      _KpiTile('Ajustes pendentes', kpis['ajustesPontoPendentes'], Icons.schedule),
                      _KpiTile('Ferias proximas', kpis['feriasProximas'], Icons.beach_access),
                      _KpiTile('Admissoes abertas', kpis['admissoesEmAndamento'], Icons.person_add_alt),
                      _KpiTile('Desligamentos', kpis['desligamentosEmAndamento'], Icons.person_remove_alt_1),
                      _KpiTile('Eventos folha', kpis['eventosFolhaAbertos'], Icons.receipt_long),
                      _KpiTile('Obrigacoes trab.', kpis['obrigacoesTrabalhistasPendentes'], Icons.assignment_late),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionList(title: 'Ferias no radar', items: _asList(listas['ferias']), dateField: 'dataInicio'),
                  const SizedBox(height: 12),
                  _SectionList(title: 'Admissoes recentes', items: _asList(listas['admissoes']), dateField: 'dataPrevista'),
                  const SizedBox(height: 12),
                  _SectionList(title: 'Desligamentos recentes', items: _asList(listas['desligamentos']), dateField: 'dataDesligamento'),
                ],
              ),
            ),
    );
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final dynamic value;
  final IconData icon;

  const _KpiTile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD7DED4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: GridColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${value ?? 0}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String dateField;

  const _SectionList({required this.title, required this.items, required this.dateField});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7DED4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const Text('Sem registros no momento.', style: TextStyle(color: Color(0xFF6B7280)))
            else
              ...items.map((item) {
                final funcionario = item['funcionario'];
                final nome = funcionario is Map ? funcionario['nome']?.toString() : null;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(nome ?? item['candidatoNome']?.toString() ?? item['tipo']?.toString() ?? 'Registro DP'),
                  subtitle: Text('${item['status'] ?? ''} ${item[dateField] ?? ''}'.trim()),
                );
              }),
          ],
        ),
      ),
    );
  }
}
