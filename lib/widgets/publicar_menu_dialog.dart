import 'package:flutter/material.dart';

import '../services/menu_publicado_service.dart';
import '../utils/app_logger.dart';
import '../utils/grid_colors.dart';
import '../utils/menu_config.dart';

/// Publica uma planilha, relatorio ou tela no menu: nome, grupo e quais roles veem.
Future<void> publicarNoMenu(BuildContext context,
        {required String tipo, required int refId, required String titulo, MenuPublicadoService? servico}) =>
    showDialog<void>(
      context: context,
      builder: (_) => PublicarMenuDialog(
          tipo: tipo, refId: refId, titulo: titulo, servico: servico ?? MenuPublicadoService()),
    );

class PublicarMenuDialog extends StatefulWidget {
  final String tipo;
  final int refId;
  final String titulo;
  final MenuPublicadoService servico;

  const PublicarMenuDialog(
      {super.key, required this.tipo, required this.refId, required this.titulo, required this.servico});

  @override
  State<PublicarMenuDialog> createState() => _PublicarMenuDialogState();
}

class _PublicarMenuDialogState extends State<PublicarMenuDialog> {
  static const _grupoNovo = 'Personalizados';

  late final _titulo = TextEditingController(text: widget.titulo);
  String _grupo = _grupoNovo;
  ItemPublicado? _atual;
  List<RoleResumo> _roles = const [];
  Set<int> _antes = {};
  final Set<int> _marcadas = {};
  bool _ocupado = true;
  bool _carregado = false;
  String? _erro;

  List<String> get _grupos =>
      {for (final g in MenuConfig.fixos) g.label, _grupoNovo, if (_atual != null) _atual!.grupo}.toList();

  @override
  void initState() {
    super.initState();
    _executar(() async {
      final itens = await widget.servico.publicados();
      for (final i in itens) {
        if (i.tipo == widget.tipo && i.refId == widget.refId) _atual = i;
      }
      _roles = await widget.servico.roles();
      final atual = _atual;
      if (atual != null) {
        _titulo.text = atual.titulo;
        _grupo = atual.grupo;
        _antes = await widget.servico.rolesComAcesso(atual.menuId);
        _marcadas.addAll(_antes);
      }
      _carregado = true;
    });
  }

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<bool> _executar(Future<void> Function() tarefa) async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    var ok = true;
    try {
      await tarefa();
    } catch (e) {
      ok = false;
      AppLogger.i.warn('PublicarMenuDialog: $e');
      _erro = '$e';
    }
    if (mounted) setState(() => _ocupado = false);
    return ok;
  }

  Future<void> _publicar() async {
    final ok = await _executar(() async {
      final item = await widget.servico.publicar(widget.tipo, widget.refId, _titulo.text.trim(), _grupo);
      _atual = item;
      await widget.servico.gravarAcessos(item.menuId, {
        for (final id in _marcadas.difference(_antes)) id: true,
        for (final id in _antes.difference(_marcadas)) id: false,
      });
      _antes = Set.of(_marcadas);
      await widget.servico.carregarNoMenu();
    });
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _retirar() async {
    final ok = await _executar(() async {
      await widget.servico.despublicar(_atual!.id);
      await widget.servico.carregarNoMenu();
    });
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Publicar no menu'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _titulo,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'Nome no menu', counterText: ''),
            ),
            const SizedBox(height: 8),
            if (_carregado)
              DropdownButtonFormField<String>(
                initialValue: _grupo,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Grupo do menu'),
                items: [for (final g in _grupos) DropdownMenuItem(value: g, child: Text(g))],
                onChanged: (g) => _grupo = g ?? _grupoNovo,
              ),
            const SizedBox(height: 12),
            const Text('Quem vê (o MASTER sempre vê)', style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('Também aparece no Controle de Acesso. Vale no próximo login do usuário.',
                style: TextStyle(fontSize: 12)),
            for (final r in _roles)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(r.nome),
                value: _marcadas.contains(r.id),
                onChanged: (v) => setState(() => v == true ? _marcadas.add(r.id) : _marcadas.remove(r.id)),
              ),
            if (_ocupado) const LinearProgressIndicator(),
            if (_erro != null) Text(_erro!, style: const TextStyle(color: GridColors.error)),
          ]),
        ),
      ),
      actions: [
        if (_atual != null) TextButton(onPressed: _ocupado ? null : _retirar, child: const Text('Tirar do menu')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _ocupado || !_carregado ? null : _publicar, child: const Text('Publicar')),
      ],
    );
  }
}
