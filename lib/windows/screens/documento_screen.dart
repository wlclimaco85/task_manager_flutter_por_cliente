// ignore_for_file: library_private_types_in_public_api
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../models/conta_receber_model.dart';
import '../../../services/anexo_financeiro_service.dart';
import '../../../utils/api_links.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/document_baixa_helper.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/anexo_financeiro_widget.dart';
import '../../../widgets/boleto_viewer_widget.dart';
import './baixa_dialog.dart';
import './baixa_dialog_receber.dart';

// ─── Internal data models ────────────────────────────────────────────────────

class _DayMarkers {
  final bool hasPagar;
  final bool hasReceber;
  final bool hasPago;
  final bool hasRecebido;
  final bool hasTributo;
  // Pedido do usuario (2026-09-11): status de pagamento do lancamento no dia,
  // pra colorir o calendario por SITUACAO (paga=verde, vencida/atrasada e
  // nao paga=amarela, em aberto e ainda no prazo=vermelha) em vez de so por
  // tipo (pagar/receber).
  final bool hasAtrasada;
  const _DayMarkers({
    this.hasPagar = false,
    this.hasReceber = false,
    this.hasPago = false,
    this.hasRecebido = false,
    this.hasTributo = false,
    this.hasAtrasada = false,
  });
}

/// Pedido do usuario (2026-09-11): "quando ja foram pagas na cor verde
/// quando nao for e estiver atrazada na amarela e quando ainda estiver pra
/// vencer em aberta vermelha". `hoje` e' passado explicitamente pra facilitar
/// teste (sem depender de DateTime.now() direto na funcao).
bool _isVencida(Map<String, dynamic> item, DateTime hoje) {
  if (_isBaixada(item) || _isCancelada(item)) return false;
  final dt = _parseFinancialDate(_dateKey(item));
  if (dt == null) return false;
  final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
  return dt.isBefore(hojeSemHora);
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
            color: GridColors.secondaryDark,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Main widget ─────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _parseFinancialItems(dynamic body) {
  return _parseFinancialGroups(body).all;
}

_FinancialItems _parseFinancialGroups(dynamic body) {
  if (body == null) return const _FinancialItems();
  L.d('[PARSE] Body type: ${body.runtimeType}');
  try {
    dynamic cursor = body;
    // Percorre wrappers {"data": ...} somente enquanto cursor for Map.
    // Guard explícito: se cursor['data'] for List, sai do loop antes de
    // tentar acessar via String key num List (evita "type String is not a
    // subtype of type int of 'index'").
    while (cursor is Map && cursor.containsKey('data')) {
      final next = cursor['data'];
      if (next == null) break;
      cursor = next;
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
        L.d('[PARSE] Found structured data - Pagar: ${pagar.length}, Receber: ${receber.length}');
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
      L.d('[PARSE] Found array with ${cursor.length} items');
      unknown.addAll(_collectFinancialMaps(cursor));
    }

    if (unknown.isNotEmpty) {
      L.d('[PARSE] Splitting ${unknown.length} unknown items');
      return _splitFinancialItems(unknown);
    }
  } catch (e) {
    L.d('[PARSE] Error: $e');
  }
  L.d('[PARSE] Returning empty');
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
      L.d('[SPLIT] Item tipo desconhecido: ${item['tipo']} - $item');
      unknown.add(item);
    }
  }

  L.d('[SPLIT] Result - Pagar: ${pagar.length}, Receber: ${receber.length}, Unknown: ${unknown.length}');
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

int? _intValue(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

int? _empresaIdValue(Map<String, dynamic> item) {
  final direct = _intValue(item['empresaId'] ?? item['empresa_id'] ?? item['empId']);
  if (direct != null) return direct;

  final empresa = item['empresa'];
  if (empresa is Map) {
    return _intValue(empresa['id']);
  }
  return null;
}

String _dateKey(Map<String, dynamic> item) {
  // Verifica primeiro se alguma chave de data é um array [ano,mes,dia]
  // (Jackson sem write-dates-as-timestamps=false serializa LocalDate assim)
  for (final key in const [
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
  ]) {
    final raw = item[key];
    if (raw == null) continue;
    if (raw is List && raw.length >= 3) {
      final y = raw[0];
      final m = raw[1];
      final d = raw[2];
      if (y is int && m is int && d is int) {
        final isoStr =
            '${y.toString()}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
        final parsed = DateTime.tryParse(isoStr);
        if (parsed != null) return DateFormat('yyyy-MM-dd').format(parsed);
      }
    }
    if (raw != null) break; // achou valor não-nulo, para a busca por array
  }

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
  if (value == null) return false;
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

Future<dynamic> _fetchFinancialJson(String url) async {
  try {
    final response = await TenantContext.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
  } catch (_) {}
  return null;
}

class WindowsCalendarScreen extends StatefulWidget {
  const WindowsCalendarScreen({super.key});

  @override
  State<WindowsCalendarScreen> createState() => _WindowsCalendarScreenState();
}

class _WindowsCalendarScreenState extends State<WindowsCalendarScreen> {
  // ── Colors ──────────────────────────────────────────────────────────────
  // (local constants kept for non‑GridColors equivalents)
  static const Color _purpleLight = Color(0xFFF3E5F5);

  // ── State ────────────────────────────────────────────────────────────────
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;
  String _viewMode = 'month';
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

  Future<void> _loadYearSummariesAndMarkers(int year) async {
    final first = DateTime(year, 1, 1);
    final last = DateTime(year, 12, 31);

    _FinancialItems items;
    try {
      items = await _fetchContasCombined(
        dataInicio: _dayParam(first),
        dataFim: _dayParam(last),
      );
    } catch (_) {
      return;
    }
    final pagarList = items.pagar;
    final receberList = items.receber;

    final newMarkers = Map<String, _DayMarkers>.from(_dayMarkers);

    final hoje = DateTime.now();

    void addMarker(String key,
        {bool pagar = false,
        bool receber = false,
        bool pago = false,
        bool recebido = false,
        bool tributo = false,
        bool atrasada = false}) {
      final old = newMarkers[key] ?? const _DayMarkers();
      newMarkers[key] = _DayMarkers(
        hasPagar: old.hasPagar || pagar,
        hasReceber: old.hasReceber || receber,
        hasPago: old.hasPago || pago,
        hasRecebido: old.hasRecebido || recebido,
        hasTributo: old.hasTributo || tributo,
        hasAtrasada: old.hasAtrasada || atrasada,
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
        atrasada: _isVencida(item, hoje),
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
        atrasada: _isVencida(item, hoje),
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

  String _buildUrl(String base, Map<String, String> params) {
    final uri = Uri.parse(base);
    final query = Map<String, String>.from(uri.queryParameters)..addAll(params);
    final empId = TenantContext.empresaId;
    if (empId != null) {
      query.putIfAbsent('empId', () => empId.toString());
    }
    return uri.replace(queryParameters: query).toString();
  }

  Future<dynamic> _getFinancialJson(String url) async {
    return _fetchFinancialJson(url);
  }

  List<Map<String, dynamic>> _parseItems(dynamic body) {
    return _parseFinancialItems(body);
  }

  _FinancialItems _parseGroups(dynamic body) {
    return _parseFinancialGroups(body);
  }

  /// Busca dados financeiros do endpoint calendarioFinanceiro com dataInicio/dataFim.
  Future<_FinancialItems> _fetchContasCombined({
    required String dataInicio,
    required String dataFim,
  }) async {
    final url = _buildUrl(ApiLinks.calendarioFinanceiro, {
      'dataInicio': dataInicio,
      'dataFim': dataFim,
    });
    L.d('[CALENDARIO] GET $url');
    final body = await _fetchFinancialJson(url);
    final items = _parseFinancialGroups(body);
    L.d('[CALENDARIO] Pagar: ${items.pagar.length}, Receber: ${items.receber.length}');

    // Filtra por dia específico quando dataInicio == dataFim (modo dia)
    if (dataInicio == dataFim && dataInicio.length == 10) {
      return _FinancialItems(
        pagar: items.pagar.where((i) => _dateKey(i) == dataInicio).toList(),
        receber: items.receber.where((i) => _dateKey(i) == dataInicio).toList(),
      );
    }
    return items;
  }

  Future<void> _abrirBaixaConta(
    Map<String, dynamic> item, {
    required bool isPagar,
  }) async {
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
              ? BaixaDialog(
                  conta: ContaPagar.fromJson(body),
                )
              : BaixaDialogReceber(
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

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Fix card #440: esta tela (windows/screens/documento_screen.dart) e
  // reutilizada tambem pelo Mobile (mobile/screens/documento_screen.dart ->
  // WindowsCalendarScreen), mas nunca recebeu o Boleto Viewer (copiar linha
  // digitavel + baixar) nem o "Ver anexo" (AnexoFinanceiro) ja implementados
  // no arquivo web/screens/documento_screen.dart -- so tinha o mecanismo
  // legado _abrirPdfAnexo (launchUrl sem header de autenticacao, so
  // funcionava por acaso no Web/Windows abrindo nova aba, nunca funcionou no
  // Mobile). Portado abaixo o mesmo padrao ja usado e validado no arquivo web.

  // Abre o visualizador de anexos da conta (ver/baixar).
  void _abrirAnexosConta(Map<String, dynamic> item, {required bool isPagar}) {
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    final empresaId = _empresaIdValue(item);
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
            empresaId: empresaId,
          ),
        ),
      ),
    );
  }

  // Abre o Boleto Viewer (card #440): busca o primeiro anexo do lancamento
  // e mostra a linha digitavel (copiar) + baixar o PDF. Funciona em
  // Web/Windows (Dialog) e Mobile (bottom sheet), ver showBoletoViewerDialog/
  // showBoletoViewerBottomSheet em boleto_viewer_widget.dart.
  Future<void> _abrirBoletoViewer(Map<String, dynamic> item,
      {required bool isPagar}) async {
    final id = (item['id'] as num?)?.toInt();
    if (id == null) return;
    final empresaId = _empresaIdValue(item);
    try {
      final anexos = await AnexoFinanceiroService().listar(
        id,
        isPagar ? 'PAGAR' : 'RECEBER',
        empresaId: empresaId,
      );
      if (anexos.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Nenhum anexo encontrado para este lançamento.')),
          );
        }
        return;
      }
      final anexo = anexos.first;
      if (!mounted || anexo.id == null) return;
      if (_isMobile) {
        await showBoletoViewerBottomSheet(
          context,
          anexoId: anexo.id!,
          fileName: anexo.fileName,
          empresaId: empresaId,
        );
      } else {
        await showBoletoViewerDialog(
          context,
          anexoId: anexo.id!,
          fileName: anexo.fileName,
          empresaId: empresaId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir boleto: $e')),
        );
      }
    }
  }

  Future<void> _loadMonthMarkers(DateTime month) async {
    setState(() => _loadingMonth = true);
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month,
        DateUtils.getDaysInMonth(month.year, month.month));

    L.d('[CALENDARIO] Carregando marcadores de ${_dayParam(first)} a ${_dayParam(last)}');

    _FinancialItems items;
    try {
      items = await _fetchContasCombined(
        dataInicio: _dayParam(first),
        dataFim: _dayParam(last),
      );
    } catch (e, st) {
      L.d('[CALENDARIO] Erro ao carregar marcadores: $e\n$st');
      if (!mounted) return;
      setState(() => _loadingMonth = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível carregar o calendário: $e'),
          backgroundColor: GridColors.error,
        ),
      );
      return;
    }

    final pagarList = items.pagar;
    final receberList = items.receber;
    L.d('[CALENDARIO] Parsed - Pagar: ${pagarList.length}, Receber: ${receberList.length}');

    final newMarkers = <String, _DayMarkers>{};
    final hoje = DateTime.now();

    void addMarker(String key,
        {bool pagar = false,
        bool receber = false,
        bool pago = false,
        bool recebido = false,
        bool tributo = false,
        bool atrasada = false}) {
      final old = newMarkers[key] ?? const _DayMarkers();
      newMarkers[key] = _DayMarkers(
        hasPagar: old.hasPagar || pagar,
        hasReceber: old.hasReceber || receber,
        hasPago: old.hasPago || pago,
        hasRecebido: old.hasRecebido || recebido,
        hasTributo: old.hasTributo || tributo,
        hasAtrasada: old.hasAtrasada || atrasada,
      );
    }

    for (final item in pagarList) {
      final dateStr = _dateKey(item);
      if (dateStr.isEmpty) {
        L.d('[CALENDARIO] PAGAR sem data: $item');
        continue;
      }
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final isBaixa = _isBaixada(item);
      final tributo = _hasDocumentoFiscal(item);
      addMarker(
        dateStr,
        pagar: !isBaixa,
        pago: isBaixa,
        tributo: tributo,
        atrasada: _isVencida(item, hoje),
      );
    }

    for (final item in receberList) {
      final dateStr = _dateKey(item);
      if (dateStr.isEmpty) {
        L.d('[CALENDARIO] RECEBER sem data: $item');
        continue;
      }
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      final isBaixa = _isBaixada(item);
      final tributo = _hasDocumentoFiscal(item);
      addMarker(
        dateStr,
        receber: !isBaixa,
        recebido: isBaixa,
        tributo: tributo,
        atrasada: _isVencida(item, hoje),
      );
    }

    if (!mounted) return;
    setState(() {
      // Merge: preserva marcadores de outros meses já carregados
      _dayMarkers = {..._dayMarkers, ...newMarkers};
      _loadingMonth = false;
    });
  }

  Future<void> _loadDayData(DateTime day) async {
    setState(() {
      _loadingDay = true;
      _contasPagar = [];
      _contasReceber = [];
    });
    final dayStr = _dayParam(day);

    L.d('[CALENDARIO_DAY] Carregando dia $dayStr');
    final items = await _fetchContasCombined(
      dataInicio: dayStr,
      dataFim: dayStr,
    );
    L.d('[CALENDARIO_DAY] Parsed - Pagar: ${items.pagar.length}, Receber: ${items.receber.length}');

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

    final items = await _fetchContasCombined(
      dataInicio: _dayParam(first),
      dataFim: _dayParam(last),
    );
    final pagarList = items.pagar;
    final receberList = items.receber;

    double totalPagar = 0, totalPago = 0, totalReceber = 0, totalRecebido = 0;

    for (final item in pagarList) {
      final v = _moneyValue(item, 'valor');
      if (_isBaixada(item)) {
        totalPago += v;
      } else if (!_isCancelada(item)) {
        totalPagar += v;
      }
    }
    for (final item in receberList) {
      final v = _moneyValue(item, 'valor');
      if (_isBaixada(item)) {
        totalRecebido += v;
      } else if (!_isCancelada(item)) {
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
      backgroundColor: GridColors.divider,
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: _viewMode == 'day'
                ? _buildSingleDayView()
                : _viewMode == 'year'
                    ? _buildMonthView()
                    : _buildDayView(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: GridColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          // Refresh
          SizedBox(
            width: 40,
            child: _loadingMonth
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: GridColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh,
                        color: GridColors.primary, size: 20),
                    tooltip: 'Atualizar',
                    padding: EdgeInsets.zero,
                    onPressed: () => _loadMonthMarkers(_currentMonth),
                  ),
          ),
          const SizedBox(width: 8),
          // Toggles
          _buildToggleBtn(
            icon: Icons.calendar_view_day,
            label: 'Dia',
            active: _viewMode == 'day',
            onTap: () {
              final day = _selectedDay ?? DateTime.now();
              setState(() {
                _viewMode = 'day';
                _selectedDay = day;
                _currentMonth = DateTime(day.year, day.month);
              });
              _loadMonthMarkers(_currentMonth);
              _loadDayData(day);
            },
          ),
          const SizedBox(width: 6),
          _buildToggleBtn(
            icon: Icons.calendar_view_month,
            label: 'Mês',
            active: _viewMode == 'month',
            onTap: () => setState(() => _viewMode = 'month'),
          ),
          const SizedBox(width: 6),
          _buildToggleBtn(
            icon: Icons.calendar_month,
            label: 'Ano',
            active: _viewMode == 'year',
            onTap: () {
              setState(() => _viewMode = 'year');
              _autoCarregarResumoAno(_currentMonth.year);
            },
          ),
          const Spacer(),
          // Hoje
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: GridColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
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
          color: active ? GridColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? GridColors.primary : GridColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: active ? GridColors.primary : GridColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? GridColors.primary : GridColors.textSecondary,
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
  // Layout: calendário ocupa a tela toda quando nenhum dia selecionado.
  // Ao selecionar um dia: calendário fica em altura fixa (320) e painel de
  // detalhe aparece abaixo em Expanded. Clicar no mesmo dia fecha o painel.
  Widget _buildDayView() {
    final hasSelection = _selectedDay != null;

    Widget calendarCard = Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Column(
          children: [
            _buildMonthNav(),
            const SizedBox(height: 4),
            _buildWeekdayHeaders(),
            const SizedBox(height: 4),
            Expanded(child: ClipRect(child: _buildCalendarGrid())),
            const Divider(height: 12),
            _buildLegend(),
          ],
        ),
      ),
    );

    if (!hasSelection) {
      // Sem seleção: calendário ocupa toda a área disponível
      return calendarCard;
    }

    // Com seleção: calendário em altura adaptativa + painel de detalhe abaixo
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserva no mínimo 180px para o painel de detalhe;
        // max 400 para dar espaço suficiente às rows do grid (≥40px/row × 6 rows)
        final calHeight = (constraints.maxHeight - 180).clamp(200.0, 400.0);
        return Column(
          children: [
            SizedBox(height: calHeight, child: calendarCard),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: _buildDaySidePanel(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingleDayView() {
    if (_selectedDay == null) {
      return const SizedBox.shrink();
    }
    return Center(
      child: SizedBox(
        width: 460,
        child: _buildDaySidePanel(),
      ),
    );
  }

  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () {
            final prev = DateTime(_currentMonth.year, _currentMonth.month - 1);
            setState(() => _currentMonth = prev);
            _loadMonthMarkers(prev);
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child:
                Icon(Icons.chevron_left, color: GridColors.success, size: 20),
          ),
        ),
        Text(
          DateFormat('MMMM yyyy', 'pt_BR').format(_currentMonth),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: GridColors.textSecondary,
          ),
        ),
        InkWell(
          onTap: () {
            final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
            setState(() => _currentMonth = next);
            _loadMonthMarkers(next);
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child:
                Icon(Icons.chevron_right, color: GridColors.success, size: 20),
          ),
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
                      color: GridColors.success,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
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

    final filledCells = startWeekday + daysInMonth;
    final rowCount = (filledCells / 7).ceil();
    final totalCells = rowCount * 7;
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

    while (cells.length < totalCells) {
      cells.add(const SizedBox());
    }

    return Column(
      children: List.generate(rowCount, (row) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: row == rowCount - 1 ? 0 : 2),
            child: Row(
              children: List.generate(7, (col) {
                final index = row * 7 + col;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: col == 6 ? 0 : 2),
                    child: cells[index],
                  ),
                );
              }),
            ),
          ),
        );
      }),
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
    Color textColor = GridColors.textSecondary;

    if (isSelected) {
      bgColor = GridColors.error;
      textColor = Colors.white;
    } else if (markers.hasPagar) {
      bgColor = GridColors.primaryLight;
    } else if (markers.hasReceber) {
      bgColor = GridColors.secondaryLight;
    } else if (isPast &&
        (markers.hasPago || markers.hasRecebido || markers.hasTributo)) {
      bgColor = GridColors.divider;
    }

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          setState(() => _selectedDay = null);
        } else {
          setState(() => _selectedDay = date);
          _loadDayData(date);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? GridColors.error
                : isToday
                    ? GridColors.success
                    : GridColors.divider,
            width: (isToday || isSelected) ? 2 : 0.7,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 1),
            Wrap(
              spacing: 1,
              runSpacing: 1,
              children: [
                if (markers.hasPagar)
                  _miniIcon(Icons.arrow_upward, GridColors.error, 10),
                if (markers.hasReceber)
                  _miniIcon(Icons.arrow_downward, GridColors.success, 10),
                if (markers.hasPago) _miniIcon(Icons.check, Colors.grey, 10),
                if (markers.hasRecebido)
                  _miniIcon(Icons.check_circle, GridColors.success, 10),
                if (markers.hasTributo)
                  Container(
                    decoration: BoxDecoration(
                      color: _purpleLight,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: GridColors.info, width: 1),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: const Icon(Icons.receipt_long,
                        color: GridColors.info, size: 11),
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
        _legendItem(Icons.arrow_upward, GridColors.error, 'A Pagar'),
        _legendItem(Icons.arrow_downward, GridColors.success, 'A Receber'),
        _legendItem(Icons.check, Colors.grey, 'Pago'),
        _legendItem(Icons.check_circle, GridColors.success, 'Recebido'),
        _legendItem(Icons.receipt_long, GridColors.info, 'Doc. Fiscal'),
      ],
    );
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: GridColors.textSecondary)),
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

    final totalPagar =
        _contasPagar.fold<double>(0, (s, i) => s + _moneyValue(i, 'valor'));
    final totalReceber =
        _contasReceber.fold<double>(0, (s, i) => s + _moneyValue(i, 'valor'));
    final saldo = totalReceber - totalPagar;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          // Panel header
          Container(
            decoration: const BoxDecoration(
              color: GridColors.error,
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
                  tooltip: 'Limpar seleção',
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
                ? const Center(
                    child: CircularProgressIndicator(color: GridColors.error))
                : ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      _buildSectionHeader(
                        icon: Icons.arrow_upward,
                        color: GridColors.error,
                        label: 'A Pagar',
                        total: totalPagar,
                        totalColor: GridColors.error,
                      ),
                      ..._contasPagar
                          .map((item) => _buildContaItem(item, isPagar: true)),
                      if (_contasPagar.isEmpty)
                        _emptySection('Nenhuma conta a pagar'),
                      const SizedBox(height: 12),
                      _buildSectionHeader(
                        icon: Icons.arrow_downward,
                        color: GridColors.success,
                        label: 'A Receber',
                        total: totalReceber,
                        totalColor: GridColors.success,
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
    final valor = _moneyValue(item, 'valor');
    final status = _statusValue(item).isEmpty ? 'ABERTA' : _statusValue(item);
    final descricao = item['descricao'] as String? ?? '';
    final tributo = _hasDocumentoFiscal(item);
    final parceiro = item['parceiro'] is Map
        ? (item['parceiro'] as Map).cast<String, dynamic>()
        : null;
    final parceiroNome =
        parceiro?['nome'] as String? ?? item['parceiroNome'] as String? ?? '';

    final qtdAnexos = (item['qtdAnexos'] as num?)?.toInt() ?? 0;

    final today = DateTime.now();
    final vencStr = _dateKey(item);
    final vencDate = DateTime.tryParse(vencStr);
    final isVencida = status == 'ABERTA' &&
        vencDate != null &&
        vencDate.isBefore(DateTime(today.year, today.month, today.day));

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'BAIXADA':
        statusColor = GridColors.success;
        statusLabel = isPagar ? 'PAGO' : 'RECEBIDO';
        break;
      case 'CANCELADA':
        statusColor = Colors.grey;
        statusLabel = 'CANCELADA';
        break;
      default:
        statusColor = GridColors.warning;
        statusLabel = 'ABERTA';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: tributo ? GridColors.info : GridColors.divider,
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
                  border: Border.all(color: GridColors.info),
                ),
                child: const Icon(Icons.receipt_long,
                    color: GridColors.info, size: 14),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                status == 'BAIXADA' ? Icons.check : Icons.arrow_upward,
                color: status == 'BAIXADA'
                    ? Colors.grey
                    : (isPagar ? GridColors.error : GridColors.success),
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
            // Ações rápidas da conta e do PDF anexado.
            if (status == 'ABERTA') ...[
              const SizedBox(width: 4),
              _contaActionButton(
                icon: Icons.price_check,
                color: GridColors.success,
                tooltip: 'Baixar conta',
                onTap: () => _abrirBaixaConta(item, isPagar: isPagar),
              ),
            ],
            // Fix card #440: substituido o mecanismo legado (_abrirPdfAnexo,
            // baseado em fileId/launchUrl sem autenticacao -- so funcionava
            // por acaso no Web/Windows, nunca no Mobile) pelo par Ver anexo +
            // Boleto viewer ja usado no arquivo web/screens/documento_screen.dart,
            // baseado em AnexoFinanceiro (qtdAnexos), com download autenticado
            // e compartilhamento real no Mobile via share_plus.
            if (qtdAnexos > 0) ...[
              const SizedBox(width: 4),
              _contaActionButton(
                icon: Icons.attach_file,
                color: GridColors.info,
                tooltip: 'Ver anexo',
                onTap: () => _abrirAnexosConta(item, isPagar: isPagar),
              ),
              const SizedBox(width: 4),
              _contaActionButton(
                icon: Icons.receipt_long,
                color: GridColors.primary,
                tooltip: 'Boleto viewer',
                onTap: () => _abrirBoletoViewer(item, isPagar: isPagar),
              ),
            ],
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
                    color: isPagar ? GridColors.error : GridColors.success,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVencida)
                      _chip('VENCIDA', GridColors.error, Colors.white),
                    const SizedBox(width: 3),
                    _chip(statusLabel, statusColor, Colors.white),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _contaActionButton({
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
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
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
        color: GridColors.divider,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryCell(
              '-${_currencyFmt.format(pagar)}', 'A Pagar', GridColors.error),
          _summaryCell('+${_currencyFmt.format(receber)}', 'A Receber',
              GridColors.success),
          _summaryCell(
            '${saldo >= 0 ? '+' : ''}${_currencyFmt.format(saldo)}',
            'Saldo',
            saldo >= 0 ? GridColors.success : GridColors.error,
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
                icon: const Icon(Icons.chevron_left, color: GridColors.success),
                tooltip: 'Ano anterior',
                onPressed: () {
                  final novoAno = _currentMonth.year - 1;
                  setState(() {
                    _currentMonth = DateTime(novoAno, 1);
                    _monthSummaries.clear();
                  });
                  _autoCarregarResumoAno(novoAno);
                },
              ),
              Text(
                '$year',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: GridColors.textSecondary),
              ),
              IconButton(
                icon:
                    const Icon(Icons.chevron_right, color: GridColors.success),
                tooltip: 'Próximo ano',
                onPressed: () {
                  final novoAno = _currentMonth.year + 1;
                  setState(() {
                    _currentMonth = DateTime(novoAno, 1);
                    _monthSummaries.clear();
                  });
                  _autoCarregarResumoAno(novoAno);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingMonth
              ? const Center(
                  child: CircularProgressIndicator(color: GridColors.error))
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
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: GridColors.textSecondary),
            ),
            const SizedBox(height: 6),
            // Action buttons
            Row(
              children: [
                _monthActionBtn(
                  icon: Icons.arrow_upward,
                  color: GridColors.error,
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
                  color: GridColors.success,
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
                style: const TextStyle(fontSize: 10, color: GridColors.error),
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
                style: const TextStyle(fontSize: 10, color: GridColors.success),
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
                      ? GridColors.success
                      : GridColors.error,
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
                cellBg = GridColors.primary.withValues(alpha: 0.12);
                borderCol = GridColors.primary.withValues(alpha: 0.55);
                txtCol = GridColors.primary;
              } else if (markers.hasAtrasada) {
                cellBg = const Color(0xFFFFF9C4); // AMARELA (atrasada)
                borderCol = const Color(0xFFFFF59D);
                txtCol = const Color(0xFFF57F17);
              } else if (markers.hasPagar || markers.hasReceber) {
                cellBg = const Color(0xFFFFEBEE); // VERMELHA (aberta/pra vencer)
                borderCol = const Color(0xFFFFCDD2);
                txtCol = GridColors.error;
              } else if (markers.hasPago || markers.hasRecebido) {
                cellBg = const Color(0xFFE8F5E9); // VERDE (paga)
                borderCol = const Color(0xFFC8E6C9);
                txtCol = GridColors.success;
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
                                    color: GridColors.primary,
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
                                    color: GridColors.secondary,
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

  Widget _dot(Color color) => Container(
        width: 5,
        height: 5,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

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

  /// Carrega o ano inteiro em UMA chamada (Jan/1 → Dez/31) e distribui pelos meses.
  void _autoCarregarResumoAno(int year) {
    _carregarAnoCompleto(year);
  }

  Future<void> _carregarAnoCompleto(int year) async {
    setState(() => _loadingMonth = true);
    final dataInicio = '$year-01-01';
    final dataFim = '$year-12-31';

    final url = _buildUrl(ApiLinks.calendarioFinanceiro, {
      'dataInicio': dataInicio,
      'dataFim': dataFim,
    });
    L.d('[CALENDARIO_ANO] GET $url');
    final body = await _fetchFinancialJson(url);
    final allItems = _parseFinancialGroups(body);
    L.d('[CALENDARIO_ANO] Total - Pagar: ${allItems.pagar.length}, Receber: ${allItems.receber.length}');

    if (!mounted) return;

    // Distribui itens por mês
    final newMarkers = <String, _DayMarkers>{};
    final summaries = <int, _MonthSummary>{};
    final perMonth = <int, _FinancialItems>{};

    for (int m = 1; m <= 12; m++) {
      perMonth[m] = _FinancialItems(
        pagar: allItems.pagar.where((i) {
          final d = DateTime.tryParse(_dateKey(i));
          return d != null && d.month == m && d.year == year;
        }).toList(),
        receber: allItems.receber.where((i) {
          final d = DateTime.tryParse(_dateKey(i));
          return d != null && d.month == m && d.year == year;
        }).toList(),
      );
    }

    // Monta dayMarkers e summaries
    for (final entry in perMonth.entries) {
      final m = entry.key;
      final items = entry.value;
      double totalPagar = 0, totalPago = 0, totalReceber = 0, totalRecebido = 0;

      for (final item in items.pagar) {
        final dateStr = _dateKey(item);
        if (dateStr.isEmpty) continue;
        final isBaixa = _isBaixada(item);
        final tributo = _hasDocumentoFiscal(item);
        final old = newMarkers[dateStr] ?? const _DayMarkers();
        newMarkers[dateStr] = _DayMarkers(
          hasPagar: old.hasPagar || !isBaixa,
          hasPago: old.hasPago || isBaixa,
          hasReceber: old.hasReceber,
          hasRecebido: old.hasRecebido,
          hasTributo: old.hasTributo || tributo,
        );
        final v = _moneyValue(item, 'valor');
        if (isBaixa)
          totalPago += v;
        else if (!_isCancelada(item)) totalPagar += v;
      }

      for (final item in items.receber) {
        final dateStr = _dateKey(item);
        if (dateStr.isEmpty) continue;
        final isBaixa = _isBaixada(item);
        final tributo = _hasDocumentoFiscal(item);
        final old = newMarkers[dateStr] ?? const _DayMarkers();
        newMarkers[dateStr] = _DayMarkers(
          hasPagar: old.hasPagar,
          hasPago: old.hasPago,
          hasReceber: old.hasReceber || !isBaixa,
          hasRecebido: old.hasRecebido || isBaixa,
          hasTributo: old.hasTributo || tributo,
        );
        final v = _moneyValue(item, 'valor');
        if (isBaixa)
          totalRecebido += v;
        else if (!_isCancelada(item)) totalReceber += v;
      }

      summaries[m] = _MonthSummary(
        totalPagar: totalPagar,
        totalPago: totalPago,
        totalReceber: totalReceber,
        totalRecebido: totalRecebido,
        saldoPagar: totalPago - totalPagar,
        saldoReceber: totalRecebido - totalReceber,
      );
    }

    setState(() {
      _dayMarkers = {..._dayMarkers, ...newMarkers};
      _monthSummaries.addAll(summaries);
      _loadingMonth = false;
    });
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
  // (local constants kept for non‑GridColors equivalents)
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
    final body = await _fetchFinancialJson(widget.url);
    if (!mounted) return;
    final items = _parseFinancialItems(body);
    setState(() {
      _abertas =
          items.where((i) => !_isBaixada(i) && !_isCancelada(i)).toList();
      _baixadas = items.where(_isBaixada).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAberto =
        _abertas.fold<double>(0, (s, i) => s + _moneyValue(i, 'valor'));
    final totalBaixado =
        _baixadas.fold<double>(0, (s, i) => s + _moneyValue(i, 'valor'));
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
                color: widget.isPagar ? GridColors.error : GridColors.success,
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
                    tooltip: 'Fechar',
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
                  ? const Center(
                      child: CircularProgressIndicator(color: GridColors.error))
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _sectionTitle('Em Aberto', GridColors.warning),
                        ..._abertas.map((i) => _dialogItem(i)),
                        if (_abertas.isEmpty)
                          _emptyMsg('Nenhum item em aberto'),
                        const SizedBox(height: 12),
                        _sectionTitle(
                          widget.isPagar ? 'Pagas' : 'Recebidas',
                          GridColors.success,
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
                color: GridColors.divider,
                border: Border(top: BorderSide(color: GridColors.divider)),
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
                            color: widget.isPagar
                                ? GridColors.error
                                : GridColors.warning),
                      ),
                      Text(
                        widget.currencyFmt.format(totalAberto),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: widget.isPagar
                              ? GridColors.error
                              : GridColors.warning,
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
                        style: const TextStyle(
                            fontSize: 12, color: GridColors.success),
                      ),
                      Text(
                        widget.currencyFmt.format(totalBaixado),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: GridColors.success,
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
                          color: saldo >= 0
                              ? GridColors.success
                              : GridColors.error,
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
    final valor = _moneyValue(item, 'valor');
    final descricao = item['descricao'] as String? ?? '';
    final tributo = _hasDocumentoFiscal(item);
    final parceiro = item['parceiro'] is Map
        ? (item['parceiro'] as Map).cast<String, dynamic>()
        : null;
    final parceiroNome =
        parceiro?['nome'] as String? ?? item['parceiroNome'] as String? ?? '';
    final vencStr = _dateKey(item);
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
          color: tributo ? GridColors.info : GridColors.divider,
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
                  border: Border.all(color: GridColors.info),
                ),
                child: const Icon(Icons.receipt_long,
                    color: GridColors.info, size: 14),
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
            color: widget.isPagar ? GridColors.error : GridColors.success,
          ),
        ),
      ),
    );
  }

  Widget _emptyMsg(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(msg,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
          textAlign: TextAlign.center),
    );
  }
}

// ─── Web alias ───────────────────────────────────────────────────────────────
typedef WebCalendarScreen = WindowsCalendarScreen;
