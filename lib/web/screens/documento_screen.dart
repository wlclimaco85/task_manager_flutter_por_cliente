// ignore_for_file: library_private_types_in_public_api
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:intl/intl.dart';
import '../../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/anexo_financeiro_widget.dart';
import '../../../widgets/boleto_viewer_widget.dart';
import '../../../services/anexo_financeiro_service.dart';
import '../../../utils/document_baixa_helper.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../models/conta_receber_model.dart';
import 'baixa_dialog.dart';
import 'baixa_dialog_receber.dart';

// ─── Internal data models ────────────────────────────────────────────────────

class _DayMarkers {
  final bool hasPagar;
  final bool hasReceber;
  final bool hasPago;
  final bool hasRecebido;
  final bool hasTributo;
  const _DayMarkers({
    this.hasPagar = false,
    this.hasReceber = false,
    this.hasPago = false,
    this.hasRecebido = false,
    this.hasTributo = false,
  });
}

class _MonthSummary {
  final double totalPagar;
  final double totalPago;
  final double totalReceber;
  final double totalRecebido;
  final double saldoPagar;
  final double saldoReceber;
  const _MonthSummary({
    this.totalPagar = 0,
    this.totalPago = 0,
    this.totalReceber = 0,
    this.totalRecebido = 0,
    this.saldoPagar = 0,
    this.saldoReceber = 0,
  });
}

class _FinancialItems {
  final List<Map<String, dynamic>> pagar;
  final List<Map<String, dynamic>> receber;
  final List<Map<String, dynamic>> unknown;

  const _FinancialItems({
    this.pagar = const [],
    this.receber = const [],
    this.unknown = const [],
  });

  List<Map<String, dynamic>> get all => [...pagar, ...receber, ...unknown];

  List<Map<String, dynamic>> byTipo(String tipo) {
    final upper = tipo.toUpperCase();
    if (upper == 'PAGAR') return pagar.isNotEmpty ? pagar : unknown;
    if (upper == 'RECEBER') return receber.isNotEmpty ? receber : unknown;
    return all;
  }
}

class _MiniWeekday extends StatelessWidget {
  final String label;

  const _MiniWeekday(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: GridColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Parsing functions (top-level) ────────────────────────────────────────────

_FinancialItems _parseFinancialGroups(dynamic body) {
  try {
    dynamic cursor = body;
    while (cursor is Map && cursor.containsKey('data')) {
      cursor = cursor['data'];
    }

    final pagar = <Map<String, dynamic>>[];
    final receber = <Map<String, dynamic>>[];
    final unknown = <Map<String, dynamic>>[];

    if (cursor is Map) {
      for (final key in const [
        'contasPagar',
        'contasAPagar',
        'contas_a_pagar',
        'pagar',
        'aPagar',
        'payables',
      ]) {
        pagar.addAll(_collectFinancialMaps(cursor[key], tipo: 'PAGAR'));
      }
      for (final key in const [
        'contasReceber',
        'contasAReceber',
        'contas_a_receber',
        'receber',
        'aReceber',
        'receivables',
      ]) {
        receber.addAll(_collectFinancialMaps(cursor[key], tipo: 'RECEBER'));
      }
      if (pagar.isNotEmpty || receber.isNotEmpty) {
        return _FinancialItems(pagar: pagar, receber: receber);
      }

      for (final key in const [
        'dados',
        'content',
        'items',
        'results',
        'lista'
      ]) {
        final value = cursor[key];
        if (value is List) {
          unknown.addAll(_collectFinancialMaps(value));
          break;
        } else if (value is Map) {
          final nested = _parseFinancialGroups(value);
          if (nested.all.isNotEmpty) return nested;
        }
      }
    }
    if (cursor is List) {
      unknown.addAll(_collectFinancialMaps(cursor));
    }

    if (unknown.isNotEmpty) {
      return _splitFinancialItems(unknown);
    }
  } catch (_) {}
  return const _FinancialItems();
}

List<Map<String, dynamic>> _collectFinancialMaps(dynamic value,
    {String? tipo}) {
  final result = <Map<String, dynamic>>[];
  if (value is List) {
    for (final item in value.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      if (tipo != null && !_hasTipo(map)) {
        map['_calendarioTipo'] = tipo;
      }
      result.add(map);
    }
  } else if (value is Map) {
    for (final key in const ['dados', 'content', 'items', 'results', 'lista']) {
      result.addAll(_collectFinancialMaps(value[key], tipo: tipo));
    }
    for (final key in const ['abertas', 'baixadas', 'pagas', 'recebidas']) {
      result.addAll(_collectFinancialMaps(value[key], tipo: tipo));
    }
  }
  return result;
}

_FinancialItems _splitFinancialItems(List<Map<String, dynamic>> items) {
  final pagar = <Map<String, dynamic>>[];
  final receber = <Map<String, dynamic>>[];
  final unknown = <Map<String, dynamic>>[];

  for (final item in items) {
    if (_isTipo(item, 'PAGAR')) {
      pagar.add(item);
    } else if (_isTipo(item, 'RECEBER')) {
      receber.add(item);
    } else {
      unknown.add(item);
    }
  }

  return _FinancialItems(pagar: pagar, receber: receber, unknown: unknown);
}

String _stringValue(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final value = item[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

Map<String, dynamic>? _mapValue(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final value = item[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return null;
}

DateTime? _parseFinancialDate(String value) {
  if (value.isEmpty) return null;
  final iso = value.length >= 10 ? value.substring(0, 10) : value;
  final parsedIso = DateTime.tryParse(iso);
  if (parsedIso != null) return parsedIso;

  final brMatch = RegExp(r'^(\d{2})/(\d{2})/(\d{4})').firstMatch(value);
  if (brMatch != null) {
    return DateTime.tryParse(
      '${brMatch.group(3)}-${brMatch.group(2)}-${brMatch.group(1)}',
    );
  }
  return null;
}

double _moneyValue(Map<String, dynamic> item, String key) {
  final value = item[key] ??
      item['valorOriginal'] ??
      item['valorTotal'] ??
      item['valorBaixa'] ??
      item['amount'];
  if (value is num) return value.toDouble();
  if (value is String) {
    final normalized = value.contains(',')
        ? value
            .replaceAll('R\$', '')
            .replaceAll(' ', '')
            .replaceAll('.', '')
            .replaceAll(',', '.')
        : value.replaceAll('R\$', '').replaceAll(' ', '');
    return double.tryParse(normalized) ?? 0;
  }
  return 0;
}

String _statusValue(Map<String, dynamic> item) {
  final value = item['status'] ?? item['situacao'];
  if (value is num) {
    switch (value.toInt()) {
      case 1:
        return 'BAIXADA';
      case 2:
        return 'CANCELADA';
      default:
        return 'ABERTA';
    }
  }
  final text = value?.toString().trim().toUpperCase() ?? '';
  switch (text) {
    case '1':
    case 'PAGO':
    case 'PAGA':
    case 'RECEBIDO':
    case 'RECEBIDA':
    case 'LIQUIDADO':
    case 'LIQUIDADA':
      return 'BAIXADA';
    case '2':
    case 'CANCELADO':
    case 'CANCELADA':
      return 'CANCELADA';
    case '0':
    case 'PENDENTE':
    case 'VENCIDA':
    case 'ABERTO':
    case 'ABERTA':
      return 'ABERTA';
    default:
      return text;
  }
}

bool _isBaixada(Map<String, dynamic> item) => _statusValue(item) == 'BAIXADA';

bool _isCancelada(Map<String, dynamic> item) =>
    _statusValue(item) == 'CANCELADA';

bool _hasDocumentoFiscal(Map<String, dynamic> item) {
  final value = item['documentoFiscal'] ?? item['documento_fiscal'];
  return value == true || value.toString().toLowerCase() == 'true';
}

bool _hasTipo(Map<String, dynamic> item) {
  return _stringValue(item, const [
    '_calendarioTipo',
    'tipo',
    'tipoConta',
    'tipo_conta',
    'natureza',
    'origem',
    'categoria',
  ]).isNotEmpty;
}

bool _isTipo(Map<String, dynamic> item, String tipo) {
  final raw = _stringValue(item, const [
    '_calendarioTipo',
    'tipo',
    'tipoConta',
    'tipo_conta',
    'tipoLancamento',
    'tipo_lancamento',
    'natureza',
    'origem',
    'categoria',
  ]).toUpperCase();
  if (raw == tipo) return true;
  if (tipo == 'PAGAR') {
    return raw.contains('PAGAR') ||
        raw.contains('DESPESA') ||
        raw.contains('SAIDA');
  }
  if (tipo == 'RECEBER') {
    return raw.contains('RECEBER') ||
        raw.contains('RECEITA') ||
        raw.contains('ENTRADA');
  }
  return false;
}

String _dateKey(Map<String, dynamic> item) {
  final value = _stringValue(item, const [
    'dataVencimento',
    'data_vencimento',
    'dataPrevista',
    'data_prevista',
    'dataCompetencia',
    'data_competencia',
    'data',
    'vencimento',
    'dtVencimento',
    'dt_vencimento',
    'dueDate',
  ]);
  final parsed = _parseFinancialDate(value);
  if (parsed != null) return DateFormat('yyyy-MM-dd').format(parsed);
  return value;
}

// ─── Main widget ─────────────────────────────────────────────────────────────

class WindowsCalendarScreen extends StatefulWidget {
  /// Mantido apenas para compatibilidade com chamadas antigas.
  /// O Calendario Financeiro nao renderiza header proprio.
  final bool useLightHeader;

  const WindowsCalendarScreen({super.key, this.useLightHeader = false});

  @override
  State<WindowsCalendarScreen> createState() => _WindowsCalendarScreenState();
}

class _WindowsCalendarScreenState extends State<WindowsCalendarScreen> {
  // ── Colors ──────────────────────────────────────────────────────────────
  static const Color _red = GridColors.primary;
  static const Color _redLight = Color(0xFFFFEBEE);
  static const Color _green = GridColors.secondary;
  static const Color _greenLight = Color(0xFFE8F5E9);
  static const Color _orange = Color(0xFFE65100);
  static const Color _purple = Color(0xFF6A1B9A);
  static const Color _purpleLight = Color(0xFFF3E5F5);
  static const Color _grey = Color(0xFFF5F5F5);
  static const Color _greyBorder = Color(0xFFE0E0E0);
  static const Color _dark = Color(0xFF212121);

  // ── State ────────────────────────────────────────────────────────────────
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  String _viewMode = 'day';
  bool _loadingDay = false;
  bool _loadingMonth = false;

  List<Map<String, dynamic>> _contasPagar = [];
  List<Map<String, dynamic>> _contasReceber = [];

  final Map<int, _MonthSummary> _monthSummaries = {};
  Map<String, _DayMarkers> _dayMarkers = {};

  // ── Formatters ───────────────────────────────────────────────────────────
  final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadMonthMarkers(_currentMonth);
    _loadYearSummariesAndMarkers(_currentMonth.year);
  }

  // ── API helpers ──────────────────────────────────────────────────────────

  String _dayParam(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String _monthParam(DateTime d) => DateFormat('yyyy-MM').format(d);

  String _buildUrl(String base, Map<String, String> params) {
    final uri = Uri.parse(base);
    final query = Map<String, String>.from(uri.queryParameters)..addAll(params);
    final empId = TenantContext.empresaId;
    if (empId != null) {
      query.putIfAbsent('empId', () => empId.toString());
    }
    return uri.replace(queryParameters: query).toString();
  }

  List<Map<String, dynamic>> _parseItems(dynamic body) {
    return _parseFinancialGroups(body).all;
  }

  _FinancialItems _parseGroups(dynamic body) {
    return _parseFinancialGroups(body);
  }

  Future<void> _loadMonthMarkers(DateTime month) async {
    setState(() => _loadingMonth = true);
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month,
        DateUtils.getDaysInMonth(month.year, month.month));
    final url = _buildUrl(ApiLinks.calendarioFinanceiro, {
      'dataInicio': _dayParam(first),
      'dataFim': _dayParam(last),
    });

    final res = await NetworkCaller().getRequest(url);
    final items =
        res.isSuccess ? _parseGroups(res.body) : const _FinancialItems();
    final pagarList = items.pagar;
    final receberList = items.receber;

    final newMarkers = Map<String, _DayMarkers>.from(_dayMarkers);

    void addMarker(String key,
        {bool pagar = false,
        bool receber = false,
        bool pago = false,
        bool recebido = false,
        bool tributo = false}) {
      final old = newMarkers[key] ?? const _DayMarkers();
      newMarkers[key] = _DayMarkers(
        hasPagar: old.hasPagar || pagar,
        hasReceber: old.hasReceber || receber,
        hasPago: old.hasPago || pago,
        hasRecebido: old.hasRecebido || recebido,
        hasTributo: old.hasTributo || tributo,
      );
    }

    for (final item in pagarList) {
      final dateStr = _dateKey(item);
      if (dateStr.isEmpty) continue;
      final isBaixa = _isBaixada(item);
      final tributo = _hasDocumentoFiscal(item);
      addMarker(
        dateStr,
        pagar: !isBaixa,
        pago: isBaixa,
        tributo: tributo,
      );
    }

    for (final item in receberList) {
      final dateStr = _dateKey(item);
      if (dateStr.isEmpty) continue;
      final isBaixa = _isBaixada(item);
      final tributo = _hasDocumentoFiscal(item);
      addMarker(
        dateStr,
        receber: !isBaixa,
        recebido: isBaixa,
        tributo: tributo,
      );
    }

    if (!mounted) return;
    setState(() {
      _dayMarkers = newMarkers;
      _loadingMonth = false;
    });
  }

  Future<void> _loadYearSummariesAndMarkers(int year) async {
    final first = DateTime(year, 1, 1);
    final last = DateTime(year, 12, 31);
    final url = _buildUrl(ApiLinks.calendarioFinanceiro, {
      'dataInicio': _dayParam(first),
      'dataFim': _dayParam(last),
    });

    final res = await NetworkCaller().getRequest(url);
    final items =
        res.isSuccess ? _parseGroups(res.body) : const _FinancialItems();
    final pagarList = items.pagar;
    final receberList = items.receber;

    final newMarkers = Map<String, _DayMarkers>.from(_dayMarkers);

    void addMarker(String key,
        {bool pagar = false,
        bool receber = false,
        bool pago = false,
        bool recebido = false,
        bool tributo = false}) {
      final old = newMarkers[key] ?? const _DayMarkers();
      newMarkers[key] = _DayMarkers(
        hasPagar: old.hasPagar || pagar,
        hasReceber: old.hasReceber || receber,
        hasPago: old.hasPago || pago,
        hasRecebido: old.hasRecebido || recebido,
        hasTributo: old.hasTributo || tributo,
      );
    }

    final monthlyPagar = <int, double>{};
    final monthlyPago = <int, double>{};
    final monthlyReceber = <int, double>{};
    final monthlyRecebido = <int, double>{};

    for (final item in pagarList) {
      final dateStr = _dateKey(item);
      if (dateStr.isEmpty) continue;
      final isBaixa = _isBaixada(item);
      final tributo = _hasDocumentoFiscal(item);
      addMarker(
        dateStr,
        pagar: !isBaixa,
        pago: isBaixa,
        tributo: tributo,
      );

      final dt = _parseFinancialDate(dateStr);
      if (dt != null && dt.year == year) {
        final m = dt.month;
        final v = _moneyValue(item, 'valor');
        if (isBaixa) {
          monthlyPago[m] = (monthlyPago[m] ?? 0) + v;
        } else if (!_isCancelada(item)) {
          monthlyPagar[m] = (monthlyPagar[m] ?? 0) + v;
        }
      }
    }

    for (final item in receberList) {
      final dateStr = _dateKey(item);
      if (dateStr.isEmpty) continue;
      final isBaixa = _isBaixada(item);
      final tributo = _hasDocumentoFiscal(item);
      addMarker(
        dateStr,
        receber: !isBaixa,
        recebido: isBaixa,
        tributo: tributo,
      );

      final dt = _parseFinancialDate(dateStr);
      if (dt != null && dt.year == year) {
        final m = dt.month;
        final v = _moneyValue(item, 'valor');
        if (isBaixa) {
          monthlyRecebido[m] = (monthlyRecebido[m] ?? 0) + v;
        } else if (!_isCancelada(item)) {
          monthlyReceber[m] = (monthlyReceber[m] ?? 0) + v;
        }
      }
    }

    final newSummaries = Map<int, _MonthSummary>.from(_monthSummaries);
    for (int m = 1; m <= 12; m++) {
      final tp = monthlyPagar[m] ?? 0;
      final tpg = monthlyPago[m] ?? 0;
      final tr = monthlyReceber[m] ?? 0;
      final trb = monthlyRecebido[m] ?? 0;
      newSummaries[m] = _MonthSummary(
        totalPagar: tp,
        totalPago: tpg,
        totalReceber: tr,
        totalRecebido: trb,
        saldoPagar: tpg - tp,
        saldoReceber: trb - tr,
      );
    }

    if (!mounted) return;
    setState(() {
      _dayMarkers = newMarkers;
      _monthSummaries.addAll(newSummaries);
    });
  }

  Future<void> _loadDayData(DateTime day) async {
    setState(() {
      _loadingDay = true;
      _contasPagar = [];
      _contasReceber = [];
    });
    final dayStr = _dayParam(day);
    final url = _buildUrl(ApiLinks.calendarioFinanceiro, {
      'dataInicio': dayStr,
      'dataFim': dayStr,
      'dataVencimento': dayStr,
    });

    final res = await NetworkCaller().getRequest(url);
    final items =
        res.isSuccess ? _parseGroups(res.body) : const _FinancialItems();

    if (!mounted) return;
    setState(() {
      _contasPagar = items.pagar;
      _contasReceber = items.receber;
      _loadingDay = false;
    });
  }

  Future<_MonthSummary> _loadMonthSummary(int year, int month) async {
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month, DateUtils.getDaysInMonth(year, month));
    final url = _buildUrl(ApiLinks.calendarioFinanceiro, {
      'dataInicio': _dayParam(first),
      'dataFim': _dayParam(last),
    });

    final res = await NetworkCaller().getRequest(url);
    final items =
        res.isSuccess ? _parseGroups(res.body) : const _FinancialItems();
    final pagarList = items.pagar;
    final receberList = items.receber;

    double totalPagar = 0, totalPago = 0, totalReceber = 0, totalRecebido = 0;

    for (final item in pagarList) {
      final v = (item['valor'] as num?)?.toDouble() ?? 0;
      if (item['status'] == 'BAIXADA') {
        totalPago += v;
      } else if (item['status'] != 'CANCELADA') {
        totalPagar += v;
      }
    }
    for (final item in receberList) {
      final v = (item['valor'] as num?)?.toDouble() ?? 0;
      if (item['status'] == 'BAIXADA') {
        totalRecebido += v;
      } else if (item['status'] != 'CANCELADA') {
        totalReceber += v;
      }
    }

    return _MonthSummary(
      totalPagar: totalPagar,
      totalPago: totalPago,
      totalReceber: totalReceber,
      totalRecebido: totalRecebido,
      saldoPagar: totalPago - totalPagar,
      saldoReceber: totalRecebido - totalReceber,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _grey,
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
              child: _viewMode == 'day' ? _buildDayView() : _buildMonthView()),
        ],
      ),
    );
  }

  // ── Barra de toggle Dia/Mês + Hoje + refresh ──
  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _greyBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Toggle buttons
          _buildToggleBtn(
            icon: Icons.calendar_view_day,
            label: 'Dia',
            active: _viewMode == 'day',
            onTap: () => setState(() => _viewMode = 'day'),
          ),
          const SizedBox(width: 6),
          _buildToggleBtn(
            icon: Icons.calendar_view_month,
            label: 'Mês',
            active: _viewMode == 'month',
            onTap: () => setState(() => _viewMode = 'month'),
          ),
          const Spacer(),
          // Hoje button
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              final today = DateTime.now();
              setState(() {
                _selectedDay = today;
                _currentMonth = DateTime(today.year, today.month);
              });
              _loadMonthMarkers(_currentMonth);
              _loadDayData(today);
            },
            child: const Text('Hoje',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          _buildRefreshBtn(),
        ],
      ),
    );
  }

  // Botão de refresh no header (translúcido branco, ao lado de "Hoje").
  Widget _buildRefreshBtn() {
    final carregando = _loadingDay || _loadingMonth;
    return Material(
      color: _redLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: carregando
            ? null
            : () {
                final day = _selectedDay ?? DateTime.now();
                _loadMonthMarkers(_currentMonth);
                _loadDayData(day);
              },
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: carregando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: _red),
                  )
                : const Icon(Icons.refresh, size: 20, color: _red),
          ),
        ),
      ),
    );
  }

  Future<dynamic> _fetchFinancialJson(String url) async {
    try {
      final response = await TenantContext.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  // Abre o popup de baixa da conta (a partir do item do calendário).
  Future<void> _abrirBaixaConta(Map<String, dynamic> item,
      {required bool isPagar}) async {
    final id = item['id']?.toString();
    if (!DocumentoBaixaHelper.itemIdValido(id)) {
      _mostrarErro('ID da conta não encontrado');
      return;
    }

    final isTitulo = item['documentoFiscal'] == true;

    try {
      Map<String, dynamic> body;

      if (isTitulo) {
        body = Map<String, dynamic>.from(item);
      } else {
        final url = isPagar
            ? ApiLinks.updateContaPagar(id!)
            : ApiLinks.updateContaReceber(id!);
        dynamic fetchedBody = await _fetchFinancialJson(url);
        final parsedBody = DocumentoBaixaHelper.parseContaBody(fetchedBody);
        if (parsedBody == null) {
          _mostrarErro('Dados da conta não encontrados na resposta');
          return;
        }
        body = parsedBody;
      }

      try {
        final result = await showDialog<bool>(
          context: context,
          builder: (_) => isPagar
              ? WebBaixaDialog(
                  conta: ContaPagar.fromJson(body),
                )
              : WebBaixaDialogReceber(
                  conta: ContaReceber.fromJson(body),
                ),
        );

        if (result == true && _selectedDay != null) {
          await _loadDayData(_selectedDay!);
          await _loadMonthMarkers(_currentMonth);
        }
      } catch (e) {
        _mostrarErro('Erro ao parsejar dados da conta: $e');
      }
    } catch (e) {
      _mostrarErro('Erro ao carregar dados: $e');
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    print('[DOCUMENTO_SCREEN] Erro ao abrir baixa: $mensagem');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  // Abre o visualizador de anexos da conta (ver/baixar).
  void _abrirAnexosConta(Map<String, dynamic> item, {required bool isPagar}) {
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, _) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AnexoFinanceiroWidget(
            lancamentoId: id,
            lancamentoTipo: isPagar ? 'PAGAR' : 'RECEBER',
            empresaId: (item['empresa']?['id'] as num?)?.toInt(),
          ),
        ),
      ),
    );
  }

  // Abre o Boleto Viewer (card #440): busca o primeiro anexo do lancamento
  // e mostra a linha digitavel (copiar) + baixar o PDF.
  Future<void> _abrirBoletoViewer(Map<String, dynamic> item,
      {required bool isPagar}) async {
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    // Fix card #443: itens do Calendario Financeiro (CalendarioFinanceiroItemDTO)
    // expoem empresaId achatado, nao aninhado como 'empresa': {'id': ...}
    // (formato usado pelas grids de Contas a Pagar/Receber).
    final empresaId = (item['empresa']?['id'] as num?)?.toInt() ??
        (item['empresaId'] as num?)?.toInt();
    try {
      final anexos = await AnexoFinanceiroService().listar(
        id,
        isPagar ? 'PAGAR' : 'RECEBER',
        empresaId: empresaId,
      );
      if (anexos.isEmpty) {
        _mostrarErro('Nenhum anexo encontrado para este lançamento.');
        return;
      }
      final anexo = anexos.first;
      if (!mounted || anexo.id == null) return;
      await showBoletoViewerDialog(
        context,
        anexoId: anexo.id!,
        fileName: anexo.fileName,
        empresaId: empresaId,
      );
    } catch (e) {
      _mostrarErro('Erro ao abrir boleto: $e');
    }
  }

  // Ícone de ação compacto usado nos itens do detalhe do dia.
  Widget _miniActionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildToggleBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _redLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? _red : _greyBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? _red : _dark),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? _red : _dark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Day view ─────────────────────────────────────────────────────────────
  Widget _buildDayView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Card(
            margin: const EdgeInsets.all(12),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildMonthNav(),
                  const SizedBox(height: 8),
                  _buildWeekdayHeaders(),
                  const SizedBox(height: 4),
                  Expanded(child: _buildCalendarGrid()),
                  const Divider(height: 16),
                  _buildLegend(),
                ],
              ),
            ),
          ),
        ),
        if (_selectedDay != null)
          SizedBox(
            width: 360,
            child: _buildDaySidePanel(),
          ),
      ],
    );
  }

  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: _green),
          onPressed: () {
            final prev = DateTime(_currentMonth.year, _currentMonth.month - 1);
            setState(() => _currentMonth = prev);
            _loadMonthMarkers(prev);
          },
        ),
        Text(
          DateFormat('MMMM yyyy', 'pt_BR').format(_currentMonth),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: _dark,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: _green),
          onPressed: () {
            final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
            setState(() => _currentMonth = next);
            _loadMonthMarkers(next);
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return Row(
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    final cells = <Widget>[];

    // Empty leading cells
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateStr = _dayParam(date);
      final markers = _dayMarkers[dateStr] ?? const _DayMarkers();
      final isToday = date == todayNorm;
      final isSelected =
          _selectedDay != null && _dayParam(_selectedDay!) == dateStr;
      final isPast = date.isBefore(todayNorm);

      cells.add(_buildDayCell(
        day: day,
        date: date,
        markers: markers,
        isToday: isToday,
        isSelected: isSelected,
        isPast: isPast,
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 0.85,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: cells,
    );
  }

  Widget _buildDayCell({
    required int day,
    required DateTime date,
    required _DayMarkers markers,
    required bool isToday,
    required bool isSelected,
    required bool isPast,
  }) {
    Color? bgColor;
    Color textColor = _dark;

    if (isSelected) {
      bgColor = _red;
      textColor = Colors.white;
    } else if (markers.hasPagar) {
      bgColor = _redLight;
    } else if (markers.hasReceber) {
      bgColor = _greenLight;
    } else if (markers.hasPago || markers.hasRecebido || markers.hasTributo) {
      bgColor = const Color(0xFFF1F5F9);
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDay = date);
        _loadDayData(date);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isToday ? _green : _greyBorder,
            width: isToday ? 2 : 0.5,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 1,
              runSpacing: 1,
              children: [
                if (markers.hasPagar) _miniIcon(Icons.arrow_upward, _red, 11),
                if (markers.hasReceber)
                  _miniIcon(Icons.arrow_downward, _green, 11),
                if (markers.hasPago) _miniIcon(Icons.check, Colors.grey, 11),
                if (markers.hasRecebido)
                  _miniIcon(Icons.check_circle, _green, 11),
                if (markers.hasTributo)
                  Container(
                    decoration: BoxDecoration(
                      color: _purpleLight,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: _purple, width: 1),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: const Icon(Icons.receipt_long,
                        color: _purple, size: 13),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniIcon(IconData icon, Color color, double size) {
    return Icon(icon, color: color, size: size);
  }

  // ── Legend ───────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _legendItem(Icons.arrow_upward, _red, 'A Pagar'),
        _legendItem(Icons.arrow_downward, _green, 'A Receber'),
        _legendItem(Icons.check, Colors.grey, 'Pago'),
        _legendItem(Icons.check_circle, _green, 'Recebido'),
        _legendItem(Icons.receipt_long, _purple, 'Doc. Fiscal'),
      ],
    );
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: _dark)),
      ],
    );
  }

  // ── Day side panel ───────────────────────────────────────────────────────
  Widget _buildDaySidePanel() {
    final day = _selectedDay!;
    final weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final wdLabel = weekdays[day.weekday % 7];
    final dateLabel =
        '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year} ($wdLabel)';

    final totalPagar = _contasPagar.fold<double>(
        0, (s, i) => s + ((i['valor'] as num?)?.toDouble() ?? 0));
    final totalReceber = _contasReceber.fold<double>(
        0, (s, i) => s + ((i['valor'] as num?)?.toDouble() ?? 0));
    final saldo = totalReceber - totalPagar;

    return Card(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          // Panel header
          Container(
            decoration: const BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.event, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _selectedDay = null),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _loadingDay
                ? const Center(child: CircularProgressIndicator(color: _red))
                : ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      _buildSectionHeader(
                        icon: Icons.arrow_upward,
                        color: _red,
                        label: 'A Pagar',
                        total: totalPagar,
                        totalColor: _red,
                      ),
                      ..._contasPagar
                          .map((item) => _buildContaItem(item, isPagar: true)),
                      if (_contasPagar.isEmpty)
                        _emptySection('Nenhuma conta a pagar'),
                      const SizedBox(height: 12),
                      _buildSectionHeader(
                        icon: Icons.arrow_downward,
                        color: _green,
                        label: 'A Receber',
                        total: totalReceber,
                        totalColor: _green,
                      ),
                      ..._contasReceber
                          .map((item) => _buildContaItem(item, isPagar: false)),
                      if (_contasReceber.isEmpty)
                        _emptySection('Nenhuma conta a receber'),
                      const SizedBox(height: 12),
                      _buildDaySummaryRow(totalPagar, totalReceber, saldo),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String label,
    required double total,
    required Color totalColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const Spacer(),
          Text(
            _currencyFmt.format(total),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: totalColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContaItem(Map<String, dynamic> item, {required bool isPagar}) {
    final valor = (item['valor'] as num?)?.toDouble() ?? 0;
    final status = item['status'] as String? ?? 'ABERTA';
    final descricao = item['descricao'] as String? ?? '';
    final tributo = item['documentoFiscal'] == true;
    final parceiro = (item['parceiro'] as Map?)?.cast<String, dynamic>();
    final parceiroNome = parceiro?['nome'] as String? ?? '';
    final qtdAnexos = (item['qtdAnexos'] as num?)?.toInt() ?? 0;

    final today = DateTime.now();
    final vencStr = (item['dataVencimento'] as String?)?.substring(0, 10) ?? '';
    final vencDate = DateTime.tryParse(vencStr);
    final isVencida = status == 'ABERTA' &&
        vencDate != null &&
        vencDate.isBefore(DateTime(today.year, today.month, today.day));

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'BAIXADA':
        statusColor = _green;
        statusLabel = isPagar ? 'PAGO' : 'RECEBIDO';
        break;
      case 'CANCELADA':
        statusColor = Colors.grey;
        statusLabel = 'CANCELADA';
        break;
      default:
        statusColor = _orange;
        statusLabel = 'ABERTA';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: tributo ? _purple : _greyBorder,
          width: tributo ? 1.5 : 0.5,
        ),
      ),
      color: tributo ? _purpleLight.withValues(alpha: 0.3) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fiscal icon
            if (tributo) ...[
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _purple),
                ),
                child: const Icon(Icons.receipt_long, color: _purple, size: 14),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                status == 'BAIXADA' ? Icons.check : Icons.arrow_upward,
                color: status == 'BAIXADA'
                    ? Colors.grey
                    : (isPagar ? _red : _green),
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            // Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descricao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (parceiroNome.isNotEmpty)
                    Text(parceiroNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Right side: value + chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFmt.format(valor),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isPagar ? _red : _green,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVencida) _chip('VENCIDA', _red, Colors.white),
                    const SizedBox(width: 3),
                    _chip(statusLabel, statusColor, Colors.white),
                  ],
                ),
                // Ações: ver anexo (se houver) e baixar conta (se ABERTA)
                if (status == 'ABERTA' || qtdAnexos > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (qtdAnexos > 0) ...[
                        _miniActionBtn(
                          icon: Icons.attach_file,
                          color: GridColors.textPrimary.withValues(alpha: 0.55),
                          tooltip: 'Ver anexo',
                          onTap: () =>
                              _abrirAnexosConta(item, isPagar: isPagar),
                        ),
                        const SizedBox(width: 2),
                        _miniActionBtn(
                          icon: Icons.receipt_long,
                          color: GridColors.primary,
                          tooltip: 'Boleto viewer',
                          onTap: () =>
                              _abrirBoletoViewer(item, isPagar: isPagar),
                        ),
                      ],
                      if (status == 'ABERTA') ...[
                        const SizedBox(width: 2),
                        _miniActionBtn(
                          icon: Icons.price_check,
                          color: GridColors.success,
                          tooltip: 'Baixar conta',
                          onTap: () => _abrirBaixaConta(item, isPagar: isPagar),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _emptySection(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(msg,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
          textAlign: TextAlign.center),
    );
  }

  Widget _buildDaySummaryRow(double pagar, double receber, double saldo) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _grey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _greyBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryCell('-${_currencyFmt.format(pagar)}', 'A Pagar', _red),
          _summaryCell('+${_currencyFmt.format(receber)}', 'A Receber', _green),
          _summaryCell(
            '${saldo >= 0 ? '+' : ''}${_currencyFmt.format(saldo)}',
            'Saldo',
            saldo >= 0 ? _green : _red,
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 12)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // ── Month view ───────────────────────────────────────────────────────────
  Widget _buildMonthView() {
    final year = _currentMonth.year;
    return Column(
      children: [
        // Year navigation
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: _green),
                onPressed: () => setState(() {
                  final newDt = DateTime(_currentMonth.year - 1, 1);
                  setState(() => _currentMonth = newDt);
                  _loadYearSummariesAndMarkers(newDt.year);
                }),
              ),
              Text(
                '$year',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: _dark),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: _green),
                onPressed: () => setState(() {
                  final newDt = DateTime(_currentMonth.year + 1, 1);
                  setState(() => _currentMonth = newDt);
                  _loadYearSummariesAndMarkers(newDt.year);
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingMonth
              ? const Center(child: CircularProgressIndicator(color: _red))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.35,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (ctx, idx) => _buildMonthCard(year, idx + 1),
                ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(int year, int month) {
    final monthNames = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    final summary = _monthSummaries[month];
    final saldo = summary != null
        ? (summary.totalRecebido + summary.saldoReceber) -
            (summary.totalPago + summary.saldoPagar.abs())
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month name + year
            Text(
              '${monthNames[month - 1]} $year',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: _dark),
            ),
            const SizedBox(height: 6),
            // Action buttons
            Row(
              children: [
                _monthActionBtn(
                  icon: Icons.arrow_upward,
                  color: _red,
                  tooltip: 'Contas a Pagar',
                  onTap: () => _showMonthPopup(
                    context,
                    year: year,
                    month: month,
                    isPagar: true,
                    monthName: monthNames[month - 1],
                  ),
                ),
                const SizedBox(width: 6),
                _monthActionBtn(
                  icon: Icons.arrow_downward,
                  color: _green,
                  tooltip: 'Contas a Receber',
                  onTap: () => _showMonthPopup(
                    context,
                    year: year,
                    month: month,
                    isPagar: false,
                    monthName: monthNames[month - 1],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildMiniMonthDays(year, month)),
            const SizedBox(height: 6),
            if (summary != null) ...[
              Text(
                summary.totalPagar > 0
                    ? (summary.totalPago > 0
                        ? 'Pagar: ${_currencyFmt.format(summary.totalPagar)} (Pago: ${_currencyFmt.format(summary.totalPago)})'
                        : 'Pagar: ${_currencyFmt.format(summary.totalPagar)}')
                    : (summary.totalPago > 0
                        ? 'Pago: ${_currencyFmt.format(summary.totalPago)}'
                        : 'Pagar: ${_currencyFmt.format(0)}'),
                style: const TextStyle(fontSize: 10, color: _red),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                summary.totalReceber > 0
                    ? (summary.totalRecebido > 0
                        ? 'Receber: ${_currencyFmt.format(summary.totalReceber)} (Rec: ${_currencyFmt.format(summary.totalRecebido)})'
                        : 'Receber: ${_currencyFmt.format(summary.totalReceber)}')
                    : (summary.totalRecebido > 0
                        ? 'Recebido: ${_currencyFmt.format(summary.totalRecebido)}'
                        : 'Receber: ${_currencyFmt.format(0)}'),
                style: const TextStyle(fontSize: 10, color: _green),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Saldo: ${_currencyFmt.format((summary.totalRecebido + summary.totalReceber) - (summary.totalPago + summary.totalPagar))}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ((summary.totalRecebido + summary.totalReceber) -
                              (summary.totalPago + summary.totalPagar)) >=
                          0
                      ? _green
                      : _red,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _loadAndCacheMonthSummary(year, month),
                child: const Text('Carregar', style: TextStyle(fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMonthDays(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final startOffset = firstDay.weekday % 7;
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();
    final isCurrentMonth = today.year == year && today.month == month;

    return Column(
      children: [
        const Row(
          children: [
            _MiniWeekday('D'),
            _MiniWeekday('S'),
            _MiniWeekday('T'),
            _MiniWeekday('Q'),
            _MiniWeekday('Q'),
            _MiniWeekday('S'),
            _MiniWeekday('S'),
          ],
        ),
        const SizedBox(height: 3),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.35,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: totalCells,
            itemBuilder: (_, index) {
              final day = index - startOffset + 1;
              if (day < 1 || day > daysInMonth) {
                return const SizedBox.shrink();
              }
              final cellDate = DateTime(year, month, day);
              final dateStr = _dayParam(cellDate);
              final markers = _dayMarkers[dateStr] ?? const _DayMarkers();
              final isToday = isCurrentMonth && today.day == day;

              Color cellBg = GridColors.card;
              Color borderCol = GridColors.borderSubtle.withValues(alpha: 0.55);
              Color txtCol = GridColors.textMuted;

              if (isToday) {
                cellBg = _red.withValues(alpha: 0.12);
                borderCol = _red.withValues(alpha: 0.55);
                txtCol = _red;
              } else if (markers.hasPagar) {
                cellBg = const Color(0xFFFFEBEE);
                borderCol = const Color(0xFFFFCDD2);
                txtCol = _red;
              } else if (markers.hasReceber) {
                cellBg = const Color(0xFFE8F5E9);
                borderCol = const Color(0xFFC8E6C9);
                txtCol = _green;
              } else if (markers.hasPago || markers.hasRecebido) {
                cellBg = const Color(0xFFE8F5E9);
                borderCol = const Color(0xFFC8E6C9);
                txtCol = _green;
              } else if (markers.hasTributo) {
                cellBg = const Color(0xFFF1F5F9);
                borderCol = const Color(0xFFE2E8F0);
                txtCol = const Color(0xFF475569);
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDay = cellDate;
                    _currentMonth = DateTime(year, month);
                    _viewMode = 'day';
                  });
                  _loadMonthMarkers(DateTime(year, month));
                  _loadDayData(cellDate);
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: borderCol,
                      width: isToday ? 1.5 : 0.8,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: (isToday ||
                                  markers.hasPagar ||
                                  markers.hasReceber)
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: txtCol,
                        ),
                      ),
                      if (markers.hasPagar ||
                          markers.hasReceber ||
                          markers.hasPago ||
                          markers.hasRecebido)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (markers.hasPagar)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 0.5),
                                  decoration: const BoxDecoration(
                                    color: _red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (markers.hasReceber)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 0.5),
                                  decoration: const BoxDecoration(
                                    color: _green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (markers.hasPago && !markers.hasPagar)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 0.5),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (markers.hasRecebido && !markers.hasReceber)
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 0.5),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _monthActionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Future<void> _loadAndCacheMonthSummary(int year, int month) async {
    final summary = await _loadMonthSummary(year, month);
    if (!mounted) return;
    setState(() => _monthSummaries[month] = summary);
  }

  Future<void> _showMonthPopup(
    BuildContext context, {
    required int year,
    required int month,
    required bool isPagar,
    required String monthName,
  }) async {
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final url = isPagar
        ? _buildUrl(
            ApiLinks.allContasPagar, {'mesAno': monthStr, 'tamanho': '1000'})
        : _buildUrl(
            ApiLinks.allContasReceber, {'mesAno': monthStr, 'tamanho': '1000'});

    showDialog(
      context: context,
      builder: (_) => _MonthDetailDialog(
        title:
            '${isPagar ? 'Contas a Pagar' : 'Contas a Receber'} — $monthName $year',
        url: url,
        isPagar: isPagar,
        currencyFmt: _currencyFmt,
      ),
    );
  }
}

// ─── Month detail dialog ─────────────────────────────────────────────────────

class _MonthDetailDialog extends StatefulWidget {
  final String title;
  final String url;
  final bool isPagar;
  final NumberFormat currencyFmt;

  const _MonthDetailDialog({
    required this.title,
    required this.url,
    required this.isPagar,
    required this.currencyFmt,
  });

  @override
  State<_MonthDetailDialog> createState() => _MonthDetailDialogState();
}

class _MonthDetailDialogState extends State<_MonthDetailDialog> {
  static const Color _red = GridColors.primary;
  static const Color _green = GridColors.secondary;
  static const Color _orange = Color(0xFFE65100);
  static const Color _grey = Color(0xFFF5F5F5);
  static const Color _greyBorder = Color(0xFFE0E0E0);
  static const Color _purple = Color(0xFF6A1B9A);
  static const Color _purpleLight = Color(0xFFF3E5F5);

  bool _loading = true;
  List<Map<String, dynamic>> _abertas = [];
  List<Map<String, dynamic>> _baixadas = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await NetworkCaller().getRequest(widget.url);
    if (!mounted) return;
    List<Map<String, dynamic>> items = [];
    if (res.isSuccess) {
      try {
        final data = res.body!['data'];
        final dados = data['dados'] as List? ?? [];
        items = List<Map<String, dynamic>>.from(dados);
      } catch (_) {}
    }
    setState(() {
      _abertas = items
          .where((i) => i['status'] != 'BAIXADA' && i['status'] != 'CANCELADA')
          .toList();
      _baixadas = items.where((i) => i['status'] == 'BAIXADA').toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAberto = _abertas.fold<double>(
        0, (s, i) => s + ((i['valor'] as num?)?.toDouble() ?? 0));
    final totalBaixado = _baixadas.fold<double>(
        0, (s, i) => s + ((i['valor'] as num?)?.toDouble() ?? 0));
    final saldo = widget.isPagar
        ? totalBaixado - totalAberto
        : totalBaixado - totalAberto;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          children: [
            // Dialog header
            Container(
              decoration: BoxDecoration(
                color: widget.isPagar ? _red : _green,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.isPagar ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _red))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _sectionTitle('Em Aberto', _orange),
                        ..._abertas.map((i) => _dialogItem(i)),
                        if (_abertas.isEmpty)
                          _emptyMsg('Nenhum item em aberto'),
                        const SizedBox(height: 12),
                        _sectionTitle(
                          widget.isPagar ? 'Pagas' : 'Recebidas',
                          _green,
                        ),
                        ..._baixadas.map((i) => _dialogItem(i)),
                        if (_baixadas.isEmpty) _emptyMsg('Nenhum item'),
                      ],
                    ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: _grey,
                border: Border(top: BorderSide(color: _greyBorder)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total em aberto:',
                        style: TextStyle(
                            fontSize: 12,
                            color: widget.isPagar ? _red : _orange),
                      ),
                      Text(
                        widget.currencyFmt.format(totalAberto),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: widget.isPagar ? _red : _orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isPagar ? 'Total pago:' : 'Total recebido:',
                        style: const TextStyle(fontSize: 12, color: _green),
                      ),
                      Text(
                        widget.currencyFmt.format(totalBaixado),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saldo:',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.currencyFmt.format(saldo),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: saldo >= 0 ? _green : _red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        style:
            TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
      ),
    );
  }

  Widget _dialogItem(Map<String, dynamic> item) {
    final valor = (item['valor'] as num?)?.toDouble() ?? 0;
    final descricao = item['descricao'] as String? ?? '';
    final tributo = item['documentoFiscal'] == true;
    final parceiro = (item['parceiro'] as Map?)?.cast<String, dynamic>();
    final parceiroNome = parceiro?['nome'] as String? ?? '';
    final vencStr = (item['dataVencimento'] as String?)?.substring(0, 10) ?? '';
    final dia = vencStr.length >= 10 ? vencStr.substring(8, 10) : '';
    final mes = vencStr.length >= 7 ? vencStr.substring(5, 7) : '';
    final dataLabel = dia.isNotEmpty && mes.isNotEmpty ? '$dia/$mes' : '';

    final subtitleParts = <String>[];
    if (dataLabel.isNotEmpty) subtitleParts.add(dataLabel);
    if (parceiroNome.isNotEmpty) subtitleParts.add(parceiroNome);
    final subtitleText = subtitleParts.join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: tributo ? _purple : _greyBorder,
          width: tributo ? 1.5 : 0.5,
        ),
      ),
      color: tributo ? _purpleLight.withValues(alpha: 0.25) : Colors.white,
      child: ListTile(
        dense: true,
        leading: tributo
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _purple),
                ),
                child: const Icon(Icons.receipt_long, color: _purple, size: 14),
              )
            : null,
        title: Text(descricao,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12)),
        subtitle: subtitleText.isNotEmpty
            ? Text(subtitleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10))
            : null,
        trailing: Text(
          widget.currencyFmt.format(valor),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: widget.isPagar ? _red : _green,
          ),
        ),
      ),
    );
  }

  Widget _emptyMsg(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        msg,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}

// ─── Web alias ───────────────────────────────────────────────────────────────
typedef WebCalendarScreen = WindowsCalendarScreen;
