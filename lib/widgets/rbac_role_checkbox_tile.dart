// lib/widgets/rbac_role_checkbox_tile.dart
// Widget reutilizável para checkbox de role com sincronização e debounce

import 'package:flutter/material.dart';
import 'dart:async';

/// Representa uma role que pode ser atribuída a um usuário
class RoleItem {
  final String roleKey;
  final String roleLabel;
  final String? description;
  bool isSelected;

  RoleItem({
    required this.roleKey,
    required this.roleLabel,
    this.description,
    this.isSelected = false,
  });
}

/// Widget para exibir e gerenciar checkbox de role com debounce
class RBACRoleCheckboxTile extends StatefulWidget {
  final RoleItem role;
  final VoidCallback? onChanged;
  final bool enabled;
  final Duration debounceDuration;

  const RBACRoleCheckboxTile({
    super.key,
    required this.role,
    this.onChanged,
    this.enabled = true,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<RBACRoleCheckboxTile> createState() => _RBACRoleCheckboxTileState();
}

class _RBACRoleCheckboxTileState extends State<RBACRoleCheckboxTile> {
  late bool _localCheckboxState;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _localCheckboxState = widget.role.isSelected;
  }

  @override
  void didUpdateWidget(RBACRoleCheckboxTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincronizar estado local com estado da role quando vem do backend
    if (oldWidget.role.isSelected != widget.role.isSelected) {
      setState(() {
        _localCheckboxState = widget.role.isSelected;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onCheckboxChanged(bool? newValue) {
    if (newValue == null) return;

    // Atualizar estado local imediatamente para feedback visual
    setState(() {
      _localCheckboxState = newValue;
    });

    // Cancelar debounce anterior
    _debounceTimer?.cancel();

    // Iniciar novo debounce antes de chamar callback
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.role.isSelected = newValue;
      widget.onChanged?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: _localCheckboxState,
      onChanged: widget.enabled ? _onCheckboxChanged : null,
      title: Text(
        widget.role.roleLabel,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: widget.enabled ? Colors.black87 : Colors.grey,
            ),
      ),
      subtitle: widget.role.description != null
          ? Text(
              widget.role.description!,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      activeColor: Colors.green,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      dense: true,
    );
  }
}
