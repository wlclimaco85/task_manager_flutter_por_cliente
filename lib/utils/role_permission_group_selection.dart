import '../models/role_permissao_model.dart';
import 'role_permission_catalog.dart';

const List<String> rolePermissionFields = [
  'podeVer',
  'podeInserir',
  'podeEditar',
  'podeDeletar',
  'podeBaixar',
];

bool rolePermissionFieldValue(RolePermissao permissao, String campo) {
  return switch (campo) {
    'podeVer' => permissao.podeVer,
    'podeInserir' => permissao.podeInserir,
    'podeEditar' => permissao.podeEditar,
    'podeDeletar' => permissao.podeDeletar,
    'podeBaixar' => permissao.podeBaixar,
    _ => false,
  };
}

bool? rolePermissionGroupCheckboxValue({
  required RolePermissionGroup grupo,
  required RolePermissao Function(RolePermissionMenuEntry tela) permissaoDe,
}) {
  if (grupo.entries.isEmpty) return false;

  var total = 0;
  var marcados = 0;

  for (final tela in grupo.entries) {
    final permissao = permissaoDe(tela);
    for (final campo in rolePermissionFields) {
      total++;
      if (rolePermissionFieldValue(permissao, campo)) {
        marcados++;
      }
    }
  }

  if (marcados == 0) return false;
  if (marcados == total) return true;
  return null;
}

RolePermissionGroup resolveRolePermissionCompleteGroup(
  RolePermissionGroup grupo, {
  List<RolePermissionGroup>? allGroups,
}) {
  final groups = allGroups ?? RolePermissionCatalog.groups();
  return groups.firstWhere(
    (candidate) => candidate.id == grupo.id,
    orElse: () => grupo,
  );
}

List<Map<String, Object>> buildRolePermissionGroupBatch({
  required int roleId,
  required RolePermissionGroup grupo,
  required bool marcar,
}) {
  return grupo.entries
      .map(
        (tela) => <String, Object>{
          'roleId': roleId,
          'telaNome': tela.telaNome,
          for (final campo in rolePermissionFields) campo: marcar,
        },
      )
      .toList();
}

RolePermissao rolePermissionWithAllFields(
  RolePermissao permissao, {
  required bool valor,
}) {
  return permissao.copyWith(
    podeVer: valor,
    podeInserir: valor,
    podeEditar: valor,
    podeDeletar: valor,
    podeBaixar: valor,
  );
}
