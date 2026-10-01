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

class WebDashboardFinanceiroScreen extends StatefulWidget {
  final bool showAppBar;

  const WebDashboardFinanceiroScreen({
    super.key,
    this.showAppBar = false,
  });

  @override
  State<WebDashboardFinanceiroScreen> createState() =>
      _WebDashboardFinanceiroScreenState();
}

class _WebDashboardFinanceiroScreenState
    extends State<WebDashboardFinanceiroScreen> {
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

  // KPIs adicionais do endpoint /kpis
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
          _error = 'Nenhum dado encontrado para o filtro selecionado.';
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

        // KPIs do endpoint /kpis com fallback para campos do dashboard
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
      String label = e['semana']?.toString() ?? e['label']?.toString() ?? '';
      if (label.isEmpty && e['data'] != null) {
        final dStr = e['data'].toString();
        if (dStr.length >= 10) {
          final parts = dStr.substring(0, 10).split('-');
          if (parts.length == 3) {
            label = '${parts[2]}/${parts[1]}';
          } else {
            label = dStr;
          }
        } else {
          label = dStr;
        }
      }
      return _FluxoItem(
        label,
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
    final body = Container(
      color: GridColors.background,
      child: _buildBody(),
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: GridColors.background,
        appBar: AppBar(
          title: const Text('Dashboard Financeiro'),
          backgroundColor: GridColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: GridColors.background,
      body: body,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: GridColors.primary,
        ),
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
                decoration: BoxDecoration(
                  color: GridColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: GridColors.error,
                  size: 40,
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFiltrosCard(),
          const SizedBox(height: 20),
          _buildKpiGrid(),
          const SizedBox(height: 24),
          SaudeFinanceiraSection(model: _saudeFinanceira),
          const SizedBox(height: 24),
          _buildChartsRow(),
          const SizedBox(height: 24),
          _buildPieChartsRow(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: GridColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.dashboard_customize_rounded,
            color: GridColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Financeiro',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: GridColors.textSecondary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Visão analítica gerencial de receitas, despesas e fluxo de caixa',
              style: TextStyle(
                fontSize: 13,
                color: GridColors.textMuted,
              ),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _loading ? null : _loadDashboard,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Atualizar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: GridColors.textSecondary,
            side: const BorderSide(color: GridColors.divider),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltrosCard() {
    final periodos = [
      {'label': '7 dias', 'value': '7d'},
      {'label': '30 dias', 'value': '30d'},
      {'label': '90 dias', 'value': '90d'},
      {'label': '12 meses', 'value': '12m'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 18, color: GridColors.textMuted),
              const SizedBox(width: 8),
              const Text(
                'Filtros e Parâmetros',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: GridColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (_empresaId != null || _contaBancariaId != null || _dataInicio != null || _dataFim != null)
                TextButton.icon(
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
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: const Text('Limpar filtros'),
                  style: TextButton.styleFrom(
                    foregroundColor: GridColors.error,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_empresas.isNotEmpty)
                _dropdown(
                  value: _empresaId,
                  items: _empresas,
                  hint: 'Empresa',
                  enabled: false,
                  onChanged: (v) {
                    _empresaId = v;
                    _loadDashboard();
                  },
                ),
              if (_parceiros.isNotEmpty)
                _dropdown(
                  value: _parceiroId,
                  items: _parceiros,
                  hint: 'Parceiro',
                  enabled: false,
                  onChanged: (v) {
                    _parceiroId = v;
                    _loadDashboard();
                  },
                ),
              if (_contasBancarias.isNotEmpty)
                _dropdown(
                  value: _contaBancariaId,
                  items: _contasBancarias,
                  hint: 'Conta Bancária',
                  onChanged: (v) {
                    _contaBancariaId = v;
                    _loadDashboard();
                  },
                ),
              _dateField(
                label: 'Data Início',
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
              _dateField(
                label: 'Data Fim',
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
              Container(
                height: 32,
                width: 1,
                color: GridColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              // Chips de Período
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Período: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GridColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ...periodos.map((p) {
                    final isSelected = _periodoFilter == p['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(p['label']!),
                        selected: isSelected,
                        selectedColor: GridColors.primary,
                        backgroundColor: GridColors.filterBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
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
                  }),
                ],
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
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<int>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: const TextStyle(fontSize: 13, color: GridColors.textMuted),
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: GridColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        items: [
          DropdownMenuItem<int>(
            value: null,
            child: Text('Todas',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          ...items.map((e) => DropdownMenuItem<int>(
                value: e['value'] as int?,
                child: Text(
                  e['label']?.toString() ?? '',
                  style: const TextStyle(fontSize: 13, color: GridColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              )),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? selected,
    required ValueChanged<DateTime?> onPick,
    required VoidCallback onClear,
  }) {
    return SizedBox(
      width: 170,
      child: InkWell(
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
            labelStyle: const TextStyle(fontSize: 13, color: GridColors.textMuted),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: GridColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            suffixIcon: selected != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: onClear,
                  )
                : const Icon(Icons.calendar_today_outlined, size: 16, color: GridColors.textMuted),
          ),
          child: Text(
            selected != null
                ? DateFormat('dd/MM/yyyy').format(selected)
                : 'Selecionar',
            style: TextStyle(
              fontSize: 13,
              color: selected != null ? GridColors.textSecondary : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final count = isWide ? 4 : 2;

        return Column(
          children: [
            // Linha 1: Principais (Saldo Projetado, A Receber, A Pagar, Vencido)
            GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isWide ? 2.3 : 1.9,
              children: [
                _buildKpiCard(
                  title: 'Saldo Projetado',
                  valor: _saldoProjetado,
                  icon: Icons.account_balance_rounded,
                  accentColor: GridColors.info,
                  subtitle: 'Previsão com lançamentos futuros',
                ),
                _buildKpiCard(
                  title: 'A Receber',
                  valor: _aReceber,
                  icon: Icons.arrow_downward_rounded,
                  accentColor: GridColors.success,
                  subtitle: 'Títulos pendentes de entrada',
                ),
                _buildKpiCard(
                  title: 'A Pagar',
                  valor: _aPagar,
                  icon: Icons.arrow_upward_rounded,
                  accentColor: GridColors.error,
                  subtitle: 'Obrigações e despesas futuras',
                ),
                _buildKpiCard(
                  title: 'Total Vencido',
                  valor: _totalVencido,
                  icon: Icons.warning_amber_rounded,
                  accentColor: GridColors.warning,
                  subtitle: 'Títulos em atraso',
                  isWarning: _totalVencido > 0,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Linha 2: Indicadores Secundários (Saldo em Conta, Entradas, Saídas, Inadimplência)
            GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isWide ? 2.6 : 2.1,
              children: [
                _buildMiniKpiCard(
                  title: 'Saldo Bancário Consolidado',
                  valor: _kpiSaldo,
                  icon: Icons.account_balance_wallet_outlined,
                  color: GridColors.info,
                ),
                _buildMiniKpiCard(
                  title: 'Entradas Realizadas',
                  valor: _kpiEntradas,
                  icon: Icons.trending_up_rounded,
                  color: GridColors.success,
                ),
                _buildMiniKpiCard(
                  title: 'Saídas Realizadas',
                  valor: _kpiSaidas,
                  icon: Icons.trending_down_rounded,
                  color: GridColors.error,
                ),
                _buildMiniKpiCard(
                  title: 'Inadimplência',
                  valor: _kpiInadimplencia,
                  icon: Icons.report_problem_outlined,
                  color: GridColors.warning,
                  isPercentual: true,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required double valor,
    required IconData icon,
    required Color accentColor,
    required String subtitle,
    bool isWarning = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? GridColors.warning.withValues(alpha: 0.5) : GridColors.divider,
          width: isWarning ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: GridColors.textMuted,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _currency.format(valor),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: valor < 0 ? GridColors.error : GridColors.textSecondary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isWarning ? GridColors.warningDark : GridColors.textMuted,
              fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKpiCard({
    required String title,
    required double valor,
    required IconData icon,
    required Color color,
    bool isPercentual = false,
  }) {
    final valorFormatado = isPercentual ? '${valor.toStringAsFixed(1)}%' : _currency.format(valor);

    return Container(
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GridColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: GridColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  valorFormatado,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide && _projecao.isNotEmpty) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFluxoChartCard()),
              const SizedBox(width: 20),
              Expanded(child: _buildProjecaoChartCard()),
            ],
          );
        }

        return Column(
          children: [
            _buildFluxoChartCard(),
            if (_projecao.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildProjecaoChartCard(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFluxoChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 20, color: GridColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Fluxo de Caixa Projetado',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: GridColors.textSecondary,
                ),
              ),
              const Spacer(),
              _legenda(GridColors.success, 'Entradas'),
              const SizedBox(width: 14),
              _legenda(GridColors.error, 'Saídas'),
            ],
          ),
          const SizedBox(height: 20),
          if (_fluxo.isEmpty)
            Container(
              height: 240,
              alignment: Alignment.center,
              child: const Text(
                'Nenhum dado de fluxo para o período selecionado.',
                style: TextStyle(color: GridColors.textMuted),
              ),
            )
          else
            SizedBox(
              height: 240,
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
                          const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: GridColors.divider.withValues(alpha: 0.6),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 68,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) return const SizedBox.shrink();
                          return Text(
                            _formatK(value),
                            style: const TextStyle(fontSize: 10, color: GridColors.textMuted),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= _fluxo.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _fluxo[i].semana,
                              style: const TextStyle(fontSize: 11, color: GridColors.textSecondary, fontWeight: FontWeight.w600),
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
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: math.max(item.entrada, 0),
                          color: GridColors.success,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: math.max(item.saida, 0),
                          color: GridColors.error,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
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
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: 20, color: GridColors.info),
              const SizedBox(width: 8),
              const Text(
                'Projeção de Saldo (Próximos Meses)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: GridColors.textSecondary,
                ),
              ),
              const Spacer(),
              _legenda(GridColors.info, 'Saldo Previsto'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: GridColors.divider.withValues(alpha: 0.6),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 68,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatK(value),
                          style: const TextStyle(fontSize: 10, color: GridColors.textMuted),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _projecao.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _projecao[i].mes,
                            style: const TextStyle(fontSize: 11, color: GridColors.textSecondary, fontWeight: FontWeight.w600),
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
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: GridColors.info.withValues(alpha: 0.12),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeColor: GridColors.info,
                        strokeWidth: 2.5,
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
                          const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildPieChartsRow() {
    if (_categorias.isEmpty && _topParceiros.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_categorias.isNotEmpty)
                Expanded(
                  child: _buildDonutChartCard(
                    title: 'Despesas por Categoria',
                    icon: Icons.pie_chart_outline_rounded,
                    data: _categorias.map((c) => _PieData(c.nome, c.valor)).toList(),
                  ),
                ),
              if (_categorias.isNotEmpty && _topParceiros.isNotEmpty)
                const SizedBox(width: 20),
              if (_topParceiros.isNotEmpty)
                Expanded(
                  child: _buildDonutChartCard(
                    title: 'Top Parceiros / Clientes',
                    icon: Icons.groups_outlined,
                    data: _topParceiros.map((p) => _PieData(p.nome, p.valor)).toList(),
                  ),
                ),
            ],
          );
        }

        return Column(
          children: [
            if (_categorias.isNotEmpty)
              _buildDonutChartCard(
                title: 'Despesas por Categoria',
                icon: Icons.pie_chart_outline_rounded,
                data: _categorias.map((c) => _PieData(c.nome, c.valor)).toList(),
              ),
            if (_categorias.isNotEmpty && _topParceiros.isNotEmpty)
              const SizedBox(height: 20),
            if (_topParceiros.isNotEmpty)
              _buildDonutChartCard(
                title: 'Top Parceiros / Clientes',
                icon: Icons.groups_outlined,
                data: _topParceiros.map((p) => _PieData(p.nome, p.valor)).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDonutChartCard({
    required String title,
    required IconData icon,
    required List<_PieData> data,
  }) {
    final total = data.fold<double>(0, (s, d) => s + d.valor);
    if (total <= 0) return const SizedBox.shrink();

    final colors = [
      const Color(0xFF1976D2), // Blue
      const Color(0xFF93070A), // Primary Red
      const Color(0xFF005826), // Secondary Green
      const Color(0xFFE65100), // Orange
      const Color(0xFF6A1B9A), // Purple
      const Color(0xFF00838F), // Teal
      const Color(0xFFD81B60), // Pink
      const Color(0xFFF57F17), // Amber
    ];

    return Container(
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: GridColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: GridColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${_currency.format(total)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: GridColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: data.take(8).toList().asMap().entries.map((e) {
                      final i = e.key;
                      final d = e.value;
                      final pct = (d.valor / total) * 100;
                      return PieChartSectionData(
                        value: d.valor,
                        showTitle: false,
                        color: colors[i % colors.length],
                        radius: 26,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.take(6).toList().asMap().entries.map((e) {
                    final i = e.key;
                    final d = e.value;
                    final pct = (d.valor / total) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.nome,
                              style: const TextStyle(
                                fontSize: 12,
                                color: GridColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: GridColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currency.format(d.valor),
                            style: const TextStyle(
                              fontSize: 12,
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
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
