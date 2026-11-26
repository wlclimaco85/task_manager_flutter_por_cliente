import 'package:flutter/material.dart';

import '../services/menu_publicado_service.dart';
import '../utils/app_logger.dart';
import '../utils/grid_colors.dart';
import 'planilha_view.dart';
import 'publicar_menu_dialog.dart';

/// Construtor de Planilhas (MASTER): cria modelos (layout + fontes de dados) e publica no menu.
class PlanilhaConstrutorView extends StatefulWidget {
  final MenuPublicadoService? servico;

  const PlanilhaConstrutorView({super.key, this.servico});

  @override
  State<PlanilhaConstrutorView> createState() => _PlanilhaConstrutorViewState();
}

class _PlanilhaConstrutorViewState extends State<PlanilhaConstrutorView> {
  late final MenuPublicadoService _svc = widget.servico ?? MenuPublicadoService();
  List<ModeloPlanilha> _lista = const [];
  ModeloPlanilha? _editando;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _tentar(Future<void> Function() tarefa) async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await tarefa();
    } catch (e) {
      AppLogger.i.warn('PlanilhaConstrutorView: $e');
      _erro = '$e';
    }
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _carregar() => _tentar(() async => _lista = await _svc.modelos());

  Future<void> _editar(ModeloPlanilha resumo) =>
      _tentar(() async => _editando = await _svc.modelo(resumo.id!));

  @override
  Widget build(BuildContext context) {
    final editando = _editando;
    if (editando != null) {
      return PlanilhaView(
        key: ValueKey('modelo-${editando.id}'),
        edicaoModelo: editando,
        menu: _svc,
        onVoltar: () {
          setState(() => _editando = null);
          _carregar();
        },
      );
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Text('Construtor de Planilhas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          IconButton(tooltip: 'Atualizar', onPressed: _carregar, icon: const Icon(Icons.refresh)),
          FilledButton.icon(
            onPressed: () => setState(() => _editando = const ModeloPlanilha(titulo: 'Novo modelo')),
            icon: const Icon(Icons.add),
            label: const Text('Novo modelo'),
          ),
        ]),
      ),
      Expanded(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_erro!)))
                : _lista.isEmpty
                    ? const Center(child: Text('Nenhum modelo criado ainda.'))
                    : ListView.separated(
                        itemCount: _lista.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final m = _lista[i];
                          return ListTile(
                            minVerticalPadding: 10,
                            leading: const Icon(Icons.grid_on, color: GridColors.primary),
                            title: Text(m.titulo),
                            subtitle: m.descricao == null ? null : Text(m.descricao!),
                            onTap: () => _editar(m),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                  tooltip: 'Publicar no menu',
                                  onPressed: () => publicarNoMenu(context,
                                      tipo: 'PLANILHA', refId: m.id!, titulo: m.titulo, servico: _svc),
                                  icon: const Icon(Icons.menu_open)),
                              IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => _editar(m),
                                  icon: const Icon(Icons.edit_outlined)),
                            ]),
                          );
                        }),
      ),
    ]);
  }
}
