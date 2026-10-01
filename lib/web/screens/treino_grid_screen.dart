import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../models/treino_model.dart';
import '../../../utils/pdf_export_helper.dart';

class WebTreinoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebTreinoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final nomeAluno = AuthUtility.userInfo?.data?.codDadosPessoal?.nome ?? 'Aluno';
    return DynamicGridWindowsScreen<Treino>(
      telaNome: 'treino',
      hasPermission: hasPermission,
      fromJson: (json) => Treino.fromJson(json),
      toJson: (a) => a.toJson(),
      headerActions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF93070A)),
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text('Exportar PDF', style: TextStyle(color: Colors.white)),
          onPressed: () => PdfExportHelper.exportarListaGenerica(
            context,
            titulo: 'Treinos',
            nomeAluno: nomeAluno,
            registros: const [],
          ),
        ),
      ],
    );
  }
}


