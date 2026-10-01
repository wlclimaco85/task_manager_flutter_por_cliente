import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/file_attachment_model.dart';
import '../../../models/network_response.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../services/network_caller.dart';

class WebFileAttachmentGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebFileAttachmentGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<FileAttachment>(
      telaNome: 'file_attachment', // nome da tela no banco
      hasPermission: hasPermission,
      fromJson: (json) => FileAttachment.fromJson(json),
      toJson: (a) => a.toJson(),

      // 🔥 AQUI entram os botões extras por linha
      customActions: () => [
        CustomAction<FileAttachment>(
          icon: Icons.payment,
          label: 'Download',
          onPressed: (context, object) => _downloadFile(context, object),
          isVisible: (chamado) {
            // exemplo genérico, muda conforme seu ChamadoModel:
            // return chamado.status != 'FECHADO';
            return true;
          },
        ),
      ],
    );
  }

  void _downloadFile(BuildContext context, FileAttachment arquivo) async {
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        ApiLinks.downloadArquivo(arquivo.id.toString()),
      );

      if (response.isSuccess && response.body != null) {
        // Implementar lógica de download do arquivo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download iniciado: ${arquivo.fileName}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer download: $response')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }
}

