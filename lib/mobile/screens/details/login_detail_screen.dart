import 'package:flutter/material.dart';
import '../../../models/login_model.dart';
import '../../../models/empresa_model.dart';
import '../../../models/parceiro_model.dart';
import '../../../models/aplicativo_model.dart';
import '../../../models/role_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldType, FieldConfigWindows;
import '../../../services/network_caller.dart';
import '../../../widgets/login_setores_detail.dart';
import '../../../widgets/login_roles_detail.dart';

class MobileLoginDetailScreen extends StatelessWidget {
  final Login item;
  final SecurityCheck hasPermission;

  const MobileLoginDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  /// Carrega roles disponíveis filtradas por parceiroId/empresaId e inclui as roles atuais
  Future<List<Map<String, dynamic>>> _loadRolesDisponiveis(
    String? parceiroId,
    String? empresaId,
    List<Role>? currentRoles,
  ) async {
    List<Map<String, dynamic>> list = [];
    try {
      String endpoint = ApiLinks.rolesDisponiveis;
      List<String> params = [];
      if (parceiroId?.isNotEmpty == true) {
        params.add('parceiroId=$parceiroId');
      }
      if (empresaId?.isNotEmpty == true) {
        params.add('empresaId=$empresaId');
      }
      if (params.isNotEmpty) {
        endpoint += '?' + params.join('&');
      }

      final response = await NetworkCaller().getRequest(endpoint);
      if (response.isSuccess && response.body is List) {
        list = (response.body as List)
            .map((r) => r is Map<String, dynamic> ? r : <String, dynamic>{})
            .toList();
      }
    } catch (_) {}

    if (currentRoles != null) {
      for (final r in currentRoles) {
        if (r.id != null) {
          final rid = r.id.toString();
          if (!list.any((entry) => entry['id']?.toString() == rid)) {
            list.insert(0, {
              'id': r.id,
              'name': r.description ?? r.key ?? 'Role #$rid',
              'description': r.description ?? r.key ?? 'Role #$rid',
            });
          }
        }
      }
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> _loadParceiros(Parceiro? currentParceiro) async {
    List<Map<String, dynamic>> list = [];
    try {
      final response = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/parceiro?pagina=0&tamanho=500&semFiltroParceiro=true',
      );
      if (response.isSuccess && response.body != null) {
        final dynamic body = response.body;
        final raw = body is Map
            ? (body['content'] ?? body['items'] ?? body['dados'] ?? body['data'])
            : body;
        if (raw is List) {
          list = raw
              .map((e) => e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    } catch (_) {}

    if (currentParceiro != null && currentParceiro.id != null) {
      final currentId = currentParceiro.id.toString();
      if (!list.any((p) => p['id']?.toString() == currentId)) {
        list.insert(0, {
          'id': currentParceiro.id,
          'nome': currentParceiro.nome ?? currentParceiro.razaoSocial ?? 'Parceiro #$currentId',
        });
      }
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> _loadEmpresas(Empresa? currentEmpresa) async {
    List<Map<String, dynamic>> list = [];
    try {
      final response = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/empresa?pagina=0&tamanho=500',
      );
      if (response.isSuccess && response.body != null) {
        final dynamic body = response.body;
        final raw = body is Map
            ? (body['content'] ?? body['items'] ?? body['dados'] ?? body['data'])
            : body;
        if (raw is List) {
          list = raw
              .map((e) => e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    } catch (_) {}

    if (currentEmpresa != null && currentEmpresa.id != null) {
      final currentId = currentEmpresa.id.toString();
      if (!list.any((e) => e['id']?.toString() == currentId)) {
        list.insert(0, {
          'id': currentEmpresa.id,
          'nome': currentEmpresa.nome ?? 'Empresa #$currentId',
        });
      }
    }
    return list;
  }

  Future<List<Map<String, dynamic>>> _loadAplicativos(Aplicativo? currentApp) async {
    List<Map<String, dynamic>> list = [];
    try {
      final response = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/aplicativo?pagina=0&tamanho=100',
      );
      if (response.isSuccess && response.body != null) {
        final dynamic body = response.body;
        final raw = body is Map
            ? (body['content'] ?? body['items'] ?? body['dados'] ?? body['data'])
            : body;
        if (raw is List) {
          list = raw
              .map((e) => e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    } catch (_) {}

    if (currentApp != null && currentApp.id != null) {
      final currentId = currentApp.id.toString();
      if (!list.any((a) => a['id']?.toString() == currentId)) {
        list.insert(0, {
          'id': currentApp.id,
          'nome': currentApp.nome ?? 'Aplicativo #$currentId',
        });
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final loginId = item.id?.toString() ?? '';
    final empresaId = item.empresa?.id?.toString() ?? '';
    final parceiroId = item.parceiro?.id?.toString() ?? '';

    final fieldOverrides = [
      FieldConfigWindows(
        fieldName: 'tipo_login',
        label: 'Tipo de Login',
        fieldType: FieldType.dropdown,
        enabled: false,
        dropdownOptions: [
          {'id': 'MASTER', 'nome': 'Administrador (MASTER)'},
          {'id': 'APP_PERSONAL', 'nome': 'Personal (APP_PERSONAL)'},
          {'id': 'APP_ACADEMIA', 'nome': 'Academia (APP_ACADEMIA)'},
          {'id': 'APP_NUTRICIONISTA', 'nome': 'Nutricionista (APP_NUTRICIONISTA)'},
          {'id': 'APP_ALUNO', 'nome': 'Aluno (APP_ALUNO)'},
          {'id': 'APP_ABRACO', 'nome': 'Abraço (APP_ABRACO)'},
          {'id': 'APP_CONTABILIDADE', 'nome': 'Contabilidade (APP_CONTABILIDADE)'},
          {'id': 'APP_SITE_JOAO', 'nome': 'Site João (APP_SITE_JOAO)'},
        ],
      ),
      FieldConfigWindows(
        fieldName: 'tipoLogin',
        label: 'Tipo de Login',
        fieldType: FieldType.dropdown,
        enabled: false,
        dropdownOptions: [
          {'id': 'MASTER', 'nome': 'Administrador (MASTER)'},
          {'id': 'APP_PERSONAL', 'nome': 'Personal (APP_PERSONAL)'},
          {'id': 'APP_ACADEMIA', 'nome': 'Academia (APP_ACADEMIA)'},
          {'id': 'APP_NUTRICIONISTA', 'nome': 'Nutricionista (APP_NUTRICIONISTA)'},
          {'id': 'APP_ALUNO', 'nome': 'Aluno (APP_ALUNO)'},
          {'id': 'APP_ABRACO', 'nome': 'Abraço (APP_ABRACO)'},
          {'id': 'APP_CONTABILIDADE', 'nome': 'Contabilidade (APP_CONTABILIDADE)'},
          {'id': 'APP_SITE_JOAO', 'nome': 'Site João (APP_SITE_JOAO)'},
        ],
      ),
      FieldConfigWindows(
        fieldName: 'aplicativo',
        label: 'Aplicativo',
        fieldType: FieldType.dropdown,
        enabled: false,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        dropdownFutureBuilder: () => _loadAplicativos(item.aplicativo),
      ),
      FieldConfigWindows(
        fieldName: 'parceiro',
        label: 'Parceiro',
        fieldType: FieldType.dropdown,
        isRequired: false,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        dropdownFutureBuilder: () => _loadParceiros(item.parceiro),
      ),
      FieldConfigWindows(
        fieldName: 'empresa',
        label: 'Empresa',
        fieldType: FieldType.dropdown,
        isRequired: false,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        dropdownFutureBuilder: () => _loadEmpresas(item.empresa),
      ),
      FieldConfigWindows(
        fieldName: 'roles',
        label: 'Roles',
        fieldType: FieldType.multiselect,
        isRequired: false,
        dropdownValueField: 'id',
        dropdownDisplayField: 'description',
        dropdownFutureBuilder: () =>
            _loadRolesDisponiveis(parceiroId, empresaId, item.roles),
      ),
      FieldConfigWindows(
        fieldName: 'foto',
        label: 'Foto de Perfil',
        fieldType: FieldType.file,
        isRequired: false,
      ),
      FieldConfigWindows(
        fieldName: 'cpf_cnpj',
        label: 'CPF / CNPJ',
        fieldType: FieldType.cpf,
        isRequired: false,
      ),
      FieldConfigWindows(
        fieldName: 'cpfCnpj',
        label: 'CPF / CNPJ',
        fieldType: FieldType.cpf,
        isRequired: false,
      ),
      FieldConfigWindows(
        fieldName: 'ativo',
        label: 'Ativo',
        fieldType: FieldType.boolean,
        isRequired: false,
      ),
      FieldConfigWindows(
        fieldName: 'aplicativo_empresa',
        label: 'Aplicativo Empresa',
        fieldType: FieldType.text,
        isInForm: false,
      ),
      FieldConfigWindows(
        fieldName: 'aplicativoEmpresa',
        label: 'Aplicativo Empresa',
        fieldType: FieldType.text,
        isInForm: false,
      ),
      FieldConfigWindows(
        fieldName: 'password_reset_token',
        label: 'Token',
        fieldType: FieldType.text,
        isInForm: false,
      ),
      FieldConfigWindows(
        fieldName: 'password_reset_expires',
        label: 'Expiração',
        fieldType: FieldType.text,
        isInForm: false,
      ),
      FieldConfigWindows(
        fieldName: 'must_change_password',
        label: 'Trocar Senha',
        fieldType: FieldType.boolean,
        isInForm: false,
      ),
      FieldConfigWindows(
        fieldName: 'trocar_senha_proximo_login',
        label: 'Trocar Senha',
        fieldType: FieldType.boolean,
        isInForm: false,
      ),
    ];

    return GenericDetailFormScreen(
      item: item.toJson(),
      telaNome: 'login',
      hasPermission: hasPermission,
      fieldOverrides: fieldOverrides,
      relatedTabs: [
        RelatedGridTab(
          title: 'Roles',
          icon: Icons.security,
          telaNome: 'role',
          extraParams: {'loginId': loginId, 'empresaId': empresaId, 'parceiroId': parceiroId},
          // Endpoint com /boletobancos (extrai base do rolesDisponiveis)
          deleteEndpointOverride:
              '${ApiLinks.rolesDisponiveis.replaceAll('/api/role/disponiveis', '')}/api/logins/$loginId/roles/:id',
        ),
        RelatedGridTab(
          title: 'Setores',
          icon: Icons.business_center,
          customWidget: LoginSetoresDetail(loginId: item.id),
        ),
        RelatedGridTab(
          title: 'Chamados',
          icon: Icons.support_agent,
          telaNome: 'chamado',
          extraParams: {'usuarioAberturaId': loginId, 'empresaId': empresaId, 'parceiroId': parceiroId},
        ),
      ],
    );
  }
}
