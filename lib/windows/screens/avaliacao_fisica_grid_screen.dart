import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../models/avaliacao_fisica_model.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/pdf_export_helper.dart';
import '../../web/screens/avaliacao_fisica_wizard_screen.dart';

class WindowsAvaliacaoFisicaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsAvaliacaoFisicaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final nomeAluno = AuthUtility.userInfo?.data?.codDadosPessoal?.nome ?? 'Aluno';
    return DynamicGridWindowsScreen<AvaliacaoFisica>(
      telaNome: 'AvaliacaoFisica',
      hasPermission: hasPermission,
      fromJson: (json) => AvaliacaoFisica.fromJson(json),
      toJson: (a) => a.toJson(),
      headerActions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: GridColors.primary),
          icon: const Icon(Icons.assignment_add, color: Colors.white),
          label: const Text('Nova Avaliação Guiada', style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AvaliacaoFisicaWizardScreen()),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF93070A)),
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text('Exportar PDF', style: TextStyle(color: Colors.white)),
          onPressed: () => PdfExportHelper.exportarListaGenerica(
            context,
            titulo: 'Avaliação Física',
            nomeAluno: nomeAluno,
            registros: const [],
          ),
        ),
      ],
    );
  }
}
