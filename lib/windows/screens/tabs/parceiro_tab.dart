import 'package:flutter/material.dart';

import '../../../models/regime_tributario_model.dart';
import '../../../widgets/tab_config.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType;

List<TabConfig> tabConfigs = [
  // ----------------------------------------------------
  // ABA DE FORMULÁRIO (FIELDS = FieldConfigWindows)
  // ----------------------------------------------------
  TabConfig(
    title: "Dados Principais",
    icon: Icons.person,
    isGrid: false,
    formFields: [
      const FieldConfigWindows(
        label: "Nome",
        fieldName: "nome",
        icon: Icons.person,
        fieldType: FieldType.text,
        isInForm: true,
        isRequired: true,
      ),
      const FieldConfigWindows(
        label: "CPF",
        fieldName: "cpf",
        icon: Icons.badge,
        fieldType: FieldType.text,
        isInForm: true,
      ),
      const FieldConfigWindows(
        label: "E-mail",
        fieldName: "email",
        icon: Icons.email,
        fieldType: FieldType.email,
        isInForm: true,
      ),
    ],
  ),

  // ----------------------------------------------------
  // ABA GRID → EMPRESAS
  // ----------------------------------------------------
  TabConfig(
    title: "Empresas",
    icon: Icons.business,
    isGrid: true,
    formFields: [
      const FieldConfigWindows(
        label: "Nome",
        fieldName: "nome",
        fieldType: FieldType.text,
        icon: Icons.business,
      ),
      const FieldConfigWindows(
        label: "CNPJ",
        fieldName: "cnpj",
        fieldType: FieldType.text,
        icon: Icons.badge,
      ),
    ],
  ),

  // ----------------------------------------------------
  // ABA GRID → ENDEREÇOS
  // ----------------------------------------------------
  TabConfig(
    title: "Endereços",
    icon: Icons.location_city,
    isGrid: true,
    formFields: [
      const FieldConfigWindows(
        label: "Logradouro",
        fieldName: "logradouro",
        fieldType: FieldType.text,
        icon: Icons.location_on,
      ),
      const FieldConfigWindows(
        label: "Cidade",
        fieldName: "cidade",
        fieldType: FieldType.text,
        icon: Icons.location_city,
      ),
    ],
  ),

  // ----------------------------------------------------
  // ABA GRID → REGIMES TRIBUTÁRIOS
  // ----------------------------------------------------
  TabConfig(
    title: "Regimes Tributários",
    icon: Icons.receipt_long,
    isGrid: true,
    formFields: RegimeTributario.fieldConfigsWindows(), // AGORA FUNCIONA
  ),
];
