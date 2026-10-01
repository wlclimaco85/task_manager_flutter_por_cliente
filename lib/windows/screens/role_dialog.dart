import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../../models/role_model.dart';
import '../../services/role_caller.dart';


class RoleDialog extends StatefulWidget {
  final int loginId;
  final int? empresaId;
  final int? parceiroId;

  const RoleDialog({
    super.key,
    required this.loginId,
    this.empresaId,
    this.parceiroId,
  });

  @override
  _RoleDialogState createState() => _RoleDialogState();
}

class _RoleDialogState extends State<RoleDialog> {
  Role? _selectedRole;
  List<Role> _roles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  _loadRoles() async {
    try {
      final roles = await RoleCaller().getRolesDisponiveis(
        empresaId: widget.empresaId,
        parceiroId: widget.parceiroId,
      );
      setState(() {
        _roles = roles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  _associateRole() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(GridTexts.roleSelectRequired),
          backgroundColor: GridColors.error,
        ),
      );
      return;
    }

    try {
      await RoleCaller().associateRoleToLogin(
        widget.loginId,
        _selectedRole?.id ?? 0,
      );
      Navigator.of(context).pop(true); // Fecha o diálogo e indica sucesso
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${GridTexts.roleAssociateErrorPrefix} $e'),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GridColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              GridTexts.roleDialogTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GridColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: GridColors.error))
            else
              DropdownButtonFormField<Role>(
                decoration: const InputDecoration(
                  labelText: GridTexts.roleFieldLabel,
                  labelStyle: TextStyle(color: GridColors.inputBorder),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: GridColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: GridColors.primary),
                  ),
                ),
                initialValue: _selectedRole,
                items: _roles.map((Role role) {
                  return DropdownMenuItem<Role>(
                    value: role,
                    child: Text(role.description ?? ''),
                  );
                }).toList(),
                onChanged: (Role? newValue) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                },
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text(
                    GridTexts.cancel,
                    style: TextStyle(color: GridColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _associateRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.buttonBackground,
                  ),
                  child: const Text(
                    GridTexts.roleAssociateAction,
                    style: TextStyle(color: GridColors.buttonText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
