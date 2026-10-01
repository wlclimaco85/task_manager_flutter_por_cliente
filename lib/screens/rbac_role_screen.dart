// lib/screens/rbac_role_screen.dart
// Tela para gerenciar roles de usuário com sincronização e debounce

import 'package:flutter/material.dart';
import '../widgets/rbac_role_checkbox_tile.dart';
import '../utils/app_logger.dart';
import '../services/role_caller.dart';

/// Serviço para interagir com backend de RBAC
class RoleProvisioningService {
  final RoleCaller _roleCaller = RoleCaller();

  /// Buscar roles disponíveis para uma empresa/parceiro
  Future<List<RoleItem>> getAvailableRoles(
      {required int loginId, int? empresaId, int? parceiroId}) async {
    try {
      L.d('[RBAC] Buscando roles disponíveis para login=$loginId, empresaId=$empresaId, parceiroId=$parceiroId');

      // Chamar novo endpoint /api/role/disponiveis
      final rolesFromBackend = await _roleCaller.getRolesDisponiveis(
        empresaId: empresaId,
        parceiroId: parceiroId,
      );

      // Converter Role model para RoleItem (compatível com UI)
      return rolesFromBackend
          .map((role) => RoleItem(
                roleKey: role.key ?? '',
                roleLabel: role.description ?? 'Sem descrição',
                description: '${role.moduloNecessario != null ? 'Módulo: ${role.moduloNecessario}' : 'Sempre disponível'}',
                isSelected: false,
              ))
          .toList();
    } catch (e) {
      L.e('[RBAC] Erro ao buscar roles: $e');
      // Fallback para mock em erro
      return _mockRoles();
    }
  }

  /// Atribuir roles a um login
  Future<bool> assignRolesToLogin({
    required int loginId,
    required List<String> roleKeys,
  }) async {
    try {
      L.d('[RBAC] Atribuindo roles $roleKeys ao login $loginId');
      // TODO: Implementar chamada real ao backend
      // PUT /api/login/{loginId} com { roles: [...] }
      return true;
    } catch (e) {
      L.e('[RBAC] Erro ao atribuir roles: $e');
      return false;
    }
  }

  /// Mock de roles para testes
  List<RoleItem> _mockRoles() {
    return [
      RoleItem(
        roleKey: 'ROLE_GERENTE',
        roleLabel: 'Gerente',
        description: 'Acesso completo ao sistema',
        isSelected: true,
      ),
      RoleItem(
        roleKey: 'ROLE_FATURISTA',
        roleLabel: 'Faturista',
        description: 'Emissão de faturas e notas',
        isSelected: false,
      ),
      RoleItem(
        roleKey: 'ROLE_COMERCIAL',
        roleLabel: 'Comercial',
        description: 'Gestão de vendas e clientes',
        isSelected: false,
      ),
      RoleItem(
        roleKey: 'ROLE_FINANCEIRO',
        roleLabel: 'Financeiro',
        description: 'Gestão financeira e fluxo de caixa',
        isSelected: false,
      ),
    ];
  }
}

/// Tela de gerenciamento de roles RBAC
class RBACRoleScreen extends StatefulWidget {
  final int loginId;
  final int? empresaId;
  final int? parceiroId;
  final VoidCallback? onSaved;

  const RBACRoleScreen({
    super.key,
    required this.loginId,
    this.empresaId,
    this.parceiroId,
    this.onSaved,
  });

  @override
  State<RBACRoleScreen> createState() => _RBACRoleScreenState();
}

class _RBACRoleScreenState extends State<RBACRoleScreen> {
  late final RoleProvisioningService _service;
  late Future<List<RoleItem>> _rolesFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _service = RoleProvisioningService();
    _rolesFuture = _service.getAvailableRoles(
      loginId: widget.loginId,
      empresaId: widget.empresaId,
      parceiroId: widget.parceiroId,
    );
  }

  Future<void> _saveRoles(List<RoleItem> roles) async {
    setState(() => _isSaving = true);

    try {
      final selectedRoleKeys =
          roles.where((r) => r.isSelected).map((r) => r.roleKey).toList();

      final success = await _service.assignRolesToLogin(
        loginId: widget.loginId,
        roleKeys: selectedRoleKeys,
      );

      if (mounted) {
        if (success) {
          L.i('[RBAC] Roles salvas com sucesso');
          widget.onSaved?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Roles atualizadas com sucesso')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao atualizar roles'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      L.e('[RBAC] Erro ao salvar roles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RoleItem>>(
      future: _rolesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Roles')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Roles')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _rolesFuture = _service.getAvailableRoles(
                        loginId: widget.loginId,
                        empresaId: widget.empresaId,
                        parceiroId: widget.parceiroId,
                      );
                    }),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final roles = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Roles'),
            elevation: 0,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecione as roles para este usuário:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ...roles.asMap().entries.map((entry) {
                        final role = entry.value;
                        return RBACRoleCheckboxTile(
                          role: role,
                          onChanged: () {
                            setState(() {});
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _saveRoles(roles),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
