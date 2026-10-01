import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/role_permissao_model.dart';
import 'package:task_manager_flutter/utils/role_permission_catalog.dart';
import 'package:task_manager_flutter/utils/role_permission_group_selection.dart';

RolePermissionMenuEntry _entry(String label, String telaNome) {
  return RolePermissionMenuEntry(
    groupId: 'suporte',
    groupLabel: 'Suporte / Comunicação',
    menuItemId: label.toLowerCase(),
    label: label,
    telaNome: telaNome,
  );
}

RolePermissao _permissao(
  String telaNome, {
  bool ver = false,
  bool inserir = false,
  bool editar = false,
  bool deletar = false,
  bool baixar = false,
}) {
  return RolePermissao(
    id: 1,
    roleId: 7,
    roleKey: 'gerente',
    roleDescription: 'Gerente',
    telaNome: telaNome,
    podeVer: ver,
    podeInserir: inserir,
    podeEditar: editar,
    podeDeletar: deletar,
    podeBaixar: baixar,
  );
}

void main() {
  test('checkbox do grupo marca somente telas do menu selecionado', () {
    final chat = _entry('Chat', 'chat');
    final comunicados = _entry('Comunicados', 'comunicados');
    final nfe = RolePermissionMenuEntry(
      groupId: 'fiscal',
      groupLabel: 'Fiscal / NFC-e',
      menuItemId: 'nfe_saida',
      label: 'NF-e Saída',
      telaNome: 'nfeSaida',
    );
    final suporte = RolePermissionGroup(
      id: 'suporte',
      label: 'Suporte / Comunicação',
      entries: [chat, comunicados],
    );
    final fiscal = RolePermissionGroup(
      id: 'fiscal',
      label: 'Fiscal / NFC-e',
      entries: [nfe],
    );

    final permissoes = <String, RolePermissao>{
      'chat': _permissao(
        'chat',
        ver: true,
        inserir: true,
        editar: true,
        deletar: true,
        baixar: true,
      ),
      'comunicados': _permissao('comunicados'),
      'nfeSaida': _permissao('nfeSaida'),
    };

    RolePermissao permissaoDe(RolePermissionMenuEntry tela) {
      return permissoes[tela.telaNome] ?? _permissao(tela.telaNome);
    }

    expect(
      rolePermissionGroupCheckboxValue(
        grupo: suporte,
        permissaoDe: permissaoDe,
      ),
      isNull,
    );

    final batch = buildRolePermissionGroupBatch(
      roleId: 7,
      grupo: suporte,
      marcar: true,
    );

    expect(batch, hasLength(2));
    expect(batch.map((item) => item['telaNome']), ['chat', 'comunicados']);
    expect(batch.any((item) => item['telaNome'] == 'nfeSaida'), isFalse);
    for (final item in batch) {
      for (final campo in rolePermissionFields) {
        expect(item[campo], isTrue);
      }
    }

    for (final item in batch) {
      final telaNome = item['telaNome']! as String;
      permissoes[telaNome] = rolePermissionWithAllFields(
        permissoes[telaNome]!,
        valor: true,
      );
    }
    expect(
      rolePermissionGroupCheckboxValue(
        grupo: suporte,
        permissaoDe: permissaoDe,
      ),
      isTrue,
    );

    permissoes['chat'] = permissoes['chat']!.copyWith(podeEditar: false);
    expect(
      rolePermissionGroupCheckboxValue(
        grupo: suporte,
        permissaoDe: permissaoDe,
      ),
      isNull,
    );
    expect(
      rolePermissionGroupCheckboxValue(
        grupo: fiscal,
        permissaoDe: permissaoDe,
      ),
      isFalse,
    );
  });

  test('checkbox do grupo filtrado resolve o menu completo antes de salvar',
      () {
    final chat = _entry('Chat', 'chat');
    final comunicados = _entry('Comunicados', 'comunicados');
    final grupoFiltrado = RolePermissionGroup(
      id: 'suporte',
      label: 'Suporte / Comunicação',
      entries: [chat],
    );
    final grupoCompleto = RolePermissionGroup(
      id: 'suporte',
      label: 'Suporte / Comunicação',
      entries: [chat, comunicados],
    );

    final resolvido = resolveRolePermissionCompleteGroup(
      grupoFiltrado,
      allGroups: [grupoCompleto],
    );
    final batch = buildRolePermissionGroupBatch(
      roleId: 7,
      grupo: resolvido,
      marcar: true,
    );

    expect(resolvido.entries, hasLength(2));
    expect(batch.map((item) => item['telaNome']), ['chat', 'comunicados']);
  });
}
