import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class PdfPreviewDialog extends StatefulWidget {
  final Uint8List bytes;

  const PdfPreviewDialog({
    super.key,
    required this.bytes,
  });

  @override
  State<PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<PdfPreviewDialog> {
  String? _tempPath;

  @override
  void initState() {
    super.initState();
    _saveTempFile();
  }

  Future<void> _saveTempFile() async {
    if (kIsWeb) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(widget.bytes);
      if (mounted) {
        setState(() => _tempPath = file.path);
      }
    } catch (_) {}
  }

  Future<void> _openExternally() async {
    if (_tempPath == null) return;
    final uri = Uri.file(_tempPath!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Visualizar PDF'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _tempPath == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Visualização de PDF não disponível nesta plataforma.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir externamente'),
                    onPressed: _openExternally,
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
