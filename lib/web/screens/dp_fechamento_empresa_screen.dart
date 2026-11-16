import 'package:flutter/material.dart';

import '../../services/dp_ponto_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_colors.dart';

/// Fechamento do ponto da empresa por competencia (Departamento Pessoal).
/// Mesma tela em Web, Windows e Mobile (o wrapper mobile so adiciona a AppBar); layout se adapta a largura.
class DpFechamentoEmpresaScreen extends StatefulWidget {
  const DpFechamentoEmpresaScreen({super.key, this.service});

  /// Injetavel para teste.
  final DpPontoService? service;

  @override
  State<DpFechamentoEmpresaScreen> createState() => _DpFechamentoEmpresaScreenState();
}

class _DpFechamentoEmpresaScreenState extends State<DpFechamentoEmpresaScreen> {
  late final DpPontoService _service = widget.service ?? DpPontoService();

  List<Map<String, dynamic>> _competencias = [];
  Map<String, dynamic>? _selecionada;
  Map<String, dynamic>? _previa;
  bool _carregando = true;
  bool _executando = false;
  String? _erro;

  static const _meses = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];

  @override
  void initState() {
    super.initState();
    _carregarCompetencias();
  }

  String _rotulo(Map<String, dynamic> c) {
    final m = (c['mes'] as num).toInt();
    return '${_meses[m - 1][0].toUpperCase()}${_meses[m - 1].substring(1)}/${c['ano']}';
  }

  bool get _fechada => _previa?['status'] == 'FECHADO';

  Future<void> _carregarCompetencias() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      _competencias = await _service.competencias();
      _selecionada = _competencias.isNotEmpty ? _competencias.first : null;
      if (_selecionada != null) await _carregarPrevia();
    } on DpPontoException catch (e) {
      _erro = e.message;
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao carregar competências: $e');
      _erro = 'Não foi possível carregar as competências.';
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _carregarPrevia() async {
    final c = _selecionada;
    if (c == null) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final p = await _service.previa((c['mes'] as num).toInt(), (c['ano'] as num).toInt());
      if (mounted) setState(() => _previa = p);
    } on DpPontoException catch (e) {
      if (mounted) setState(() { _previa = null; _erro = e.message; });
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao calcular prévia: $e', st);
      if (mounted) setState(() { _previa = null; _erro = 'Não foi possível calcular a prévia.'; });
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

  Future<void> _fechar({bool forcar = false}) async {
    final c = _selecionada;
    if (c == null) return;
    setState(() => _executando = true);
    try {
      final p = await _service.fechar((c['mes'] as num).toInt(), (c['ano'] as num).toInt(), forcar: forcar);
      if (!mounted) return;
      setState(() => _previa = p);
      _aviso('Competência ${_rotulo(c)} fechada.');
      await _atualizarLista();
    } on DpPontoException catch (e) {
      if (e.statusCode == 409 && e.previa != null) {
        setState(() => _previa = e.previa);
        await _confirmarForcar(e.message);
      } else {
        _aviso(e.message, erro: true);
      }
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao fechar competência: $e', st);
      _aviso('Não foi possível fechar a competência.', erro: true);
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  Future<void> _confirmarForcar(String msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Há pendências bloqueantes'),
        content: Text('$msg\n\nFechar assim mesmo trava o mês, e os funcionários com pendência ficam com o cálculo atual.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar e resolver')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GridColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Fechar mesmo assim'),
          ),
        ],
      ),
    );
    if (ok == true) await _fechar(forcar: true);
  }

  Future<void> _reabrir() async {
    final c = _selecionada;
    if (c == null) return;
    final controller = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reabrir ${_rotulo(c)}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 300,
          decoration: const InputDecoration(labelText: 'Motivo da reabertura (obrigatório)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Reabrir')),
        ],
      ),
    );
    if (motivo == null || motivo.isEmpty) return;
    setState(() => _executando = true);
    try {
      final p = await _service.reabrir((c['mes'] as num).toInt(), (c['ano'] as num).toInt(), motivo);
      if (!mounted) return;
      setState(() => _previa = p);
      _aviso('Competência ${_rotulo(c)} reaberta.');
      await _atualizarLista();
    } on DpPontoException catch (e) {
      _aviso(e.message, erro: true);
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao reabrir competência: $e', st);
      _aviso('Não foi possível reabrir a competência.', erro: true);
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  Future<void> _atualizarLista() async {
    try {
      final lista = await _service.competencias();
      if (!mounted) return;
      final atual = _selecionada;
      setState(() {
        _competencias = lista;
        _selecionada = lista.firstWhere(
          (x) => x['mes'] == atual?['mes'] && x['ano'] == atual?['ano'],
          orElse: () => lista.first,
        );
      });
    } catch (e, st) {
      AppLogger.i.warn('DP: não atualizou a lista de competências: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GridColors.pageBackground,
      child: RefreshIndicator(
        onRefresh: _carregarPrevia,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _cabecalho(),
            const SizedBox(height: 16),
            if (_carregando) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            if (_erro != null) _caixaErro(_erro!),
            if (!_carregando && _previa != null) ..._conteudo(),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    final status = _previa?['status'] as String? ?? 'ABERTO';
    return Card(
      color: GridColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Fechamento do ponto da empresa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<Map<String, dynamic>>(
                key: const Key('dp_competencia'),
                value: _selecionada,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Competência', border: OutlineInputBorder()),
                items: _competencias
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text('${_rotulo(c)}${c['status'] == 'FECHADO' ? '  🔒' : ''}')))
                    .toList(),
                onChanged: _executando
                    ? null
                    : (v) {
                        setState(() => _selecionada = v);
                        _carregarPrevia();
                      },
              ),
            ),
            Chip(
              label: Text(status == 'FECHADO' ? 'FECHADA' : 'ABERTA'),
              backgroundColor: status == 'FECHADO' ? GridColors.primarySoft : GridColors.surfaceMuted,
            ),
            if (!_fechada)
              FilledButton.icon(
                key: const Key('dp_fechar'),
                onPressed: _executando || _previa == null ? null : () => _fechar(),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Fechar competência'),
              ),
            if (_fechada)
              OutlinedButton.icon(
                key: const Key('dp_reabrir'),
                onPressed: _executando ? null : _reabrir,
                icon: const Icon(Icons.lock_open),
                label: const Text('Reabrir'),
              ),
            IconButton(
              tooltip: 'Recalcular prévia',
              onPressed: _carregando || _executando ? null : _carregarPrevia,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _caixaErro(String msg) => Card(
        color: GridColors.errorLight,
        child: Padding(padding: const EdgeInsets.all(16), child: Text(msg, style: const TextStyle(color: GridColors.errorDark))),
      );

  List<Widget> _conteudo() {
    final p = _previa!;
    final pend = (p['pendencias'] as List).whereType<Map>().toList();
    final funcs = (p['funcionarios'] as List).whereType<Map>().toList();
    return [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _indicador('Funcionários', '${p['totalFuncionarios']}', GridColors.primary),
        _indicador('Pendências bloqueantes', '${p['totalBloqueantes']}',
            (p['totalBloqueantes'] as num) > 0 ? GridColors.error : GridColors.success),
        _indicador('Avisos', '${p['totalAvisos']}', GridColors.warningDark),
      ]),
      const SizedBox(height: 16),
      if (pend.isNotEmpty) _pendencias(pend),
      const SizedBox(height: 16),
      _funcionarios(funcs),
    ];
  }

  Widget _indicador(String titulo, String valor, Color cor) => SizedBox(
        width: 200,
        child: Card(
          color: GridColors.card,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(color: GridColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(valor, style: TextStyle(color: cor, fontSize: 26, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );

  Widget _pendencias(List<Map> pend) => Card(
        color: GridColors.card,
        child: ExpansionTile(
          key: const Key('dp_pendencias'),
          initiallyExpanded: pend.any((x) => x['bloqueia'] == true),
          title: Text('Pendências e inconsistências (${pend.length})',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          children: pend.map((x) {
            final bloqueia = x['bloqueia'] == true;
            return ListTile(
              dense: true,
              leading: Icon(bloqueia ? Icons.block : Icons.warning_amber_rounded,
                  color: bloqueia ? GridColors.error : GridColors.warningDark),
              title: Text('${x['funcionario'] ?? '-'}${x['data'] != null ? ' · ${_dataBr(x['data'] as String)}' : ''}'),
              subtitle: Text('${x['descricao']}'),
              trailing: Text(bloqueia ? 'Bloqueia' : 'Aviso',
                  style: TextStyle(color: bloqueia ? GridColors.error : GridColors.warningDark, fontSize: 12)),
            );
          }).toList(),
        ),
      );

  static String _dataBr(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  Widget _funcionarios(List<Map> funcs) {
    return Card(
      color: GridColors.card,
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 760) {
          return Column(
            children: funcs.map((f) => ListTile(
                  key: Key('dp_func_${f['funcionarioId']}'),
                  title: Text('${f['nome']}'),
                  subtitle: Text('${f['setor']} · normais ${formatarMinutos(f['normaisMin'] as num)}'
                      ' · extras ${formatarMinutos((f['he50Min'] as num) + (f['he100Min'] as num))}'
                      ' · faltas ${f['diasFalta']}d · banco ${formatarMinutos(f['saldoBancoMin'] as num)}'),
                  trailing: _situacao(f['situacao'] as String),
                )).toList(),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(GridColors.gridHeader),
            columns: const [
              DataColumn(label: Text('Funcionário')),
              DataColumn(label: Text('Setor')),
              DataColumn(label: Text('Situação')),
              DataColumn(label: Text('Normais')),
              DataColumn(label: Text('Extras 50%')),
              DataColumn(label: Text('Extras 100%')),
              DataColumn(label: Text('Noturno')),
              DataColumn(label: Text('Atrasos')),
              DataColumn(label: Text('Saída antec.')),
              DataColumn(label: Text('Faltas')),
              DataColumn(label: Text('DSR perdido')),
              DataColumn(label: Text('Banco')),
            ],
            rows: funcs.map((f) => DataRow(cells: [
                  DataCell(Text('${f['nome']}')),
                  DataCell(Text('${f['setor']}')),
                  DataCell(_situacao(f['situacao'] as String)),
                  DataCell(Text(formatarMinutos(f['normaisMin'] as num))),
                  DataCell(Text(formatarMinutos(f['he50Min'] as num))),
                  DataCell(Text(formatarMinutos(f['he100Min'] as num))),
                  DataCell(Text(formatarMinutos(f['noturnoMin'] as num))),
                  DataCell(Text(formatarMinutos(f['atrasoMin'] as num))),
                  DataCell(Text(formatarMinutos(f['saidaAntecipadaMin'] as num))),
                  DataCell(Text('${formatarMinutos(f['faltaMin'] as num)} (${f['diasFalta']}d)')),
                  DataCell(Text('${f['dsrPerdidoDias']}d')),
                  DataCell(Text(formatarMinutos(f['saldoBancoMin'] as num))),
                ])).toList(),
          ),
        );
      }),
    );
  }

  Widget _situacao(String s) {
    final (txt, cor) = switch (s) {
      'BLOQUEADO' => ('Bloqueado', GridColors.error),
      'COM_AVISOS' => ('Com avisos', GridColors.warningDark),
      _ => ('OK', GridColors.success),
    };
    return Text(txt, style: TextStyle(color: cor, fontWeight: FontWeight.w600));
  }
}
