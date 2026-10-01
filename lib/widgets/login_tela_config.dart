import 'package:flutter/material.dart';
import '../../../models/telas_model.dart';

class LoginTelaConfig {
  static TelaConfig get config {
    return TelaConfig(
      id: 1, // coloque um id qualquer fixo ou do banco
      nome: "logins", // nome técnico da tela
      titulo: "Logins",

      fetchEndpoint: "/logins/list",
      createEndpoint: "/logins",
      updateEndpoint: "/logins/:id",
      deleteEndpoint: "/logins/:id",

      idFieldName: "id",
      dateFieldName: "createdAt",
      enableSearch: true,

      fields: [
        TelaField(
          label: "ID",
          fieldName: "id",
          fieldType: TelaFieldType.number,
          isVisibleByDefault: true,
          isFilterable: true,
          isInForm: false,
          isSortable: true,
          isFixed: true,
        ),
        TelaField(
          label: "Usuário",
          fieldName: "usuario",
          fieldType: TelaFieldType.text,
          isRequired: true,
          isFilterable: true,
          iconData: Icons.person,
          isInForm: true,
        ),
        TelaField(
          label: "Email",
          fieldName: "email",
          fieldType: TelaFieldType.email,
          isRequired: true,
          iconData: Icons.email,
          isFilterable: true,
        ),
        TelaField(
          label: "Ativo",
          fieldName: "ativo",
          fieldType: TelaFieldType.boolean,
          isInForm: true,
          defaultValue: true,
        ),
      ],
    );
  }
}
