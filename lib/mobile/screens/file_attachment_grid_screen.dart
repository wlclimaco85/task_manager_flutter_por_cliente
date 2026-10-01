import 'package:flutter/material.dart';
import '../../../models/file_attachment_model.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../customization/generic_grid_card.dart';

class FileAttachmentGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const FileAttachmentGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<FileAttachment>(
      title: "Arquivos",
      fetchEndpoint: ApiLinks.allArquivos,
      createEndpoint: ApiLinks.createArquivo,
      updateEndpoint: ApiLinks.updateArquivo(":id"),
      deleteEndpoint: ApiLinks.deleteArquivo(":id"),
      fromJson: (json) => FileAttachment.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: FileAttachment.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'uploadDate',
      customActions: () => [
        CustomAction<FileAttachment>(
          icon: Icons.payment,
          label: 'Download',
          onPressed: (context, object) => _downloadFile(context, object),
          isVisible: (object) => true,
        ),
      ],
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
      useUserBannerAppBar: true,
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
