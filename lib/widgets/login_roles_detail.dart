import 'package:flutter/material.dart';

import '../constants/custom_colors.dart';
import '../models/role_model.dart';
import '../services/role_caller.dart';

typedef RoleesLoader = Future<List<Role>> Function();
typedef LoginRoleesLoader = Future<List<Role>> Function(int loginId);
typedef LoginRoleUpdater = Future<bool> Function(int loginId, int roleId);
typedef LoginRoleesSalvar = Future<bool> Function(
    int loginId, List<int> roleIds);

class LoginRoleesDetail extends StatefulWidget {
  final int? loginId;
  final RoleesLoader carregarRolees;
  final LoginRoleesLoader carregarRoleesDoLogin;
  final LoginRoleUpdater vincularRole;
  final LoginRoleUpdater desvincularRole;
  final LoginRoleesSalvar salvarRolees;

  LoginRoleesDetail({
    super.key,
    required this.loginId,
    RoleesLoader? carregarRolees,
    LoginRoleesLoader? carregarRoleesDoLogin,
    LoginRoleUpdater? vincularRole,
    LoginRoleUpdater? desvincularRole,
    LoginRoleesSalvar? salvarRolees,
  })  : carregarRolees = carregarRolees ?? RoleCaller().getRoles,
        carregarRoleesDoLogin =
            carregarRoleesDoLogin ?? RoleCaller().fetchRolesDoLogin,
        vincularRole = vincularRole ?? RoleCaller().associateRoleToLogin,
        desvincularRole = desvincularRole ?? RoleCaller().removeRoleFromLogin,
        salvarRolees = salvarRolees ?? RoleCaller().atualizarRolesDoLogin;

  @override
  State<LoginRoleesDetail> createState() => _LoginRoleesDetailState();
}

class _LoginRoleesDetailState extends State<LoginRoleesDetail> {
  bool _carregando = true;
  List<Role> _vinculados = [];
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
          _erro = 'Salve o login antes de vincular rolees.';
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
      final list = await widget.carregarRoleesDoLogin(loginId);
      if (!mounted) return;
      setState(() {
        _vinculados = List.of(list)
          ..sort(
              (a, b) => (a.description ?? '').compareTo(b.description ?? ''));
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Falha ao carregar rolees vinculados.';
      });
    }
  }

  Future<void> _confirmarEDesvincular(Role role) async {
    final loginId = widget.loginId;
    if (loginId == null || role.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: GridColors.error),
            SizedBox(width: 8),
            Text('Desvincular Role'),
          ],
        ),
        content: Text(
          'Deseja realmente desvincular o role "${role.description ?? 'Role #${role.id}'}" deste login?',
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

    final ok = await widget.desvincularRole(loginId, role.id!);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role "${role.description}" desvinculado com sucesso.'),
          backgroundColor: GridColors.success,
        ),
      );
      _recarregar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao desvincular role do login.'),
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
      builder: (dialogContext) => _VincularRoleesDialog(
        loginId: loginId,
        vinculadosAtuais: _vinculados,
        carregarRolees: widget.carregarRolees,
        vincularRole: widget.vincularRole,
        desvincularRole: widget.desvincularRole,
        salvarRolees: widget.salvarRolees,
      ),
    );

    if (atualizado != null && mounted) {
      if (atualizado is List<Role>) {
        setState(() {
          _vinculados = List.of(atualizado)
            ..sort(
                (a, b) => (a.description ?? '').compareTo(b.description ?? ''));
          _erro = null;
        });
      }
      await _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loginId == null || widget.loginId! <= 0) {
      return _mensagem('Salve o login antes de vincular rolees.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra superior da Grid de Rolees (Sem botão Novo, com botão Vincular)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              const Icon(Icons.security, color: GridColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Rolees vinculados',
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
                key: const Key('btn-vincular-rolees'),
                onPressed: _carregando ? null : _abrirModalVincular,
                icon: const Icon(Icons.add_link, size: 18),
                label: const Text('Vincular'),
                style: FilledButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

        // Corpo: carregando, erro ou grid de rolees
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
                  ? _mensagem(_erro!)
                  : _vinculados.isEmpty
                      ? _buildEmptyState()
                      : _buildGridRolees(),
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
              'Nenhum role vinculado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GridColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Clique no botão "Vincular" para associar rolees a este usuário.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: GridColors.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _abrirModalVincular,
              icon: const Icon(Icons.add_link),
              label: const Text('Vincular rolees'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridRolees() {
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
                label:
                    Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Role / Descrição',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Aplicativo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Chave',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('Ações',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            rows: _vinculados.map((role) {
              return DataRow(
                key: ValueKey('row-role-${role.id}'),
                cells: [
                  DataCell(Text('${role.id ?? '-'}')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user,
                            size: 16, color: GridColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          role.description ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(role.aplicativo?.nome ?? '-')),
                  DataCell(Text(role.key ?? '-')),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.link_off,
                          color: GridColors.error, size: 20),
                      tooltip: 'Desvincular role',
                      onPressed: () => _confirmarEDesvincular(role),
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

/// Diálogo Modal de Vínculo de Rolees com "Selecionar todos" e "Desmarcar todos"
class _VincularRoleesDialog extends StatefulWidget {
  final int loginId;
  final List<Role> vinculadosAtuais;
  final RoleesLoader carregarRolees;
  final LoginRoleUpdater vincularRole;
  final LoginRoleUpdater desvincularRole;
  final LoginRoleesSalvar salvarRolees;

  const _VincularRoleesDialog({
    required this.loginId,
    required this.vinculadosAtuais,
    required this.carregarRolees,
    required this.vincularRole,
    required this.desvincularRole,
    required this.salvarRolees,
  });

  @override
  State<_VincularRoleesDialog> createState() => _VincularRoleesDialogState();
}

class _VincularRoleesDialogState extends State<_VincularRoleesDialog> {
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;
  List<Role> _todosRolees = [];
  Set<int> _selecionados = {};
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _iniciarDados();
  }

  Future<void> _iniciarDados() async {
    try {
      final list = await widget.carregarRolees();
      if (!mounted) return;

      final porId = <int, Role>{};
      for (final s in [...list, ...widget.vinculadosAtuais]) {
        if (s.id != null) porId[s.id!] = s;
      }

      setState(() {
        _todosRolees = porId.values.toList()
          ..sort(
              (a, b) => (a.description ?? '').compareTo(b.description ?? ''));
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
        _erro = 'Falha ao carregar lista de rolees.';
      });
    }
  }

  void _selecionarTodos() {
    setState(() {
      _selecionados =
          _todosRolees.where((s) => s.id != null).map((s) => s.id!).toSet();
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
      sucesso = await widget.salvarRolees(loginId, idsSelecionados);
    } catch (_) {
      sucesso = false;
    }

    // Se o salvarRolees falhou ou retornou false, tenta fallback individual seguro
    if (!sucesso) {
      final idsAtuais = widget.vinculadosAtuais
          .where((s) => s.id != null)
          .map((s) => s.id!)
          .toSet();
      final paraAdicionar = _selecionados.difference(idsAtuais);
      final paraRemover = idsAtuais.difference(_selecionados);

      bool okIndiv = true;
      for (final id in paraAdicionar) {
        final r = await widget.vincularRole(loginId, id);
        if (!r) okIndiv = false;
      }
      for (final id in paraRemover) {
        final r = await widget.desvincularRole(loginId, id);
        if (!r) okIndiv = false;
      }
      sucesso = okIndiv;
    }

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vínculos de rolees salvos com sucesso.'),
          backgroundColor: GridColors.success,
        ),
      );
      final selecionadosObjetos = _todosRolees
          .where((s) => s.id != null && _selecionados.contains(s.id!))
          .toList();
      Navigator.of(context).pop(selecionadosObjetos);
    } else {
      setState(() {
        _salvando = false;
        _erro = 'Não foi possível salvar os vínculos de rolees.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleesFiltrados = _filtro.trim().isEmpty
        ? _todosRolees
        : _todosRolees.where((s) {
            final termo = _filtro.trim().toLowerCase();
            return (s.description ?? '').toLowerCase().contains(termo) ||
                (s.key ?? '').toLowerCase().contains(termo) ||
                (s.aplicativo?.nome ?? '').toLowerCase().contains(termo);
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
                      'Vincular Rolees ao Login',
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
                    onPressed:
                        _salvando ? null : () => Navigator.of(context).pop(),
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
                    '${_selecionados.length} de ${_todosRolees.length} selecionado(s)',
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
                  hintText: 'Filtrar rolees por nome...',
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

            // Lista de rolees
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _todosRolees.isEmpty
                      ? const Center(
                          child: Text('Nenhum role disponível no sistema.'),
                        )
                      : roleesFiltrados.isEmpty
                          ? const Center(
                              child:
                                  Text('Nenhum role encontrado para a busca.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: roleesFiltrados.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 56),
                              itemBuilder: (context, index) {
                                final role = roleesFiltrados[index];
                                final roleId = role.id!;
                                final marcado = _selecionados.contains(roleId);

                                return CheckboxListTile(
                                  key: Key('login-role-$roleId'),
                                  value: marcado,
                                  activeColor: GridColors.success,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    role.description ?? 'Role #$roleId',
                                    style: TextStyle(
                                      fontWeight: marcado
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      if ((role.aplicativo?.nome ?? '')
                                          .isNotEmpty)
                                        role.aplicativo!.nome!,
                                      if ((role.key ?? '').isNotEmpty)
                                        role.key!,
                                    ].join(' | '),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onChanged: _salvando
                                      ? null
                                      : (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selecionados.add(roleId);
                                            } else {
                                              _selecionados.remove(roleId);
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
                    onPressed:
                        _salvando ? null : () => Navigator.of(context).pop(),
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
