import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print("Uso: dart run tool/crud_cli.dart Login");
    exit(0);
  }

  final name = args.first.trim();
  final lower = name.toLowerCase();
  final modelFile = "lib/models/${lower}_model.dart";
  final telaConfigFile = "lib/data/models/telas/${lower}_tela_config.dart";
  final screenFile = "lib/screens/$lower/${lower}_grid_screen.dart";

  print("Gerando CRUD para: $name");

  File(screenFile).createSync(recursive: true);
  File(screenFile).writeAsStringSync("""
import 'package:flutter/material.dart';
import '../../data/customization/templates/generic_crud_generator.dart';
import '../../data/models/telas/${lower}_tela_config.dart';
import '../../models/${lower}_model.dart';

class ${name}GridScreen extends StatelessWidget {
  final permission = (String p) => true;

  ${name}GridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudGenerator<$name>(
      tela: ${name}TelaConfig.config,
      fromJson: (json) => $name.fromJson(json),
      toJson: (e) => e.toJson(),
      permissionCheck: permission,
    ).buildGrid();
  }
}
""");

  print("✔ Arquivo criado: $screenFile");
  print("✔ CRUD de $name gerado com sucesso!");
}
