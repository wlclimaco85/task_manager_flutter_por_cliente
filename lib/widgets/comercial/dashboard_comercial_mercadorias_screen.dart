import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/auth_utility.dart';
import '../../models/dashboard_comercial_mercadorias_model.dart';
import '../../services/dashboard_comercial_caller.dart';
import '../../services/empresa_caller.dart';
import '../../utils/dropdown_helpers.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../../utils/utils.dart';

class DashboardComercialMercadoriasScreen extends StatefulWidget {
  final bool showAppBar;

  const DashboardComercialMercadoriasScreen({
    super.key,
    this.showAppBar = false,
  });

  @override
  State<DashboardComercialMercadoriasScreen> createState() =>
      _DashboardComercialMercadoriasScreenState();
}

class _DashboardComercialMercadoriasScreenState
    extends State<DashboardComercialMercadoriasScreen> {
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _number = NumberFormat.decimalPattern('pt_BR');

  bool _loading = true;
  String? _error;
  DashboardComercialMercadoriasModel _dashboard =
      DashboardComercialMercadoriasModel.empty();
  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _parceiros = [];
  int? _empresaId;
  int? _parceiroId;
  String _periodo = '90d';

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
    try {
      _empresas = await EmpresaCaller.loadEmpresas();
      _parceiros = await DropdownHelpers.parceiros();
      _empresaId = pegarEmpresaLogada() ?? TenantContext.empresaId;
      _parceiroId = pegarParceiroLogada() ?? TenantContext.parceiroId;
      if (_empresaId == null && _empresas.length == 1) {
        _empresaId = _empresas.first['value'] as int?;
      }
      final empNome = AuthUtility.userInfo?.login?.empresa?.nome ??
          AuthUtility.userInfo?.login?.empresa?.razaoSocial ??
          'Empresa Atual';
      if (_empresaId != null && !_empresas.any((e) => e['value'] == _empresaId)) {
        _empresas.insert(0, {'value': _empresaId, 'label': empNome});
      }
      final parcNome = AuthUtility.userInfo?.login?.parceiro?.nome ??
          AuthUtility.userInfo?.login?.parceiro?.razaoSocial ??
          AuthUtility.userInfo?.login?.nome ??
          'Parceiro Atual';
      if (_parceiroId != null && !_parceiros.any((p) => p['value'] == _parceiroId)) {
        _parceiros.insert(0, {'value': _parceiroId, 'label': parcNome});
      }
      await _loadDashboard();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Nao foi possivel carregar o dashboard comercial.';
      });
    }
  }

  Future<void> _loadDashboard() async {
    final fim = DateTime.now();
    final inicio = fim.subtract(Duration(days: _periodoDias()));
    final data = await DashboardComercialCaller().fetchMercadorias(
      empresaId: _empresaId,
      parceiroId: _parceiroId,
      dataInicio: inicio,
      dataFim: fim,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _dashboard = data ?? DashboardComercialMercadoriasModel.empty();
      _error =
          data == null ? 'Nao foi possivel carregar os indicadores.' : null;
    });
  }

  int _periodoDias() {
    switch (_periodo) {
      case '30d':
        return 30;
      case '180d':
        return 180;
      case '365d':
        return 365;
      case '90d':
      default:
        return 90;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      onRefresh: _loadDashboard,
      color: GridColors.primary,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : _content(),
    );

    if (!widget.showAppBar) {
      return ColoredBox(color: GridColors.background, child: body);
    }

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text('Dashboard Comercial'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }

  Widget _content() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 14),
              _filters(wide),
              const SizedBox(height: 16),
              _cards(wide),
              const SizedBox(height: 16),
              wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _movementChart()),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: _marketCard()),
                      ],
                    )
                  : Column(
                      children: [
                        _movementChart(),
                        const SizedBox(height: 16),
                        _marketCard(),
                      ],
                    ),
              const SizedBox(height: 16),
              _costRanking(),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: GridColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              const Icon(Icons.inventory_2_rounded, color: GridColors.primary),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Comercial',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: GridColors.textSecondary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Entradas, saídas, estoque, giro e variação de custo contra índices de mercado.',
                style: TextStyle(fontSize: 13, color: GridColors.textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Atualizar',
          onPressed: _loadDashboard,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _filters(bool wide) {
    return Container(
      decoration: _panelDecoration(),
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (_empresas.isNotEmpty)
            SizedBox(
              width: wide ? 240 : double.infinity,
              child: DropdownButtonFormField<int>(
                value: _empresaId,
                isExpanded: true,
                decoration: _inputDecoration('Empresa'),
                items: _empresas
                    .map((e) => DropdownMenuItem<int>(
                          value: e['value'] as int?,
                          child: Text(
                            e['label']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: null,
              ),
            ),
          if (_parceiros.isNotEmpty)
            SizedBox(
              width: wide ? 240 : double.infinity,
              child: DropdownButtonFormField<int>(
                value: _parceiroId,
                isExpanded: true,
                decoration: _inputDecoration('Parceiro'),
                items: _parceiros
                    .map((p) => DropdownMenuItem<int>(
                          value: p['value'] as int?,
                          child: Text(
                            p['label']?.toString() ?? p['nome']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: null,
              ),
            ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '30d', label: Text('30 dias')),
              ButtonSegment(value: '90d', label: Text('90 dias')),
              ButtonSegment(value: '180d', label: Text('180 dias')),
              ButtonSegment(value: '365d', label: Text('12 meses')),
            ],
            selected: {_periodo},
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : GridColors.textSecondary,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? GridColors.primary
                    : Colors.white,
              ),
            ),
            onSelectionChanged: (value) {
              setState(() => _periodo = value.first);
              _loadDashboard();
            },
          ),
        ],
      ),
    );
  }

  Widget _cards(bool wide) {
    final cards = [
      _MetricCard(
        title: 'Entradas',
        value: _number.format(_dashboard.quantidadeEntrada),
        subtitle:
            '${_dashboard.notasEntrada} notas | ${_currency.format(_dashboard.valorEntrada)}',
        icon: Icons.call_received_rounded,
        color: GridColors.success,
      ),
      _MetricCard(
        title: 'Saidas',
        value: _number.format(_dashboard.quantidadeSaida),
        subtitle:
            '${_dashboard.notasSaida} notas | ${_currency.format(_dashboard.valorSaida)}',
        icon: Icons.call_made_rounded,
        color: GridColors.error,
      ),
      _MetricCard(
        title: 'Saldo em estoque',
        value: _number.format(_dashboard.saldoEstoque),
        subtitle: _currency.format(_dashboard.valorEstoque),
        icon: Icons.warehouse_rounded,
        color: GridColors.info,
      ),
      _MetricCard(
        title: 'Variacao de custo',
        value: '${_dashboard.variacaoCustoPercentual.toStringAsFixed(2)}%',
        subtitle: 'Media dos produtos com compra recente',
        icon: Icons.price_change_rounded,
        color: _dashboard.variacaoCustoPercentual > 0
            ? GridColors.warning
            : GridColors.success,
      ),
      _MetricCard(
        title: 'Giro do estoque',
        value: '${_dashboard.giroEstoquePercentual.toStringAsFixed(2)}%',
        subtitle: 'Saida sobre saldo atual',
        icon: Icons.sync_alt_rounded,
        color: GridColors.secondary,
      ),
      _MetricCard(
        title: 'Alertas comerciais',
        value:
            '${_dashboard.produtosEstoqueBaixo + _dashboard.produtosParados}',
        subtitle:
            '${_dashboard.produtosEstoqueBaixo} baixo | ${_dashboard.produtosParados} parados',
        icon: Icons.warning_amber_rounded,
        color: GridColors.warning,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 3 : 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: wide ? 2.8 : 3.8,
      ),
      itemBuilder: (_, index) => cards[index],
    );
  }

  Widget _movementChart() {
    final serie = _dashboard.serieMercadorias;
    final maxValue = serie.fold<double>(
      1,
      (max, item) =>
          math.max(max, math.max(item.valorEntrada, item.valorSaida)),
    );
    return Container(
      decoration: _panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entrada x Saida de Mercadorias',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (serie.isEmpty)
            _emptyBox('Sem movimentacao de mercadorias no periodo.')
          else
            SizedBox(
              height: 260,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: serie.map((item) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _bar(item.valorEntrada / maxValue,
                                    GridColors.success),
                                const SizedBox(width: 5),
                                _bar(item.valorSaida / maxValue,
                                    GridColors.error),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.periodo,
                            style: const TextStyle(
                                fontSize: 11, color: GridColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legend(GridColors.success, 'Entradas'),
              const SizedBox(width: 14),
              _legend(GridColors.error, 'Saidas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(double percent, Color color) {
    return Flexible(
      child: FractionallySizedBox(
        heightFactor: percent.clamp(0.04, 1),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 28),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  Widget _marketCard() {
    return Container(
      decoration: _panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Indices de Mercado',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'IPA/FGV e IGP-M ajudam a medir pressao de custo em mercadorias.',
            style: TextStyle(fontSize: 12, color: GridColors.textMuted),
          ),
          const SizedBox(height: 12),
          ..._dashboard.indicesMercado.map((indice) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GridColors.filterBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GridColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              indice.nome,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${indice.descricao} | ${indice.referencia}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: GridColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${indice.mensalPercentual.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: indice.mensalPercentual >= 0
                                  ? GridColors.error
                                  : GridColors.success,
                            ),
                          ),
                          Text(
                            '${indice.acumulado12mPercentual.toStringAsFixed(2)}% 12m',
                            style: const TextStyle(
                              fontSize: 11,
                              color: GridColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _costRanking() {
    final itens = _dashboard.produtosVariacaoCusto;
    return Container(
      decoration: _panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produtos com maior variacao de custo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (itens.isEmpty)
            _emptyBox(
                'Sem compras comparaveis para calcular variacao de custo.')
          else
            ...itens.map((produto) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          produto.nome,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          produto.ncm.isEmpty ? '-' : produto.ncm,
                          style: const TextStyle(color: GridColors.textMuted),
                        ),
                      ),
                      Expanded(
                        child: Text(_currency.format(produto.custoAnterior)),
                      ),
                      Expanded(
                        child: Text(_currency.format(produto.custoAtual)),
                      ),
                      SizedBox(
                        width: 92,
                        child: Text(
                          '${produto.variacaoPercentual.toStringAsFixed(2)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: produto.variacaoPercentual >= 0
                                ? GridColors.error
                                : GridColors.success,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 12),
      decoration: BoxDecoration(
        color: GridColors.filterBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: GridColors.textMuted),
      ),
    );
  }

  Widget _errorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 42, color: GridColors.error),
        const SizedBox(height: 12),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: GridColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, color: GridColors.textMuted)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor:
          _parceiroId == null ? Colors.white : GridColors.filterBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: GridColors.card,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: GridColors.divider),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GridColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: GridColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: GridColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
