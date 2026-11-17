import 'package:flutter/material.dart';

import '../../services/dp_ponto_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_colors.dart';

/// Banco de horas CLT: extrato por funcionario, alerta de saldo vencido/vencendo e quitacao em folha.
/// Mesma tela em Web, Windows e Mobile.
class DpBancoHorasScreen extends StatefulWidget {
  const DpBancoHorasScreen({super.key, this.service});

  /// Injetavel para teste.
  final DpPontoService? service;

  @override
  State<DpBancoHorasScreen> createState() => _DpBancoHorasScreenState();
}

class _DpBancoHorasScreenState extends State<DpBancoHorasScreen> {
  late final DpPontoService _service = widget.service ?? DpPontoService();

  List<Map<String, dynamic>> _funcionarios = [];
  List<Map<String, dynamic>> _alertas = [];
  Map<String, dynamic>? _extrato;
  int? _funcionarioId;
  bool _carregando = true;
  bool _executando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarInicial();
  }

  Future<void> _carregarInicial() async {
    try {
      final r = await Future.wait([_service.funcionarios(), _service.alertasBanco()]);
      if (!mounted) return;
      setState(() {
        _funcionarios = r[0];
        _alertas = r[1];
      });
    } on DpPontoException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao carregar banco de horas: $e', st);
      if (mounted) setState(() => _erro = 'Não foi possível carregar o banco de horas.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _carregarExtrato() async {
    final id = _funcionarioId;
    if (id == null) return;
    setState(() { _carregando = true; _erro = null; });
    try {
      final e = await _service.extratoBanco(id);
      if (mounted) setState(() => _extrato = e);
    } on DpPontoException catch (e) {
      if (mounted) setState(() { _extrato = null; _erro = e.message; });
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao consultar extrato do banco de horas: $e', st);
      if (mounted) setState(() { _extrato = null; _erro = 'Não foi possível consultar o extrato.'; });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _aviso(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? GridColors.error : GridColors.primary,
    ));
  }

  Future<void> _quitar() async {
    final id = _funcionarioId;
    final ext = _extrato?['extrato'] as Map?;
    if (id == null || ext == null) return;
    final vencido = (ext['vencido'] as num? ?? 0).toInt();
    final hoje = DateTime.now();
    final minutosCtl = TextEditingController();
    final obsCtl = TextEditingController();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar banco de horas em folha'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Saldo vencido: ${formatarMinutos(vencido)}. Será pago como hora extra de 50% na folha '
              '${hoje.month.toString().padLeft(2, '0')}/${hoje.year}.'),
          TextField(
            key: const Key('dp_quitar_minutos'),
            controller: minutosCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minutos (vazio = todo o vencido)'),
          ),
          TextField(controller: obsCtl, maxLength: 200, decoration: const InputDecoration(labelText: 'Observação')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (confirmou != true) return;
    final minutos = int.tryParse(minutosCtl.text.trim());
    setState(() => _executando = true);
    try {
      final r = await _service.quitarBanco(id, hoje.month, hoje.year, minutos: minutos, observacao: obsCtl.text.trim());
      if (!mounted) return;
      _aviso('Quitados ${formatarMinutos(r['minutos'] as num? ?? 0)} na folha ${hoje.month}/${hoje.year}.');
      await _carregarExtrato();
      _alertas = await _service.alertasBanco();
    } on DpPontoException catch (e) {
      _aviso(e.message, erro: true);
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao quitar banco de horas: $e', st);
      _aviso('Não foi possível quitar o banco de horas.', erro: true);
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GridColors.pageBackground,
      child: RefreshIndicator(
        onRefresh: () async { await _carregarInicial(); await _carregarExtrato(); },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _filtro(),
            const SizedBox(height: 16),
            if (_carregando) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            if (_erro != null)
              Card(
                color: GridColors.errorLight,
                child: Padding(padding: const EdgeInsets.all(16), child: Text(_erro!, style: const TextStyle(color: GridColors.errorDark))),
              ),
            if (_alertas.isNotEmpty) _cartaoAlertas(),
            if (!_carregando && _extrato != null) ..._conteudoExtrato(_extrato!),
          ],
        ),
      ),
    );
  }

  Widget _filtro() => Card(
        color: GridColors.card,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            const Text('Banco de horas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<int>(
                key: const Key('dp_banco_funcionario'),
                value: _funcionarioId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Funcionário', border: OutlineInputBorder()),
                items: _funcionarios
                    .map((f) => DropdownMenuItem<int>(value: (f['id'] as num).toInt(), child: Text('${f['nome'] ?? f['id']}', overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: _executando ? null : (v) { setState(() => _funcionarioId = v); _carregarExtrato(); },
              ),
            ),
          ]),
        ),
      );

  Widget _cartaoAlertas() => Card(
        color: GridColors.card,
        child: ExpansionTile(
          key: const Key('dp_banco_alertas'),
          initiallyExpanded: true,
          leading: const Icon(Icons.warning_amber_rounded, color: GridColors.warningDark),
          title: Text('Saldo vencido ou vencendo em 30 dias (${_alertas.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
          children: _alertas.map((a) => ListTile(
                dense: true,
                title: Text('${a['nome']}'),
                subtitle: Text('Vencido ${formatarMinutos(a['vencidoMin'] as num? ?? 0)} · vencendo ${formatarMinutos(a['vencendoMin'] as num? ?? 0)}'
                    '${a['primeiroVencimento'] != null ? ' · desde ${_dataBr('${a['primeiroVencimento']}')}' : ''}'),
              )).toList(),
        ),
      );

  List<Widget> _conteudoExtrato(Map<String, dynamic> dados) {
    if (dados['bancoAtivo'] != true) {
      return [
        const Card(
          color: GridColors.card,
          child: Padding(padding: EdgeInsets.all(16), child: Text('A escala deste funcionário não usa banco de horas.')),
        )
      ];
    }
    final e = Map<String, dynamic>.from(dados['extrato'] as Map);
    final linhas = (e['linhas'] as List).whereType<Map>().toList();
    final lotes = (e['lotes'] as List).whereType<Map>().toList();
    final vencido = (e['vencido'] as num).toInt();
    return [
      Text('Acordo ${dados['acordo']} · compensação em até ${dados['prazoMeses']} meses (CLT art. 59)',
          style: const TextStyle(color: GridColors.textSecondary)),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _indicador('Saldo', formatarMinutos(e['saldo'] as num), GridColors.primary),
        _indicador('Vencido', formatarMinutos(vencido), vencido > 0 ? GridColors.error : GridColors.success),
        _indicador('Vencendo (30 dias)', formatarMinutos(e['vencendo'] as num), GridColors.warningDark),
        _indicador('A vencer', formatarMinutos(e['aVencer'] as num), GridColors.textSecondary),
      ]),
      const SizedBox(height: 12),
      FilledButton.icon(
        key: const Key('dp_quitar'),
        onPressed: _executando || vencido <= 0 ? null : _quitar,
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Quitar vencido em folha'),
      ),
      const SizedBox(height: 16),
      Card(
        color: GridColors.card,
        child: ExpansionTile(
          key: const Key('dp_banco_lotes'),
          initiallyExpanded: lotes.isNotEmpty,
          title: Text('Saldo por competência e vencimento (${lotes.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
          children: lotes.map((l) => ListTile(
                dense: true,
                title: Text('${l['competencia']} · ${formatarMinutos(l['minutos'] as num)}'),
                subtitle: Text('Vence em ${_dataBr('${l['vencimento']}')}'),
                trailing: Text(_situacao('${l['situacao']}'), style: TextStyle(color: _corSituacao('${l['situacao']}'), fontWeight: FontWeight.w600)),
              )).toList(),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        color: GridColors.card,
        child: ExpansionTile(
          key: const Key('dp_banco_extrato'),
          initiallyExpanded: true,
          title: const Text('Extrato mensal', style: TextStyle(fontWeight: FontWeight.w600)),
          children: linhas.reversed.map((l) => ListTile(
                dense: true,
                title: Text('${l['competencia']}'),
                subtitle: Text('Crédito ${formatarMinutos(l['credito'] as num)} · débito ${formatarMinutos(l['debito'] as num)}'
                    ' · quitado ${formatarMinutos(l['quitado'] as num)}'),
                trailing: Text(formatarMinutos(l['saldoAcumulado'] as num), style: const TextStyle(fontWeight: FontWeight.w700)),
              )).toList(),
        ),
      ),
    ];
  }

  Widget _indicador(String titulo, String valor, Color cor) => SizedBox(
        width: 180,
        child: Card(
          color: GridColors.card,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(color: GridColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(valor, style: TextStyle(color: cor, fontSize: 24, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );

  static String _situacao(String s) => switch (s) { 'VENCIDO' => 'Vencido', 'VENCENDO' => 'Vencendo', _ => 'A vencer' };

  static Color _corSituacao(String s) => switch (s) {
        'VENCIDO' => GridColors.error,
        'VENCENDO' => GridColors.warningDark,
        _ => GridColors.textSecondary,
      };

  static String _dataBr(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }
}
