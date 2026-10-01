class RolePermissao {
  final int id;
  final int roleId;
  final String roleKey;
  final String roleDescription;
  final String telaNome;
  final bool podeVer;
  final bool podeInserir;
  final bool podeEditar;
  final bool podeDeletar;
  final bool podeBaixar;

  RolePermissao({
    required this.id,
    required this.roleId,
    required this.roleKey,
    required this.roleDescription,
    required this.telaNome,
    required this.podeVer,
    required this.podeInserir,
    required this.podeEditar,
    required this.podeDeletar,
    required this.podeBaixar,
  });

  factory RolePermissao.fromJson(Map<String, dynamic> json) {
    return RolePermissao(
      id: json['id'] ?? 0,
      roleId: json['roleId'] ?? 0,
      roleKey: json['roleKey'] ?? '',
      roleDescription: json['roleDescription'] ?? '',
      telaNome: json['telaNome'] ?? '',
      podeVer: json['podeVer'] ?? false,
      podeInserir: json['podeInserir'] ?? false,
      podeEditar: json['podeEditar'] ?? false,
      podeDeletar: json['podeDeletar'] ?? false,
      podeBaixar: json['podeBaixar'] ?? false,
    );
  }

  RolePermissao copyWith({bool? podeVer, bool? podeInserir, bool? podeEditar, bool? podeDeletar, bool? podeBaixar}) {
    return RolePermissao(
      id: id,
      roleId: roleId,
      roleKey: roleKey,
      roleDescription: roleDescription,
      telaNome: telaNome,
      podeVer: podeVer ?? this.podeVer,
      podeInserir: podeInserir ?? this.podeInserir,
      podeEditar: podeEditar ?? this.podeEditar,
      podeDeletar: podeDeletar ?? this.podeDeletar,
      podeBaixar: podeBaixar ?? this.podeBaixar,
    );
  }
}
