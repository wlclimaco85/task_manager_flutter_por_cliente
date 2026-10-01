import 'package:flutter/material.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/services/role_caller.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Widget reutilizável para seleção de roles com filtro por módulo
class RoleDropdownFiltered extends StatefulWidget {
  /// ID da empresa (opcional, prioridade baixa)
  final int? empresaId;

  /// ID do parceiro (opcional, prioridade alta)
  final int? parceiroId;

  /// Roles pré-selecionadas ao abrir o widget
  final List<Role> initialRoles;

  /// Callback quando a seleção muda
  final ValueChanged<List<Role>> onRolesChanged;

  const RoleDropdownFiltered({
    Key? key,
    this.empresaId,
    this.parceiroId,
    this.initialRoles = const [],
    required this.onRolesChanged,
  }) : super(key: key);

  @override
  State<RoleDropdownFiltered> createState() => _RoleDropdownFilteredState();
}

class _RoleDropdownFilteredState extends State<RoleDropdownFiltered> {
  late RoleCaller roleCaller;
  List<Role> availableRoles = [];
  List<Role> selectedRoles = [];
  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    roleCaller = RoleCaller();
    selectedRoles = List.from(widget.initialRoles);
    _loadRolesDisponiveis();
  }

  @override
  void didUpdateWidget(RoleDropdownFiltered oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se empresa ou parceiro mudou, recarrega as roles disponíveis
    if (oldWidget.empresaId != widget.empresaId ||
        oldWidget.parceiroId != widget.parceiroId) {
      _loadRolesDisponiveis();
    }
  }

  /// Carrega roles disponíveis do backend
  Future<void> _loadRolesDisponiveis() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final roles = await roleCaller.getRolesDisponiveis(
        empresaId: widget.empresaId,
        parceiroId: widget.parceiroId,
      );
      setState(() {
        availableRoles = roles;
        loading = false;
      });
    } catch (e) {
      L.d('Erro ao carregar roles: $e');
      setState(() {
        errorMessage = 'Erro ao carregar roles: $e';
        loading = false;
      });
    }
  }

  /// Verifica se uma role está elegível (pode ser selecionada)
  bool _isRoleEligible(Role role) {
    // Role é elegível se não tem módulo necessário (null)
    // Ou se temos dados de empresa/parceiro (dados disponíveis)
    return role.moduloNecessario == null;
  }

  /// Alterna seleção de uma role
  void _toggleRole(Role role, bool selected) {
    setState(() {
      if (selected) {
        if (!selectedRoles.any((r) => r.id == role.id)) {
          selectedRoles.add(role);
        }
      } else {
        selectedRoles.removeWhere((r) => r.id == role.id);
      }
    });
    widget.onRolesChanged(selectedRoles);
  }

  @override
  Widget build(BuildContext context) {
    // Em estado de loading
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Se erro, mostra mensagem com botão de retry
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRolesDisponiveis,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    // Se nenhuma role disponível
    if (availableRoles.isEmpty) {
      return const Center(
        child: Text('Nenhuma role disponível para este módulo'),
      );
    }

    // Lista de roles com checkboxes
    return SingleChildScrollView(
      child: Column(
        children: availableRoles.map((role) {
          final isSelected = selectedRoles.any((r) => r.id == role.id);
          final isEligible = _isRoleEligible(role);

          return CheckboxListTile(
            title: Text(
              role.description ?? 'Sem descrição',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isEligible ? Colors.black : Colors.grey,
              ),
            ),
            subtitle: role.moduloNecessario != null
                ? Tooltip(
                    message: 'Módulo ${role.moduloNecessario} não está contratado',
                    child: Row(
                      children: [
                        const Icon(Icons.lock, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Requer: ${role.moduloNecessario}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            value: isSelected && isEligible,
            enabled: isEligible,
            onChanged: isEligible
                ? (bool? value) {
                    _toggleRole(role, value ?? false);
                  }
                : null,
            controlAffinity: ListTileControlAffinity.leading,
          );
        }).toList(),
      ),
    );
  }
}
