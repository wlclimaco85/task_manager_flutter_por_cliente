import 'package:flutter/material.dart';

import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../models/role_model.dart';
import '../../services/role_caller.dart';
import '../../customization/generic_grid/grid_models.dart';
import '../../models/login_model.dart';
import '../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/login_payload_defaults.dart';
import 'details/login_detail_screen.dart';

class LoginGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;

  const LoginGridScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
  });

  static const String _defaultRoleLabel = 'Sem descrição';

  static Future<List<Map<String, dynamic>>> _loadRoles() async {
    final response = await NetworkCaller()
        .getRequest('${ApiLinks.baseUrl}/api/role/disponiveis');
    if (!response.isSuccess || response.body == null) return [];
    final lista = _extractList(response);
    return lista.map((e) {
      final desc = e['description']?.toString();
      final key = e['key']?.toString() ?? e['name']?.toString();
      final label = (desc != null && desc.isNotEmpty)
          ? desc
          : (key != null && key.isNotEmpty)
              ? key
              : _defaultRoleLabel;
      return {'value': e['id'].toString(), 'label': label};
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> _loadEmpresas() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allEmpresas);
    return _extractList(response)
        .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
        .toList();
  }

  static Future<List<Map<String, dynamic>>> _loadParceiros() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allParceiros);
    return _extractList(response)
        .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
        .toList();
  }

  static List<Map<String, dynamic>> _extractList(NetworkResponse response) {
    if (!response.isSuccess || response.body == null) return [];
    return _extractFrom(response.body);
  }

  static List<Map<String, dynamic>> _extractFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in ['data', 'dados', 'items', 'content', 'account']) {
        final nested = map[key];
        if (nested != null) {
          final extracted = _extractFrom(nested);
          if (extracted.isNotEmpty) return extracted;
        }
      }
      return [map];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'login',
      hasPermission: hasPermission,
      onUserBannerTapped: onUserBannerTapped,
      createEndpointOverride: ApiLinks.createLogin,
      updateEndpointOverride: ApiLinks.updateLogin(':id'),
      deleteEndpointOverride: ApiLinks.deleteLogin(':id'),
      additionalFormData: buildLoginAdditionalFormData(ativo: true),
      // mustChangePassword / passwordResetToken / passwordResetExpires são
      // derivados pelo backend a cada troca de senha (ver LoginController) —
      // não precisam mais ser calculados/enviados pelo Flutter.
      detailScreenBuilder: (item) => MobileLoginDetailScreen(
        item: Login.fromJson(item),
        hasPermission: hasPermission,
      ),
      fieldOverrides: [
        FieldConfig(
          label: 'Email',
          fieldName: 'email',
          icon: Icons.email,
          fieldType: FieldType.email,
          isInForm: true,
          isFilterable: true,
          isRequired: true,
          validator: (v) {
            if (v != null && v.isNotEmpty && !v.contains('@')) {
              return 'E-mail inválido';
            }
            return null;
          },
        ),
        FieldConfig(
          label: 'Nome',
          fieldName: 'nome',
          icon: Icons.person,
          fieldType: FieldType.text,
          isInForm: true,
          isFilterable: true,
          isRequired: true,
        ),
        FieldConfig(
          label: 'Roles',
          fieldName: 'roles',
          icon: Icons.security,
          fieldType: FieldType.multiselect,
          dropdownFutureBuilder: _loadRoles,
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: false,
        ),
        FieldConfig(
          label: 'Empresa',
          fieldName: 'empresa',
          displayFieldName: 'empresa.nome',
          icon: Icons.business,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: _loadEmpresas,
          dropdownValueField: 'id',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: true,
        ),
        FieldConfig(
          label: 'Parceiro',
          fieldName: 'parceiro',
          displayFieldName: 'parceiro.nome',
          icon: Icons.person_outline,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: _loadParceiros,
          dropdownValueField: 'id',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: true,
        ),
        FieldConfig(label: 'Aplicativo', fieldName: 'aplicativo', isInForm: false),
        FieldConfig(label: 'Aplicativo Empresa', fieldName: 'aplicativoEmpresa', isInForm: false),
        FieldConfig(label: 'Tipo Login', fieldName: 'tipoLogin', isInForm: false),
        FieldConfig(label: 'Trocar Senha', fieldName: 'trocarSenhaProximoLogin', isInForm: false),
        FieldConfig(label: 'Ativo', fieldName: 'ativo', isInForm: false),
        FieldConfig(label: 'Criado em', fieldName: 'dhCreatedAt', isInForm: false),
        FieldConfig(label: 'Atualizado em', fieldName: 'dhUpdatedAt', isInForm: false),
        FieldConfig(label: 'Must Change Password', fieldName: 'mustChangePassword', isInForm: false),
        FieldConfig(label: 'Password Reset Token', fieldName: 'passwordResetToken', isInForm: false),
        FieldConfig(label: 'Password Reset Expires', fieldName: 'passwordResetExpires', isInForm: false),
        FieldConfig(label: 'Setores', fieldName: 'setores', isInForm: false),
        const FieldConfig(
          label: 'Foto',
          fieldName: 'foto',
          icon: Icons.photo_camera,
          fieldType: FieldType.file,
          fileConfig: FileConfig(
            allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
            maxFileSize: 2 * 1024 * 1024,
          ),
          isInForm: true,
          isFilterable: false,
        ),
      ],
      customActions: () => [
        // Botão de permissões será adicionado no dialog mobile específico
      ],
    );
  }

}

class _MobileRoleDialog extends StatefulWidget {
  final dynamic loginId;
  final int? empresaId;
  final int? parceiroId;

  const _MobileRoleDialog({
    required this.loginId,
    this.empresaId,
    this.parceiroId,
  });

  @override
  State<_MobileRoleDialog> createState() => _MobileRoleDialogState();
}

class _MobileRoleDialogState extends State<_MobileRoleDialog> {
  late Future<List<Role>> _rolesFuture;
  final Set<int> _selectedRoleIds = {};

  @override
  void initState() {
    super.initState();
    _rolesFuture = RoleCaller().getRolesDisponiveis(
      empresaId: widget.empresaId,
      parceiroId: widget.parceiroId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerenciar Permissões'),
      content: FutureBuilder<List<Role>>(
        future: _rolesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text('Erro: ${snapshot.error}');
          }
          final roles = snapshot.data ?? [];
          return SizedBox(
            height: 300,
            width: 400,
            child: ListView.builder(
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                // CARD #319: Exibir descrição legível em vez de chave técnica bruta
                final displayTitle = (role.description != null && role.description!.isNotEmpty)
                    ? role.description!
                    : (role.key ?? 'Role #${role.id}');
                final displaySubtitle = (role.description != null && role.description!.isNotEmpty)
                    ? role.key ?? ''
                    : '';

                return CheckboxListTile(
                  title: Text(displayTitle),
                  subtitle: displaySubtitle.isNotEmpty ? Text(displaySubtitle) : null,
                  value: _selectedRoleIds.contains(role.id),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedRoleIds.add(role.id ?? 0);
                      } else {
                        _selectedRoleIds.remove(role.id);
                      }
                    });
                  },
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveRoleChanges,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _saveRoleChanges() async {
    try {
      for (final roleId in _selectedRoleIds) {
        await RoleCaller().associateRoleToLogin(widget.loginId, roleId);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissões atualizadas com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar permissões: $e')),
        );
      }
    }
  }
}
