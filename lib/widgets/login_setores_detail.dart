import 'package:flutter/material.dart';

import '../constants/custom_colors.dart';
import '../models/setor_model.dart';
import '../services/setor_caller.dart';

typedef SetoresLoader = Future<List<Setor>> Function();
typedef LoginSetoresLoader = Future<List<Setor>> Function(int loginId);
typedef LoginSetorUpdater = Future<bool> Function(int loginId, int setorId);
typedef LoginSetoresSalvar = Future<bool> Function(int loginId, List<int> setorIds);

class LoginSetoresDetail extends StatefulWidget {
  final int? loginId;
  final SetoresLoader carregarSetores;
  final LoginSetoresLoader carregarSetoresDoLogin;
  final LoginSetorUpdater vincularSetor;
  final LoginSetorUpdater desvincularSetor;
  final LoginSetoresSalvar salvarSetores;

  LoginSetoresDetail({
    super.key,
    required this.loginId,
    SetoresLoader? carregarSetores,
    LoginSetoresLoader? carregarSetoresDoLogin,
    LoginSetorUpdater? vincularSetor,
    LoginSetorUpdater? desvincularSetor,
    LoginSetoresSalvar? salvarSetores,
  })  : carregarSetores = carregarSetores ?? SetorCaller().fetchAllSetores,
        carregarSetoresDoLogin =
            carregarSetoresDoLogin ?? SetorCaller().fetchSetoresDoLogin,
        vincularSetor =
            vincularSetor ?? SetorCaller().associarSetorAoLogin,
        desvincularSetor =
            desvincularSetor ?? SetorCaller().removerSetorDoLogin,
        salvarSetores =
            salvarSetores ?? SetorCaller().atualizarSetoresDoLogin;

  @override
  State<LoginSetoresDetail> createState() => _LoginSetoresDetailState();
}

class _LoginSetoresDetailState extends State<LoginSetoresDetail> {
  bool _carregando = true;
  List<Setor> _vinculados = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  Future<void> _recarregar() async {
    final loginId = widget.loginId;
    if (loginId == null || loginId <= 0) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = 'Salve o login antes de vincular setores.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final list = await widget.carregarSetoresDoLogin(loginId);
      if (!mounted) return;
      setState(() {
        _vinculados = List.of(list)
          ..sort((a, b) => (a.nome ?? '').compareTo(b.nome ?? ''));
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Falha ao carregar setores vinculados.';
      });
    }
  }

  Future<void> _confirmarEDesvincular(Setor setor) async {
    final loginId = widget.loginId;
    if (loginId == null || setor.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: GridColors.error),
            SizedBox(width: 8),
            Text('Desvincular Setor'),
          ],
        ),
        content: Text(
          'Deseja realmente desvincular o setor "${setor.nome ?? 'Setor #${setor.id}'}" deste login?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GridColors.error),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final ok = await widget.desvincularSetor(loginId, setor.id!);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setor "${setor.nome}" desvinculado com sucesso.'),
          backgroundColor: GridColors.success,
        ),
      );
      _recarregar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao desvincular setor do login.'),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }

  Future<void> _abrirModalVincular() async {
    final loginId = widget.loginId;
    if (loginId == null || loginId <= 0) return;

    final atualizado = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _VincularSetoresDialog(
        loginId: loginId,
        vinculadosAtuais: _vinculados,
        carregarSetores: widget.carregarSetores,
        vincularSetor: widget.vincularSetor,
        desvincularSetor: widget.desvincularSetor,
        salvarSetores: widget.salvarSetores,
      ),
    );

    if (atualizado != null && mounted) {
      if (atualizado is List<Setor>) {
        setState(() {
          _vinculados = List.of(atualizado)
            ..sort((a, b) => (a.nome ?? '').compareTo(b.nome ?? ''));
          _erro = null;
        });
      }
      await _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loginId == null || widget.loginId! <= 0) {
      return _mensagem('Salve o login antes de vincular setores.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra superior da Grid de Setores (Sem botão Novo, com botão Vincular)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              const Icon(Icons.business_center, color: GridColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Setores vinculados',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: GridColors.textSecondary,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: GridColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_vinculados.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: GridColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              // Botão Vincular (Destaque, sem botão Novo)
              FilledButton.icon(
                key: const Key('btn-vincular-setores'),
                onPressed: _carregando ? null : _abrirModalVincular,
                icon: const Icon(Icons.add_link, size: 18),
                label: const Text('Vincular'),
                style: FilledButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Recarregar',
                onPressed: _carregando ? null : _recarregar,
              ),
            ],
          ),
        ),

        // Corpo: carregando, erro ou grid de setores
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
                  ? _mensagem(_erro!)
                  : _vinculados.isEmpty
                      ? _buildEmptyState()
                      : _buildGridSetores(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.domain_disabled_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum setor vinculado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GridColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Clique no botão "Vincular" para associar setores a este usuário.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: GridColors.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _abrirModalVincular,
              icon: const Icon(Icons.add_link),
              label: const Text('Vincular setores'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSetores() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 16,
            columnSpacing: 24,
            columns: const [
              DataColumn(
                label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Setor / Descrição',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Responsável',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Ramal',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Ações',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            rows: _vinculados.map((setor) {
              return DataRow(
                key: ValueKey('row-setor-${setor.id}'),
                cells: [
                  DataCell(Text('${setor.id ?? '-'}')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.apartment,
                            size: 16, color: GridColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          setor.nome ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(setor.responsavel ?? '-')),
                  DataCell(Text(setor.ramal ?? '-')),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.link_off,
                          color: GridColors.error, size: 20),
                      tooltip: 'Desvincular setor',
                      onPressed: () => _confirmarEDesvincular(setor),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _mensagem(String texto) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(texto, textAlign: TextAlign.center),
      ),
    );
  }
}

/// Diálogo Modal de Vínculo de Setores com "Selecionar todos" e "Desmarcar todos"
class _VincularSetoresDialog extends StatefulWidget {
  final int loginId;
  final List<Setor> vinculadosAtuais;
  final SetoresLoader carregarSetores;
  final LoginSetorUpdater vincularSetor;
  final LoginSetorUpdater desvincularSetor;
  final LoginSetoresSalvar salvarSetores;

  const _VincularSetoresDialog({
    required this.loginId,
    required this.vinculadosAtuais,
    required this.carregarSetores,
    required this.vincularSetor,
    required this.desvincularSetor,
    required this.salvarSetores,
  });

  @override
  State<_VincularSetoresDialog> createState() => _VincularSetoresDialogState();
}

class _VincularSetoresDialogState extends State<_VincularSetoresDialog> {
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  List<Setor> _todosSetores = [];
  Set<int> _selecionados = {};
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _iniciarDados();
  }

  Future<void> _iniciarDados() async {
    try {
      final list = await widget.carregarSetores();
      if (!mounted) return;

      final porId = <int, Setor>{};
      for (final s in [...list, ...widget.vinculadosAtuais]) {
        if (s.id != null) porId[s.id!] = s;
      }

      setState(() {
        _todosSetores = porId.values.toList()
          ..sort((a, b) => (a.nome ?? '').compareTo(b.nome ?? ''));
        _selecionados = widget.vinculadosAtuais
            .where((s) => s.id != null)
            .map((s) => s.id!)
            .toSet();
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Falha ao carregar lista de setores.';
      });
    }
  }

  void _selecionarTodos() {
    setState(() {
      _selecionados = _todosSetores
          .where((s) => s.id != null)
          .map((s) => s.id!)
          .toSet();
      _erro = null;
    });
  }

  void _desmarcarTodos() {
    setState(() {
      _selecionados.clear();
      _erro = null;
    });
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final loginId = widget.loginId;
    final idsSelecionados = _selecionados.toList();

    bool sucesso = false;
    try {
      sucesso = await widget.salvarSetores(loginId, idsSelecionados);
    } catch (_) {
      sucesso = false;
    }

    // Se o salvarSetores falhou ou retornou false, tenta fallback individual seguro
    if (!sucesso) {
      final idsAtuais = widget.vinculadosAtuais
          .where((s) => s.id != null)
          .map((s) => s.id!)
          .toSet();
      final paraAdicionar = _selecionados.difference(idsAtuais);
      final paraRemover = idsAtuais.difference(_selecionados);

      bool okIndiv = true;
      for (final id in paraAdicionar) {
        final r = await widget.vincularSetor(loginId, id);
        if (!r) okIndiv = false;
      }
      for (final id in paraRemover) {
        final r = await widget.desvincularSetor(loginId, id);
        if (!r) okIndiv = false;
      }
      sucesso = okIndiv;
    }

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vínculos de setores salvos com sucesso.'),
          backgroundColor: GridColors.success,
        ),
      );
      final selecionadosObjetos = _todosSetores
          .where((s) => s.id != null && _selecionados.contains(s.id!))
          .toList();
      Navigator.of(context).pop(selecionadosObjetos);
    } else {
      setState(() {
        _salvando = false;
        _erro = 'Não foi possível salvar os vínculos de setores.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final setoresFiltrados = _filtro.trim().isEmpty
        ? _todosSetores
        : _todosSetores.where((s) {
            final termo = _filtro.trim().toLowerCase();
            return (s.nome ?? '').toLowerCase().contains(termo) ||
                (s.responsavel ?? '').toLowerCase().contains(termo) ||
                (s.ramal ?? '').toLowerCase().contains(termo);
          }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 620,
          maxHeight: 650,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho do modal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: GridColors.primary,
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Vincular Setores ao Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Fechar',
                    onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Barra de ações em massa: Selecionar todos e Desmarcar todos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF8FAFC),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('btn-selecionar-todos'),
                        onPressed:
                            _carregando || _salvando ? null : _selecionarTodos,
                        icon: const Icon(Icons.select_all, size: 18),
                        label: const Text('Selecionar todos'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        key: const Key('btn-desmarcar-todos'),
                        onPressed:
                            _carregando || _salvando ? null : _desmarcarTodos,
                        icon: const Icon(Icons.deselect, size: 18),
                        label: const Text('Desmarcar todos'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_selecionados.length} de ${_todosSetores.length} selecionado(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GridColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Campo de busca / pesquisa rápida
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Filtrar setores por nome...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (val) => setState(() => _filtro = val),
              ),
            ),

            const Divider(height: 1),

            // Lista de setores
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _todosSetores.isEmpty
                      ? const Center(
                          child: Text('Nenhum setor disponível no sistema.'),
                        )
                      : setoresFiltrados.isEmpty
                          ? const Center(
                              child: Text('Nenhum setor encontrado para a busca.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: setoresFiltrados.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 56),
                              itemBuilder: (context, index) {
                                final setor = setoresFiltrados[index];
                                final setorId = setor.id!;
                                final marcado = _selecionados.contains(setorId);

                                return CheckboxListTile(
                                  key: Key('login-setor-$setorId'),
                                  value: marcado,
                                  activeColor: GridColors.success,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    setor.nome ?? 'Setor #$setorId',
                                    style: TextStyle(
                                      fontWeight: marcado
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: (setor.responsavel != null &&
                                          setor.responsavel!.isNotEmpty)
                                      ? Text(
                                          'Resp: ${setor.responsavel}' +
                                              ((setor.ramal != null &&
                                                      setor.ramal!.isNotEmpty)
                                                  ? ' | Ramal: ${setor.ramal}'
                                                  : ''),
                                          style: const TextStyle(fontSize: 12),
                                        )
                                      : null,
                                  onChanged: _salvando
                                      ? null
                                      : (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selecionados.add(setorId);
                                            } else {
                                              _selecionados.remove(setorId);
                                            }
                                            _erro = null;
                                          });
                                        },
                                );
                              },
                            ),
            ),

            if (_erro != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: GridColors.error.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: GridColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _erro!,
                        style: const TextStyle(
                          color: GridColors.error,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Rodapé do modal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    key: const Key('btn-salvar-vinculos'),
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Salvar vínculos'),
                    style: FilledButton.styleFrom(
                      backgroundColor: GridColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
