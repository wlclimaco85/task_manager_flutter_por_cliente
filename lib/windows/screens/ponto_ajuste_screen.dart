import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:intl/intl.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../utils/grid_texts.dart';

const _primary = GridColors.primary;
const _green   = GridColors.secondary;
const _bg      = GridColors.pageBackground;
const _white   = GridColors.card;
const _border  = GridColors.borderSubtle;

// ── Status colors ─────────────────────────────────────────────────────────────
Color _statusColor(String s) => switch (s) {
  'OK'         => GridColors.success,
  'FALTA'      => GridColors.error,
  'INCOMPLETO' => GridColors.warningDark,
  'FERIADO'    => GridColors.statusHoliday,
  'FOLGA'      => GridColors.neutral,
  _            => GridColors.neutral,
};

IconData _statusIcon(String s) => switch (s) {
  'OK'         => Icons.check_circle_outline,
  'FALTA'      => Icons.cancel_outlined,
  'INCOMPLETO' => Icons.warning_amber_outlined,
  'FERIADO'    => Icons.celebration_outlined,
  'FOLGA'      => Icons.weekend_outlined,
  _            => Icons.help_outline,
};

/// Tela de ajuste de ponto — para gestores.
/// Seleciona funcionário + mês não fechado → lista todos os dias com batidas.
/// Cada dia tem botão de ajuste para editar/adicionar/remover batidas.
class WindowsPontoAjusteScreen extends StatefulWidget {
  const WindowsPontoAjusteScreen({super.key});
  @override
  State<WindowsPontoAjusteScreen> createState() => _WebPontoAjusteScreenState();
}

class _WebPontoAjusteScreenState extends State<WindowsPontoAjusteScreen> {
  List<dynamic> _funcionarios = [];
  List<Map<String, dynamic>> _mesesAbertos = [];
  List<Map<String, dynamic>> _dias = [];

  int? _funcionarioId;
  Map<String, dynamic>? _mesSelecionado;
  bool _loadingFunc = false;
  bool _loadingDias = false;

  @override
  void initState() {
    super.initState();
    _carregarFuncionarios();
  }

  Future<void> _carregarFuncionarios() async {
    setState(() => _loadingFunc = true);
    final resp = await TenantContext.get('${ApiLinks.baseUrl}/api/funcionario?tamanho=200');
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      List lista = [];
      if (body is Map) {
        final d = body['data'];
        if (d is Map) {
          lista = d['dados'] ?? d['content'] ?? [];
        } else if (d is List) lista = d;
      }
      setState(() => _funcionarios = lista);
    }
    if (mounted) setState(() => _loadingFunc = false);
  }

  Future<void> _carregarMeses(int funcId) async {
    setState(() { _mesesAbertos = []; _mesSelecionado = null; _dias = []; });
    final url = '${ApiLinks.baseUrl}/api/folha-ponto/meses-abertos?funcionarioId=$funcId';
    final resp = await TenantContext.get(url);
    if (resp.statusCode == 200) {
      final lista = jsonDecode(resp.body) as List;
      setState(() {
        _mesesAbertos = lista.map((e) => Map<String, dynamic>.from(e)).toList();
        // Seleciona o mês mais recente automaticamente
        if (_mesesAbertos.isNotEmpty) {
          _mesSelecionado = _mesesAbertos.first;
          _carregarDias();
        }
      });
    }
  }

  Future<void> _carregarDias() async {
    if (_funcionarioId == null || _mesSelecionado == null) return;
    setState(() { _loadingDias = true; _dias = []; });
    final mes = _mesSelecionado!['mes'];
    final ano = _mesSelecionado!['ano'];
    final url = '${ApiLinks.baseUrl}/api/folha-ponto/dias'
        '?funcionarioId=$_funcionarioId&mes=$mes&ano=$ano';
    final resp = await TenantContext.get(url);
    if (resp.statusCode == 200) {
      final lista = jsonDecode(resp.body) as List;
      setState(() => _dias = lista.map((e) => Map<String, dynamic>.from(e)).toList());
    }
    if (mounted) setState(() => _loadingDias = false);
  }

  Future<void> _fecharFolha() async {
    if (_funcionarioId == null || _mesSelecionado == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(GridTexts.closeSheet),
        content: Text(GridTexts.closeSheetConfirm(_mesSelecionado!['label'].toString())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(GridTexts.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: GridColors.textPrimary),
            child: const Text(GridTexts.close),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final resp = await TenantContext.post('${ApiLinks.baseUrl}/api/folha-ponto/fechar', {
      'funcionarioId': _funcionarioId,
      'mes': _mesSelecionado!['mes'],
      'ano': _mesSelecionado!['ano'],
    });
    if (resp.statusCode == 200) {
      _snack(GridTexts.closeSheetSuccess);
      _carregarMeses(_funcionarioId!);
    } else {
      _snack(GridTexts.closeSheetError);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary, foregroundColor: GridColors.textPrimary, elevation: 2,
        title: const Row(children: [
          Icon(Icons.manage_history, size: 20), SizedBox(width: 8),
          Text(GridTexts.timeAdjustmentTitle, style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          if (_mesSelecionado != null && _mesSelecionado!['status'] != 'FECHADO')
            TextButton.icon(
              onPressed: _fecharFolha,
              icon: const Icon(Icons.lock_outline, color: GridColors.textPrimary, size: 16),
              label: const Text(GridTexts.closeSheet, style: TextStyle(color: GridColors.textPrimary, fontSize: 12)),
            ),
          if (_funcionarioId != null)
            IconButton(onPressed: _carregarDias, icon: const Icon(Icons.refresh), tooltip: GridTexts.refresh),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        _buildFiltros(),
        if (_loadingDias) const LinearProgressIndicator(color: _primary),
        Expanded(child: _buildConteudo()),
      ]),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _white,
      child: Row(children: [
        // Funcionário
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<int>(
            initialValue: _funcionarioId,
            decoration: const InputDecoration(
              labelText: GridTexts.employee, border: OutlineInputBorder(), isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            hint: _loadingFunc ? const Text(GridTexts.loading) : const Text(GridTexts.select),
            items: _funcionarios.map<DropdownMenuItem<int>>((f) {
              final id = f['id'] as int?;
              final nome = f['nome']?.toString() ?? f['id']?.toString() ?? '';
              return DropdownMenuItem(value: id, child: Text(nome, overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (v) {
              setState(() { _funcionarioId = v; });
              if (v != null) _carregarMeses(v);
            },
          ),
        ),
        const SizedBox(width: 12),
        // Mês (só meses não fechados)
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _mesSelecionado,
            decoration: InputDecoration(
              labelText: GridTexts.month,
              border: const OutlineInputBorder(), isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              suffixIcon: _mesSelecionado != null
                  ? _statusChip(_mesSelecionado!['status']?.toString() ?? 'ABERTO')
                  : null,
            ),
            hint: const Text(GridTexts.selectMonth),
            items: _mesesAbertos.map((m) => DropdownMenuItem(
              value: m,
              child: Row(children: [
                Text(m['label']?.toString() ?? ''),
                const SizedBox(width: 6),
                _statusChip(m['status']?.toString() ?? 'ABERTO'),
              ]),
            )).toList(),
            onChanged: (v) {
              setState(() => _mesSelecionado = v);
              _carregarDias();
            },
          ),
        ),
        // Resumo
        if (_dias.isNotEmpty) ...[
          const SizedBox(width: 16),
          _buildResumo(),
        ],
      ]),
    );
  }

  Widget _statusChip(String status) {
    final color = switch (status) {
      'FECHADO'     => GridColors.statusClosed,
      'ACEITO_FUNC' => _green,
      _             => GridColors.statusNew,
    };
    final label = switch (status) {
      'FECHADO'     => GridTexts.closed,
      'ACEITO_FUNC' => GridTexts.accepted,
      _             => GridTexts.open,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildResumo() {
    final ok = _dias.where((d) => d['status'] == 'OK').length;
    final falta = _dias.where((d) => d['status'] == 'FALTA').length;
    final incompleto = _dias.where((d) => d['status'] == 'INCOMPLETO').length;
    return Row(children: [
      _resumoBadge('OK', ok, _statusColor('OK')),
      const SizedBox(width: 6),
      _resumoBadge(GridTexts.absence, falta, _statusColor('FALTA')),
      const SizedBox(width: 6),
      _resumoBadge(GridTexts.incomplete, incompleto, _statusColor('INCOMPLETO')),
    ]);
  }

  Widget _resumoBadge(String label, int count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Text('$label: $count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _buildConteudo() {
    if (_funcionarioId == null) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_search, size: 64, color: GridColors.neutral),
        SizedBox(height: 12),
        Text(GridTexts.selectEmployeeFirst, style: TextStyle(color: GridColors.neutral, fontSize: 16)),
      ]));
    }
    if (_mesesAbertos.isEmpty && !_loadingDias) {
      return const Center(child: Text(GridTexts.noOpenMonthFound, style: TextStyle(color: GridColors.neutral)));
    }
    if (_dias.isEmpty && !_loadingDias) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _dias.length,
      itemBuilder: (_, i) => _buildDiaCard(_dias[i]),
    );
  }

  Widget _buildDiaCard(Map<String, dynamic> dia) {
    final status = dia['status']?.toString() ?? 'FOLGA';
    final isDiaUtil = dia['isDiaUtil'] == true;
    final isFeriado = dia['isFeriado'] == true;
    final batidas = (dia['batidas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 5),
      color: isDiaUtil ? _white : GridColors.surfaceMuted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDiaUtil ? color.withValues(alpha: 0.3) : _border,
          width: isDiaUtil ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          // Data
          SizedBox(
            width: 72,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dia['diaSemana']?.toString().toUpperCase() ?? '',
                  style: TextStyle(fontSize: 10, color: isDiaUtil ? _primary : GridColors.neutral,
                      fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text('${dia['dia']}/${_mesSelecionado?['mes'].toString().padLeft(2, '0') ?? ''}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                      color: isDiaUtil ? GridColors.textSecondary : GridColors.neutral)),
            ]),
          ),
          // Status icon
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(_statusIcon(status), color: color, size: 16),
          ),
          const SizedBox(width: 10),
          // Batidas
          Expanded(
            child: isFeriado
                ? Text(dia['data'] != null ? _nomeFeriado(dia['data'].toString()) : GridTexts.holiday,
                    style: TextStyle(color: _statusColor('FERIADO'), fontSize: 12, fontStyle: FontStyle.italic))
                : !isDiaUtil
                    ? const Text(GridTexts.dayOff, style: TextStyle(color: GridColors.neutral, fontSize: 12))
                    : batidas.isEmpty
                        ? const Text(GridTexts.noRecords, style: TextStyle(color: GridColors.neutral, fontSize: 12))
                        : Wrap(
                            spacing: 6, runSpacing: 4,
                            children: batidas.map((b) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _green.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _green.withValues(alpha: 0.3)),
                              ),
                              child: Text(b['hora']?.toString() ?? '',
                                  style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
                            )).toList(),
                          ),
          ),
          // Botão ajuste (só dias úteis e mês não fechado)
          if (isDiaUtil && _mesSelecionado?['status'] != 'FECHADO')
            TextButton.icon(
              onPressed: () => _abrirAjuste(dia),
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text(GridTexts.adjust, style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: _primary, padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
        ]),
      ),
    );
  }

  String _nomeFeriado(String dataStr) => GridTexts.holiday;
  Future<void> _abrirAjuste(Map<String, dynamic> dia) async {
    final batidas = List<Map<String, dynamic>>.from(
        (dia['batidas'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? []);
    final dataStr = dia['data']?.toString() ?? '';
    final data = DateTime.tryParse(dataStr) ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (_) => _AjusteDialog(
        data: data,
        batidas: batidas,
        funcionarioId: _funcionarioId!,
        onSaved: () {
          _snack(GridTexts.adjustmentSaved);
          _carregarDias();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog de ajuste de batidas de um dia
// ─────────────────────────────────────────────────────────────────────────────
class _AjusteDialog extends StatefulWidget {
  final DateTime data;
  final List<Map<String, dynamic>> batidas;
  final int funcionarioId;
  final VoidCallback onSaved;
  const _AjusteDialog({required this.data, required this.batidas, required this.funcionarioId, required this.onSaved});
  @override
  State<_AjusteDialog> createState() => _AjusteDialogState();
}

class _AjusteDialogState extends State<_AjusteDialog> {
  late List<Map<String, dynamic>> _batidas;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _batidas = List.from(widget.batidas);
  }

  Future<void> _adicionarBatida() async {
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (hora == null) return;
    final dt = DateTime(widget.data.year, widget.data.month, widget.data.day, hora.hour, hora.minute);
    setState(() => _batidas.add({
      'hora': '${hora.hour.toString().padLeft(2,'0')}:${hora.minute.toString().padLeft(2,'0')}',
      'dataHora': dt.toIso8601String(),
      '_novo': true,
    }));
    // Ordena por hora
    _batidas.sort((a, b) => (a['hora'] ?? '').compareTo(b['hora'] ?? ''));
  }

  void _remover(int idx) => setState(() => _batidas.removeAt(idx));

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      final empresaId = TenantContext.empresaId;
      // Cria solicitação de ajuste
      final solResp = await TenantContext.post('${ApiLinks.baseUrl}/api/ponto-ajuste/solicitacoes', {
        'funcionario': {'id': widget.funcionarioId},
        if (empresaId != null) 'empresa': {'id': empresaId},
        'dataPonto': DateFormat('yyyy-MM-dd').format(widget.data),
        'motivo': GridTexts.manualAdjustmentReason,
      });
      if (solResp.statusCode != 200) {
        _snack(GridTexts.adjustmentRequestError);
        setState(() => _saving = false);
        return;
      }
      final solId = jsonDecode(solResp.body)['id'];
      // Salva batidas novas
      for (final b in _batidas.where((b) => b['_novo'] == true)) {
        await TenantContext.post('${ApiLinks.baseUrl}/api/ponto-ajuste/batidas', {
          'solicitacao': {'id': solId},
          'funcionario': {'id': widget.funcionarioId},
          if (empresaId != null) 'empresa': {'id': empresaId},
          'dataHora': b['dataHora'],
          'tipo': 'ENTRADA',
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      _snack(GridTexts.genericError(e.toString()));
    }
    if (mounted) setState(() => _saving = false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _white,
      title: Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(DateFormat('dd/MM/yyyy (EEE)', 'pt_BR').format(widget.data),
            style: const TextStyle(color: _primary, fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_batidas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(GridTexts.noPunchesThisDay, style: TextStyle(color: GridColors.neutral)),
            )
          else
            ..._batidas.asMap().entries.map((e) {
              final idx = e.key;
              final b = e.value;
              final isNovo = b['_novo'] == true;
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: (isNovo ? GridColors.statusNew : _green).withValues(alpha: 0.15),
                  child: Text('${idx + 1}', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: isNovo ? GridColors.statusNew : _green)),
                ),
                title: Text(b['hora']?.toString() ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        color: isNovo ? GridColors.statusNew : GridColors.textSecondary)),
                subtitle: Text(isNovo ? GridTexts.newPunch : GridTexts.registered,
                    style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: _primary, size: 18),
                  onPressed: () => _remover(idx),
                  tooltip: GridTexts.remove,
                ),
              );
            }),
          const Divider(),
          TextButton.icon(
            onPressed: _adicionarBatida,
            icon: const Icon(Icons.add_circle_outline, color: _green),
            label: const Text(GridTexts.addPunch, style: TextStyle(color: _green)),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(GridTexts.cancel)),
        ElevatedButton.icon(
          onPressed: _saving ? null : _salvar,
          icon: _saving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _white))
              : const Icon(Icons.save_outlined, size: 14),
          label: Text(_saving ? GridTexts.saving : GridTexts.save),
          style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: _white),
        ),
      ],
    );
  }
}
