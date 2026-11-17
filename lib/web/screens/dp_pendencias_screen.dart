import 'package:flutter/material.dart';

import '../../services/dp_ponto_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/grid_colors.dart';

/// Pendencias do DP (espelhos sem aceite, ajustes, ferias, banco de horas) e aviso imediato por notificacao.
/// Mesma tela em Web, Windows e Mobile.
class DpPendenciasScreen extends StatefulWidget {
  const DpPendenciasScreen({super.key, this.service});

  /// Injetavel para teste.
  final DpPontoService? service;

  @override
  State<DpPendenciasScreen> createState() => _DpPendenciasScreenState();
}

class _DpPendenciasScreenState extends State<DpPendenciasScreen> {
  late final DpPontoService _service = widget.service ?? DpPontoService();

  Map<String, dynamic>? _dados;
  bool _carregando = true;
  bool _notificando = false;
  String? _erro;

  static const _categorias = <(String, String, IconData)>[
    ('espelhosSemAceite', 'Espelhos sem aceite do funcionário', Icons.draw_outlined),
    ('ajustesPendentes', 'Ajustes de ponto aguardando resposta', Icons.edit_calendar_outlined),
    ('feriasPendentes', 'Solicitações de férias aguardando resposta', Icons.beach_access_outlined),
    ('bancoHoras', 'Banco de horas vencido ou vencendo', Icons.hourglass_bottom),
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final d = await _service.pendencias();
      if (mounted) setState(() => _dados = d);
    } on DpPontoException catch (e) {
      if (mounted) setState(() { _dados = null; _erro = e.message; });
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao carregar pendências: $e', st);
      if (mounted) setState(() { _dados = null; _erro = 'Não foi possível carregar as pendências.'; });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _notificar() async {
    setState(() => _notificando = true);
    try {
      final n = await _service.notificarPendencias();
      _aviso(n == 0 ? 'Nada a avisar: não há pendências.' : '$n alerta(s) enviado(s).');
    } on DpPontoException catch (e) {
      _aviso(e.message, erro: true);
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao notificar pendências: $e', st);
      _aviso('Não foi possível enviar os avisos.', erro: true);
    } finally {
      if (mounted) setState(() => _notificando = false);
    }
  }

  void _aviso(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? GridColors.error : GridColors.primary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final d = _dados;
    return Container(
      color: GridColors.pageBackground,
      child: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: GridColors.card,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  const Text('Pendências do DP',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
                  if (d != null) Chip(label: Text('${d['total']} pendência(s)')),
                  FilledButton.icon(
                    key: const Key('dp_notificar'),
                    onPressed: _notificando || _carregando ? null : _notificar,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Avisar agora'),
                  ),
                  IconButton(tooltip: 'Atualizar', onPressed: _carregando ? null : _carregar, icon: const Icon(Icons.refresh)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            if (_carregando) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
            if (_erro != null)
              Card(
                color: GridColors.errorLight,
                child: Padding(padding: const EdgeInsets.all(16), child: Text(_erro!, style: const TextStyle(color: GridColors.errorDark))),
              ),
            if (!_carregando && d != null) ..._categorias.map((c) => _categoria(c.$1, c.$2, c.$3, d)),
          ],
        ),
      ),
    );
  }

  Widget _categoria(String chave, String titulo, IconData icone, Map<String, dynamic> d) {
    final itens = (d[chave] as List? ?? []).whereType<Map>().toList();
    return Card(
      color: GridColors.card,
      child: ExpansionTile(
        key: Key('dp_pend_$chave'),
        initiallyExpanded: itens.isNotEmpty,
        leading: Icon(icone, color: itens.isEmpty ? GridColors.success : GridColors.warningDark),
        title: Text('$titulo (${itens.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
        children: itens.isEmpty
            ? const [ListTile(dense: true, title: Text('Nada pendente.'))]
            : itens.map((i) => ListTile(
                  dense: true,
                  title: Text('${i['funcionario'] ?? '-'}${i['referencia'] != null ? ' · ${i['referencia']}' : ''}'),
                  subtitle: Text('${i['detalhe']}'),
                )).toList(),
      ),
    );
  }
}
