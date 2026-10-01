import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/role_permissao_model.dart';
import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/role_permission_group_selection.dart';
import '../../utils/role_permission_catalog.dart';
import '../../utils/tenant_context.dart';

// Fix (card #471): normalizacao de nomes de tela (lowercase + remove "_")
String _normalizeTelaNome(String s) => s.toLowerCase().replaceAll('_', '');

// Conversao de snake_case para camelCase
String toBackendTelaNome(String screenName) {
  if (!screenName.contains('_')) {
    return screenName;
  }

  final parts = screenName.split('_');
  final buffer = StringBuffer(parts[0]);

  for (int i = 1; i < parts.length; i++) {
    final part = parts[i];
    if (part.isNotEmpty) {
      buffer.write(part[0].toUpperCase() + part.substring(1));
    }
  }

  return buffer.toString();
}

class RolePermissaoMobileScreen extends StatefulWidget {
  const RolePermissaoMobileScreen({super.key});

  @override
  State<RolePermissaoMobileScreen> createState() =>
      _RolePermissaoMobileScreenState();
}

class _RolePermissaoMobileScreenState extends State<RolePermissaoMobileScreen> {
  List<RolePermissao> _permissoes = [];
  List<Map<String, dynamic>> _roles = [];
  final TextEditingController _buscaCtrl = TextEditingController();
  int? _roleId;
  String _busca = '';
  bool _carregando = true;
  final Set<String> _gruposSalvando = <String>{};

  @override
  void initState() {
    super.initState();
    _buscaCtrl.addListener(() {
      setState(() => _busca = _buscaCtrl.text);
    });
    _carregarDados();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final token = AuthUtility.userInfo?.token ?? '';
    final tenantId = TenantContext.empresaId?.toString() ?? '';

    try {
      final resPermissoes = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/role-permissao/all'),
        headers: {'Authorization': 'Bearer $token', 'X-Tenant-ID': tenantId},
      );

      final resRoles = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/role'),
        headers: {'Authorization': 'Bearer $token', 'X-Tenant-ID': tenantId},
      );

      if (resPermissoes.statusCode == 200 && resRoles.statusCode == 200) {
        final permData = jsonDecode(resPermissoes.body);
        final rolesData = jsonDecode(resRoles.body);

        setState(() {
          _permissoes = ((permData['data']?['dados'] ?? []) as List)
              .map((j) => RolePermissao.fromJson(j))
              .toList();
          _roles = ((rolesData['data']?['dados'] ?? []) as List)
              .map((r) => {'id': r['id'], 'description': r['description']})
              .toList();
          if (_roles.isNotEmpty) _roleId = _roles.first['id'] as int?;
          _carregando = false;
        });
      } else {
        setState(() => _carregando = false);
      }
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  // Fix (card #493): mobile - refatorado para receber telaNome diretamente
  Future<void> _salvar(String telaNome, String campo, bool valor) async {
    if (_roleId == null) return;
    final roleId = _roleId!;
    final token = AuthUtility.userInfo?.token ?? '';
    final tenantId = TenantContext.empresaId?.toString() ?? '';

    try {
      final baseUri = Uri.parse(ApiLinks.baseUrl);
      final requestUri = baseUri.replace(
        path:
            '${baseUri.path}/api/role-permissao/$roleId/${Uri.encodeComponent(telaNome)}',
      );

      final response = await http.put(
        requestUri,
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant-ID': tenantId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({campo: valor}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao salvar: ${response.statusCode}'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        final index = _permissoes.indexWhere(
          (p) =>
              p.roleId == roleId &&
              _normalizeTelaNome(p.telaNome) == _normalizeTelaNome(telaNome),
        );
        if (index >= 0) {
          final atual = _permissoes[index];
          _permissoes[index] = atual.copyWith(
            podeVer: campo == 'podeVer' ? valor : null,
            podeInserir: campo == 'podeInserir' ? valor : null,
            podeEditar: campo == 'podeEditar' ? valor : null,
            podeDeletar: campo == 'podeDeletar' ? valor : null,
            podeBaixar: campo == 'podeBaixar' ? valor : null,
          );
        } else {
          _permissoes.add(RolePermissao(
            id: 0,
            roleId: roleId,
            roleKey: '',
            roleDescription: '',
            telaNome: telaNome,
            podeVer: campo == 'podeVer' ? valor : false,
            podeInserir: campo == 'podeInserir' ? valor : false,
            podeEditar: campo == 'podeEditar' ? valor : false,
            podeDeletar: campo == 'podeDeletar' ? valor : false,
            podeBaixar: campo == 'podeBaixar' ? valor : false,
          ));
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salvo'),
            backgroundColor: GridColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _salvarGrupo(RolePermissionGroup grupo, bool marcar) async {
    if (_roleId == null || grupo.entries.isEmpty) return;
    final roleId = _roleId!;
    final grupoCompleto = resolveRolePermissionCompleteGroup(grupo);
    final grupoKey = grupoCompleto.id;
    if (_gruposSalvando.contains(grupoKey)) return;
    setState(() => _gruposSalvando.add(grupoKey));

    final token = AuthUtility.userInfo?.token ?? '';
    final tenantId = TenantContext.empresaId?.toString() ?? '';

    try {
      final response = await http.post(
        Uri.parse('${ApiLinks.baseUrl}/api/role-permissao/batch'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Tenant-ID': tenantId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(buildRolePermissionGroupBatch(
          roleId: roleId,
          grupo: grupoCompleto,
          marcar: marcar,
        )),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar menu: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _atualizarGrupoLocal(roleId, grupoCompleto, marcar));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(marcar ? 'Menu liberado' : 'Menu bloqueado'),
            backgroundColor: GridColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _gruposSalvando.remove(grupoKey));
      }
    }
  }

  void _atualizarGrupoLocal(
    int roleId,
    RolePermissionGroup grupo,
    bool marcar,
  ) {
    for (final tela in grupo.entries) {
      final index = _permissoes.indexWhere(
        (p) =>
            p.roleId == roleId &&
            _normalizeTelaNome(p.telaNome) == _normalizeTelaNome(tela.telaNome),
      );
      if (index >= 0) {
        _permissoes[index] = rolePermissionWithAllFields(
          _permissoes[index],
          valor: marcar,
        );
      } else {
        _permissoes.add(RolePermissao(
          id: 0,
          roleId: roleId,
          roleKey: '',
          roleDescription: '',
          telaNome: tela.telaNome,
          podeVer: marcar,
          podeInserir: marcar,
          podeEditar: marcar,
          podeDeletar: marcar,
          podeBaixar: marcar,
        ));
      }
    }
  }

  RolePermissao _permissaoDe(RolePermissionMenuEntry tela) {
    final telaNomeNormalizado = _normalizeTelaNome(tela.telaNome);
    return _permissoes.firstWhere(
      (p) =>
          p.roleId == _roleId &&
          _normalizeTelaNome(p.telaNome) == telaNomeNormalizado,
      orElse: () => RolePermissao(
        id: 0,
        roleId: _roleId!,
        roleKey: '',
        roleDescription: '',
        telaNome: tela.telaNome,
        podeVer: false,
        podeInserir: false,
        podeEditar: false,
        podeDeletar: false,
        podeBaixar: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        title: const Text('Controle de Acesso'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _roles.isEmpty
              ? const Center(child: Text('Nenhuma role'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButton<int>(
                        value: _roleId,
                        isExpanded: true,
                        items: _roles
                            .map((r) => DropdownMenuItem<int>(
                                  value: r['id'] as int?,
                                  child: Text(r['description'] ?? ''),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _roleId = v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _buscaCtrl,
                        decoration: InputDecoration(
                          labelText: 'Buscar tela',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _busca.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar busca',
                                  icon: const Icon(Icons.clear),
                                  onPressed: _buscaCtrl.clear,
                                ),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    Expanded(child: _buildListaMobile()),
                  ],
                ),
    );
  }

  /// Fix (card #493): layout mobile otimizado - lista vertical com cards
  /// em vez de tabela horizontal. Cada tela tem seus checkboxes organizados
  /// em 2 linhas (Ver/Inserir/Editar na primeira, Deletar/Baixar na segunda).
  Widget _buildListaMobile() {
    if (_roleId == null) return const SizedBox();

    final grupos = RolePermissionCatalog.groups(query: _busca);
    if (grupos.isEmpty) {
      return const Center(child: Text('Nenhuma tela encontrada'));
    }

    return ListView(
      children: [
        for (final grupo in grupos) ...[
          _groupHeader(grupo),
          for (final tela in grupo.entries)
            Builder(
              builder: (context) {
                final p = _permissaoDe(tela);
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tela.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _permCheckbox(
                                'Ver',
                                p.podeVer,
                                () => _salvar(
                                    tela.telaNome, 'podeVer', !p.podeVer)),
                            _permCheckbox(
                                'Inserir',
                                p.podeInserir,
                                () => _salvar(tela.telaNome, 'podeInserir',
                                    !p.podeInserir)),
                            _permCheckbox(
                                'Editar',
                                p.podeEditar,
                                () => _salvar(tela.telaNome, 'podeEditar',
                                    !p.podeEditar)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _permCheckbox(
                                  'Deletar',
                                  p.podeDeletar,
                                  () => _salvar(tela.telaNome, 'podeDeletar',
                                      !p.podeDeletar)),
                            ),
                            Expanded(
                              child: _permCheckbox(
                                  'Baixar',
                                  p.podeBaixar,
                                  () => _salvar(tela.telaNome, 'podeBaixar',
                                      !p.podeBaixar)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _groupHeader(RolePermissionGroup grupo) {
    final grupoCompleto = resolveRolePermissionCompleteGroup(grupo);
    final value = rolePermissionGroupCheckboxValue(
      grupo: grupoCompleto,
      permissaoDe: _permissaoDe,
    );
    final salvando = _gruposSalvando.contains(grupoCompleto.id);
    final tooltip = salvando
        ? 'Salvando permissões de ${grupo.label}'
        : 'Marcar ou desmarcar todas as permissões de ${grupo.label}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Container(
        decoration: BoxDecoration(
          color: GridColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Tooltip(
              message: tooltip,
              child: Checkbox(
                value: value,
                tristate: true,
                semanticLabel: tooltip,
                onChanged:
                    salvando ? null : (_) => _salvarGrupo(grupo, value != true),
              ),
            ),
            Expanded(
              child: Text(
                grupo.label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            salvando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Tudo',
                    style: TextStyle(
                      fontSize: 12,
                      color: GridColors.textSecondary,
                    ),
                  ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  /// Widget para exibir checkbox com label (mobile-friendly)
  Widget _permCheckbox(String label, bool valor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: valor, onChanged: (_) => onTap()),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
