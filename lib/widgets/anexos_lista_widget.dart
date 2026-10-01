// lib/widgets/anexos_lista_widget.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/anexo_financeiro_model.dart';
import '../services/anexo_financeiro_service.dart';
import '../utils/grid_colors.dart';
import '../utils/grid_texts.dart';

/// Reusable widget to display and manage file attachments.
class AnexosListaWidget extends StatefulWidget {
  final int lancamentoId;
  final String lancamentoTipo;
  final String? titulo;

  const AnexosListaWidget({
    super.key,
    required this.lancamentoId,
    required this.lancamentoTipo,
    this.titulo,
  });

  @override
  State<AnexosListaWidget> createState() => _AnexosListaWidgetState();
}

class _AnexosListaWidgetState extends State<AnexosListaWidget> {
  final _service = AnexoFinanceiroService();
  List<AnexoFinanceiro> _anexos = [];
  bool _loading = false;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _error = null; });
    try {
      _anexos = await _service.listar(widget.lancamentoId, widget.lancamentoTipo);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'xml'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: GridColors.error, content: Text('Arquivo muito grande. Máximo: 10MB')),
        );
      }
      return;
    }
    setState(() { _uploading = true; _error = null; });
    try {
      final novo = await _service.upload(widget.lancamentoId, widget.lancamentoTipo, file);
      setState(() { _anexos.add(novo); });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _uploading = false; });
    }
  }

  Future<void> _baixar(AnexoFinanceiro anexo) async {
    if (anexo.id == null) return;
    setState(() { _loading = true; });
    try {
      final bytes = await _service.download(anexo.id!);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${anexo.fileName}');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salvo em ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _remover(AnexoFinanceiro anexo) async {
    if (anexo.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(GridTexts.confirmDelete),
        content: Text('Remover "${anexo.fileName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(GridTexts.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text(GridTexts.remove, style: TextStyle(color: GridColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() { _loading = true; });
    try {
      await _service.remover(anexo.id!);
      setState(() { _anexos.removeWhere((a) => a.id == anexo.id); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, size: 18, color: GridColors.secondary),
            const SizedBox(width: 6),
            Text(widget.titulo ?? GridTexts.attachments, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            if (_uploading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            else
              TextButton.icon(onPressed: _upload, icon: const Icon(Icons.add, size: 18), label: const Text(GridTexts.attach)),
          ],
        ),
        if (_error != null)
          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(_error!, style: const TextStyle(color: GridColors.error, fontSize: 12))),
        if (_loading && !_uploading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
        if (_anexos.isEmpty && !_loading && !_uploading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Nenhum anexo', style: TextStyle(color: GridColors.textMuted, fontSize: 12))),
        ..._anexos.map((a) => _AnexoTile(anexo: a, onDownload: () => _baixar(a), onRemove: () => _remover(a))),
      ],
    );
  }
}

class _AnexoTile extends StatelessWidget {
  final AnexoFinanceiro anexo;
  final VoidCallback onDownload;
  final VoidCallback onRemove;

  const _AnexoTile({required this.anexo, required this.onDownload, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final icon = anexo.isPdf ? Icons.picture_as_pdf : anexo.isImage ? Icons.image : anexo.fileName.toLowerCase().endsWith('.xml') ? Icons.code : Icons.attach_file;
    final iconColor = anexo.isPdf ? Colors.red : anexo.isImage ? Colors.blue : anexo.fileName.toLowerCase().endsWith('.xml') ? Colors.grey : Colors.grey;

    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(anexo.fileName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
      subtitle: anexo.tamanhoBytes != null ? Text(anexo.tamanhoFormatado, style: const TextStyle(fontSize: 11)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.download, size: 18), onPressed: onDownload, tooltip: 'Baixar'),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: GridColors.error), onPressed: onRemove, tooltip: 'Remover'),
        ],
      ),
    );
  }
}
