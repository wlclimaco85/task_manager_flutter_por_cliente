import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/auth_utility.dart';
import '../../models/saude_financeira_model.dart';
import '../../services/conta_bancaria_caller.dart';
import '../../services/dashboard_financeiro_caller.dart';
import '../../services/empresa_caller.dart';
import '../../utils/dropdown_helpers.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../../utils/utils.dart';
import '../../widgets/finance/saude_financeira_section.dart';

/// Dashboard Financeiro para Mobile com visual moderno, responsivo e limpo
class DashboardFinanceiroMobileScreen extends StatefulWidget {
  const DashboardFinanceiroMobileScreen({super.key});

  @override
  State<DashboardFinanceiroMobileScreen> createState() =>
      _DashboardFinanceiroMobileScreenState();
}

class _DashboardFinanceiroMobileScreenState
    extends State<DashboardFinanceiroMobileScreen> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _parceiros = [];
  List<Map<String, dynamic>> _contasBancarias = [];

  int? _empresaId;
  int? _parceiroId;
  int? _contaBancariaId;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  double _aPagar = 0;
  double _aReceber = 0;
  double _saldoProjetado = 0;
  double _totalVencido = 0;

  List<_FluxoItem> _fluxo = [];
  List<_CategoriaItem> _categorias = [];
  List<_ParceiroItem> _topParceiros = [];

  // KPIs adicionais
  double _kpiSaldo = 0;
  double _kpiEntradas = 0;
  double _kpiSaidas = 0;
  double _kpiInadimplencia = 0;

  // Projeção
  List<_ProjecaoItem> _projecao = [];

  // Filtro período rápido
  String _periodoFilter = '30d';

  SaudeFinanceiraModel get _saudeFinanceira => SaudeFinanceiraModel.calcular(
        saldoAtual: _kpiSaldo != 0 ? _kpiSaldo : _saldoProjetado,
        aReceber: _aReceber,
        aPagar: _aPagar,
        receitasMes: _kpiEntradas,
        despesasMes: _kpiSaidas,
        inadimplenciaPerc: _kpiInadimplencia,
      );

  // Toggle do card de filtros para economizar espaço de tela touch
  bool _filtrosAbertos = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    _empresas = await EmpresaCaller.loadEmpresas();
    _parceiros = await DropdownHelpers.parceiros();
    _contasBancarias = await ContaBancariaCaller.loadContas();
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
    if (!mounted) return;
    setState(() {});
    await _loadDashboard();
  }

  int? _getDiasFromPeriodo() {
    switch (_periodoFilter) {
      case '7d':
        return 7;
      case '30d':
        return 30;
      case '90d':
        return 90;
      case '12m':
        return 365;
      default:
        return null;
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      DateTime? effectiveDataInicio = _dataInicio;
      DateTime? effectiveDataFim = _dataFim;
      final dias = _getDiasFromPeriodo();
      if (effectiveDataInicio == null && dias != null && dias > 0) {
        effectiveDataFim = effectiveDataFim ?? DateTime.now();
        effectiveDataInicio = effectiveDataFim.subtract(Duration(days: dias));
      }

      final results = await Future.wait([
        DashboardFinanceiroCaller().obterDashboard(
          empresaId: _empresaId,
          parceiroId: _parceiroId,
          contaBancariaId: _contaBancariaId,
          dataInicio: effectiveDataInicio?.toIso8601String().split('T').first,
          dataFim: effectiveDataFim?.toIso8601String().split('T').first,
        ),
        DashboardFinanceiroCaller().obterKpis(
          empresaId: _empresaId,
          parceiroId: _parceiroId,
          dias: dias,
        ),
      ]);

      final projecaoRaw = await DashboardFinanceiroCaller().obterProjecao(
        empresaId: _empresaId,
        parceiroId: _parceiroId,
      );

      if (!mounted) return;

      final data = results[0];
      final kpisData = results[1];

      if (data.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Nenhum dado encontrado para o filtro.';
        });
        return;
      }

      final body = (data['data'] is Map ? data['data'] : data) as Map;

      setState(() {
        _aPagar = _toDouble(body['aPagar'] ?? body['totalAPagar'] ?? 0);
        _aReceber = _toDouble(body['aReceber'] ?? body['totalAReceber'] ?? 0);
        _saldoProjetado =
            _toDouble(body['saldoProjetado'] ?? body['saldo'] ?? 0);
        _totalVencido =
            _toDouble(body['totalVencido'] ?? body['vencido'] ?? 0);

        _kpiSaldo = _toDouble(kpisData['saldoAtual'] ??
            kpisData['saldoProjetado'] ??
            body['saldoAtual'] ??
            _saldoProjetado);
        _kpiEntradas = _toDouble(kpisData['totalEntradas'] ??
            kpisData['totalRecebido'] ??
            body['totalRecebido'] ??
            body['totalEntradas'] ??
            0);
        _kpiSaidas = _toDouble(kpisData['totalSaidas'] ??
            kpisData['totalPago'] ??
            body['totalPago'] ??
            body['totalSaidas'] ??
            0);
        _kpiInadimplencia = _toDouble(kpisData['inadimplencia'] ?? 0);

        _fluxo = _parseFluxo(body['fluxoCaixaProjetado'] ?? body['fluxo'] ?? []);
        _categorias = _parseCategorias(
            body['categorias'] ?? body['categoriasFinanceiras'] ?? []);
        _topParceiros = _parseParceiros(
            body['topParceiros'] ?? body['topClientes'] ?? body['topFornecedores'] ?? []);
        _projecao = _parseProjecaoList(projecaoRaw);

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erro ao carregar dashboard: $e';
      });
    }
  }

  double _toDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  List<_FluxoItem> _parseFluxo(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) {
      if (e is! Map) return _FluxoItem('', 0, 0);
      return _FluxoItem(
        e['semana']?.toString() ?? e['label']?.toString() ?? '',
        _toDouble(e['entrada'] ?? e['receber'] ?? 0),
        _toDouble(e['saida'] ?? e['pagar'] ?? 0),
      );
    }).toList();
  }

  List<_CategoriaItem> _parseCategorias(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) {
      if (e is! Map) return _CategoriaItem('', 0);
      return _CategoriaItem(
        e['nome']?.toString() ?? e['descricao']?.toString() ?? '',
        _toDouble(e['valor'] ?? 0),
      );
    }).toList();
  }

  List<_ParceiroItem> _parseParceiros(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) {
      if (e is! Map) return _ParceiroItem('', 0);
      return _ParceiroItem(
        e['nome']?.toString() ?? '',
        _toDouble(e['valor'] ?? e['total'] ?? 0),
      );
    }).toList();
  }

  List<_ProjecaoItem> _parseProjecaoList(List<dynamic> raw) {
    return raw.map((e) {
      if (e is! Map) return _ProjecaoItem('', 0, 0);
      return _ProjecaoItem(
        e['mes']?.toString() ?? e['label']?.toString() ?? '',
        _toDouble(e['saldoPrevisto'] ?? e['saldo'] ?? 0),
        _toDouble(e['entradasPrevistas'] ?? e['acumulado'] ?? 0),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text('Dashboard Financeiro'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _filtrosAbertos ? Icons.filter_alt_off_rounded : Icons.filter_alt_outlined,
              color: Colors.white,
            ),
            tooltip: 'Filtros',
            onPressed: () {
              setState(() => _filtrosAbertos = !_filtrosAbertos);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _loadDashboard,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: GridColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: GridColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: GridColors.error, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tentar novamente'),
                style: FilledButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodoSelector(),
          if (_filtrosAbertos) ...[
            const SizedBox(height: 10),
            _buildFiltrosExpansion(),
          ],
          const SizedBox(height: 14),
          _buildHeroSaldoCard(),
          const SizedBox(height: 14),
          _buildKpisGrid(),
          const SizedBox(height: 14),
          _buildSecondaryKpisRow(),
          const SizedBox(height: 16),
          SaudeFinanceiraSection(
            model: _saudeFinanceira,
            isCompact: true,
          ),
          const SizedBox(height: 16),
          _buildFluxoChartCard(),
          if (_projecao.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildProjecaoChartCard(),
          ],
          if (_categorias.isNotEmpty || _topParceiros.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPieChartsSection(),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPeriodoSelector() {
    final periodos = [
      {'label': '7 dias', 'value': '7d'},
      {'label': '30 dias', 'value': '30d'},
      {'label': '90 dias', 'value': '90d'},
      {'label': '12 meses', 'value': '12m'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periodos.map((p) {
          final isSelected = _periodoFilter == p['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p['label']!),
              selected: isSelected,
              selectedColor: GridColors.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? GridColors.primary : GridColors.divider,
                ),
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : GridColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              onSelected: (v) {
                setState(() => _periodoFilter = p['value']!);
                _loadDashboard();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFiltrosExpansion() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 16, color: GridColors.textMuted),
              const SizedBox(width: 6),
              const Text(
                'Filtros avançados',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: GridColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _empresaId = pegarEmpresaLogada();
                    _parceiroId = pegarParceiroLogada();
                    _contaBancariaId = null;
                    _dataInicio = null;
                    _dataFim = null;
                  });
                  _loadDashboard();
                },
                style: TextButton.styleFrom(
                  foregroundColor: GridColors.error,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Limpar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_empresas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _dropdown(
                value: _empresaId,
                items: _empresas,
                hint: 'Empresa',
                enabled: false,
                onChanged: (v) {
                  _empresaId = v;
                  _loadDashboard();
                },
              ),
            ),
          if (_parceiros.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _dropdown(
                value: _parceiroId,
                items: _parceiros,
                hint: 'Parceiro',
                enabled: false,
                onChanged: (v) {
                  _parceiroId = v;
                  _loadDashboard();
                },
              ),
            ),
          if (_contasBancarias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _dropdown(
                value: _contaBancariaId,
                items: _contasBancarias,
                hint: 'Conta Bancária',
                onChanged: (v) {
                  _contaBancariaId = v;
                  _loadDashboard();
                },
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'Início',
                  selected: _dataInicio,
                  onPick: (d) {
                    _dataInicio = d;
                    _loadDashboard();
                  },
                  onClear: () {
                    _dataInicio = null;
                    _loadDashboard();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dateField(
                  label: 'Fim',
                  selected: _dataFim,
                  onPick: (d) {
                    _dataFim = d;
                    _loadDashboard();
                  },
                  onClear: () {
                    _dataFim = null;
                    _loadDashboard();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required String hint,
    required ValueChanged<int?> onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(fontSize: 12, color: GridColors.textMuted),
        isDense: true,
        filled: true,
        fillColor: enabled ? Colors.white : GridColors.filterBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GridColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GridColors.divider),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: [
        DropdownMenuItem<int>(
          value: null,
          child: Text('Todas',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
        ...items.map((e) => DropdownMenuItem<int>(
              value: e['value'] as int?,
              child: Text(e['label']?.toString() ?? '',
                  style: const TextStyle(fontSize: 13, color: GridColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? selected,
    required ValueChanged<DateTime?> onPick,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: GridColors.primary,
                  onPrimary: Colors.white,
                  onSurface: GridColors.textSecondary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: GridColors.textMuted),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: GridColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: GridColors.divider),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          suffixIcon: selected != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 14),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Text(
          selected != null
              ? DateFormat('dd/MM/yyyy').format(selected)
              : 'Selecionar',
          style: TextStyle(
            fontSize: 12,
            color: selected != null ? GridColors.textSecondary : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSaldoCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GridColors.primary,
            GridColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: GridColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Projetado',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _currency.format(_kpiSaldo),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currency.format(_saldoProjetado),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Considera saldo bancário e títulos previstos',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpisGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _buildCompactKpiCard(
          title: 'A Receber',
          valor: _aReceber,
          icon: Icons.arrow_downward_rounded,
          color: GridColors.success,
        ),
        _buildCompactKpiCard(
          title: 'A Pagar',
          valor: _aPagar,
          icon: Icons.arrow_upward_rounded,
          color: GridColors.error,
        ),
        _buildCompactKpiCard(
          title: 'Total Vencido',
          valor: _totalVencido,
          icon: Icons.warning_amber_rounded,
          color: GridColors.warning,
          isWarning: _totalVencido > 0,
        ),
        _buildCompactKpiCard(
          title: 'Inadimplência',
          valor: _kpiInadimplencia,
          icon: Icons.percent_rounded,
          color: GridColors.warning,
          isPercentual: true,
        ),
      ],
    );
  }

  Widget _buildCompactKpiCard({
    required String title,
    required double valor,
    required IconData icon,
    required Color color,
    bool isWarning = false,
    bool isPercentual = false,
  }) {
    final formatado = isPercentual ? '${valor.toStringAsFixed(1)}%' : _currency.format(valor);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? GridColors.warning.withValues(alpha: 0.6) : GridColors.divider,
          width: isWarning ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GridColors.textMuted,
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatado,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: valor < 0 ? GridColors.error : GridColors.textSecondary,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryKpisRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GridColors.divider),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: GridColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.trending_up_rounded, size: 16, color: GridColors.success),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Entradas', style: TextStyle(fontSize: 10, color: GridColors.textMuted)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _currency.format(_kpiEntradas),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GridColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GridColors.divider),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: GridColors.errorLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.trending_down_rounded, size: 16, color: GridColors.error),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saídas', style: TextStyle(fontSize: 10, color: GridColors.textMuted)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _currency.format(_kpiSaidas),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GridColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFluxoChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 18, color: GridColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Fluxo de Caixa',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: GridColors.textSecondary,
                ),
              ),
              const Spacer(),
              _legenda(GridColors.success, 'Entradas'),
              const SizedBox(width: 8),
              _legenda(GridColors.error, 'Saídas'),
            ],
          ),
          const SizedBox(height: 14),
          if (_fluxo.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: const Text('Sem movimentações no período.',
                  style: TextStyle(color: GridColors.textMuted, fontSize: 12)),
            )
          else
            SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _fluxoMaxY(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gIndex, rod, rIndex) {
                        final item = _fluxo[gIndex];
                        final label = rIndex == 0 ? 'Entrada' : 'Saída';
                        return BarTooltipItem(
                          '${item.semana}\n$label: ${_currency.format(rod.toY)}',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: GridColors.divider.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) return const SizedBox.shrink();
                          return Text(
                            _formatK(value),
                            style: const TextStyle(fontSize: 9, color: GridColors.textMuted),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= _fluxo.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _fluxo[i].semana,
                              style: const TextStyle(fontSize: 10, color: GridColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _fluxo.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: math.max(item.entrada, 0),
                          color: GridColors.success,
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                        BarChartRodData(
                          toY: math.max(item.saida, 0),
                          color: GridColors.error,
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjecaoChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: 18, color: GridColors.info),
              const SizedBox(width: 6),
              const Text(
                'Projeção de Saldo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: GridColors.textSecondary,
                ),
              ),
              const Spacer(),
              _legenda(GridColors.info, 'Saldo Previsto'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: GridColors.divider.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatK(value),
                          style: const TextStyle(fontSize: 9, color: GridColors.textMuted),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _projecao.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _projecao[i].mes,
                            style: const TextStyle(fontSize: 10, color: GridColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _projecao.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.saldo);
                    }).toList(),
                    isCurved: true,
                    color: GridColors.info,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: GridColors.info.withValues(alpha: 0.12),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeColor: GridColors.info,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final item = _projecao[spot.x.toInt()];
                        return LineTooltipItem(
                          '${item.mes}\nSaldo: ${_currency.format(item.saldo)}',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartsSection() {
    return Column(
      children: [
        if (_categorias.isNotEmpty)
          _buildMobileDonutCard(
            title: 'Despesas por Categoria',
            icon: Icons.pie_chart_outline_rounded,
            data: _categorias.map((c) => _PieData(c.nome, c.valor)).toList(),
          ),
        if (_categorias.isNotEmpty && _topParceiros.isNotEmpty)
          const SizedBox(height: 14),
        if (_topParceiros.isNotEmpty)
          _buildMobileDonutCard(
            title: 'Top Parceiros / Clientes',
            icon: Icons.groups_outlined,
            data: _topParceiros.map((p) => _PieData(p.nome, p.valor)).toList(),
          ),
      ],
    );
  }

  Widget _buildMobileDonutCard({
    required String title,
    required IconData icon,
    required List<_PieData> data,
  }) {
    final total = data.fold<double>(0, (s, d) => s + d.valor);
    if (total <= 0) return const SizedBox.shrink();

    final colors = [
      const Color(0xFF1976D2),
      const Color(0xFF93070A),
      const Color(0xFF005826),
      const Color(0xFFE65100),
      const Color(0xFF6A1B9A),
      const Color(0xFF00838F),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: GridColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: GridColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${_currency.format(total)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: GridColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                    sections: data.take(6).toList().asMap().entries.map((e) {
                      final i = e.key;
                      final d = e.value;
                      return PieChartSectionData(
                        value: d.valor,
                        showTitle: false,
                        color: colors[i % colors.length],
                        radius: 20,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.take(4).toList().asMap().entries.map((e) {
                    final i = e.key;
                    final d = e.value;
                    final pct = (d.valor / total) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              d.nome,
                              style: const TextStyle(
                                fontSize: 11,
                                color: GridColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 10,
                              color: GridColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currency.format(d.valor),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: GridColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _fluxoMaxY() {
    double max = 0;
    for (final f in _fluxo) {
      if (f.entrada > max) max = f.entrada;
      if (f.saida > max) max = f.saida;
    }
    return max <= 0 ? 1000 : max * 1.25;
  }

  String _formatK(double value) {
    if (value.abs() >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)}k';
    }
    return 'R\$ ${value.toStringAsFixed(0)}';
  }

  Widget _legenda(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: GridColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FluxoItem {
  final String semana;
  final double entrada;
  final double saida;
  _FluxoItem(this.semana, this.entrada, this.saida);
}

class _CategoriaItem {
  final String nome;
  final double valor;
  _CategoriaItem(this.nome, this.valor);
}

class _ParceiroItem {
  final String nome;
  final double valor;
  _ParceiroItem(this.nome, this.valor);
}

class _PieData {
  final String nome;
  final double valor;
  _PieData(this.nome, this.valor);
}

class _ProjecaoItem {
  final String mes;
  final double saldo;
  final double acumulado;
  _ProjecaoItem(this.mes, this.saldo, this.acumulado);
}
