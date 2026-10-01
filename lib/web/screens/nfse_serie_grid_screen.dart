import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType;

/// Bug de producao (2026-09-16, ver bugs.md): o dropdown "Serie" ao emitir
/// NFSe busca em /api/nfse-serie (tabela nfse_serie, separada de
/// nfe_serie), mas nao havia tela Web/Windows pra cadastrar essa serie --
/// so' o Mobile tinha (NfseSerieScreen). A tela dinamica 'nfse_serie' ja
/// existia no backend (mesma estrutura de 'nfe_serie', ver
/// NfseSerieController + tela_fields), so' faltava o MenuItem + esta tela.
class WebNfseSerieGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebNfseSerieGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final login = AuthUtility.userInfo?.login;
    final empresa = login?.empresa;
    final parceiro = login?.parceiro;

    final empresaIdStr = empresa?.id?.toString() ?? '';
    final empresaNome = empresa?.nome ?? '';
    final parceiroIdStr = parceiro?.id?.toString() ?? '';
    final parceiroNome = parceiro?.nome ?? '';

    final overrides = <FieldConfigWindows>[
      if (empresaIdStr.isNotEmpty)
        FieldConfigWindows(
          label: 'Empresa',
          fieldName: 'empresa',
          displayFieldName: 'empresa.nome',
          icon: Icons.business,
          isFilterable: true,
          isInForm: true,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () async => [
            {'id': empresaIdStr, 'nome': empresaNome},
          ],
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownSelectedValue: empresaIdStr,
          enabled: false,
        ),
      if (parceiroIdStr.isNotEmpty)
        FieldConfigWindows(
          label: 'Parceiro',
          fieldName: 'parceiro',
          displayFieldName: 'parceiro.nome',
          icon: Icons.person_outline,
          isFilterable: true,
          isInForm: true,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () async => [
            {'id': parceiroIdStr, 'nome': parceiroNome},
          ],
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownSelectedValue: parceiroIdStr,
          enabled: false,
        ),
      FieldConfigWindows(
        label: 'Tipo da Série',
        fieldName: 'tipo',
        isFilterable: true,
        isInForm: true,
        fieldType: FieldType.dropdown,
        dropdownOptions: const [
          {'value': 'NF-e', 'label': 'NF-e'},
          {'value': 'NFS-e', 'label': 'NFS-e'},
          {'value': 'NFC-e', 'label': 'NFC-e'},
        ],
        dropdownValueField: 'value',
        dropdownDisplayField: 'label',
      ),
    ];

    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'nfse_serie',
      hasPermission: hasPermission,
      fromJson: (j) => j,
      toJson: (a) => a,
      fieldOverrides: overrides.isNotEmpty ? overrides : null,
    );
  }
}
