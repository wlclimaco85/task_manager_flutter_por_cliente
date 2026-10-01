// lib/web/dialogs/anexo_upload_dialog.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/anexo_financeiro_model.dart';
import '../../services/anexo_financeiro_service.dart';
import '../../utils/grid_colors.dart';

const int _maxFileSize = 10 * 1024 * 1024; // 10MB
const List<String> _allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'xml'];

/// Dialog for uploading attachments to lancamentos financeiros.
class AnexoUploadDialog extends StatefulWidget {
  final int lancamentoId;
  final String lancamentoTipo;

  const AnexoUploadDialog({
    super.key,
    required this.lancamentoId,
    required this.lancamentoTipo,
  });

  @override
  State<AnexoUploadDialog> createState() => _AnexoUploadDialogState();
}

class _AnexoUploadDialogState extends State<AnexoUploadDialog> {
  final _service = AnexoFinanceiroService();
  List<AnexoFinanceiro> _anexos = [];
  bool _loading = false;
  bool _uploading = false;
  String? _error;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadAnexos();
  }

  Future<void> _loadAnexos() async {
    setState(() { _loading = true; _error = null; });
    try {
      _anexos = await _service.listar(widget.lancamentoId, widget.lancamentoTipo);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > _maxFileSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: GridColors.error, content: Text('Arquivo muito grande (${(file.size / (1024 * 1024)).toStringAsFixed(1)}MB). Máximo: 10MB')),
        );
      }
      return;
    }
    final ext = file.name.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: GridColors.error, content: Text('Tipo de arquivo não suportado: .$ext')),
        );
      }
      return;
    }
    setState(() { _uploading = true; _uploadProgress = 0; _error = null; });
    try {
      for (double p = 0; p <= 0.8; p += 0.2) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _uploadProgress = p);
      }
      final novo = await _service.upload(widget.lancamentoId, widget.lancamentoTipo, file);
      if (mounted) {
        setState(() { _anexos.add(novo); _uploadProgress = 1.0; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: GridColors.success, content: Text('Arquivo enviado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: GridColors.error, content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() { _uploading = false; _uploadProgress = 0; });
    }
  }

  Future<void> _download(AnexoFinanceiro anexo) async {
    if (anexo.id == null) return;
    setState(() => _loading = true);
    try {
      final bytes = await _service.download(anexo.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download concluído: ${anexo.fileName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: GridColors.error, content: Text('Erro ao baixar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(AnexoFinanceiro anexo) async {
    if (anexo.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Remover o anexo "${anexo.fileName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover', style: TextStyle(color: GridColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      await _service.remover(anexo.id!);
      setState(() => _anexos.removeWhere((a) => a.id == anexo.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: GridColors.success, content: Text('Anexo removido com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: GridColors.error, content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _iconForFile(AnexoFinanceiro anexo) {
    if (anexo.isPdf) return Icons.picture_as_pdf;
    if (anexo.isImage) return Icons.image;
    if (anexo.fileName.toLowerCase().endsWith('.xml')) return Icons.code;
    return Icons.attach_file;
  }

  Color _colorForFile(AnexoFinanceiro anexo) {
    if (anexo.isPdf) return Colors.red;
    if (anexo.isImage) return Colors.blue;
    if (anexo.fileName.toLowerCase().endsWith('.xml')) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_file, color: GridColors.secondary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Anexos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: GridColors.textSecondary)),
                        Text('${widget.lancamentoTipo} #${widget.lancamentoId}', style: const TextStyle(fontSize: 12, color: GridColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: GridColors.divider),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload, size: 18),
                  label: Text(_uploading ? 'Enviando... ${(_uploadProgress * 100).toInt()}%' : 'Selecionar e Enviar Arquivo'),
                  style: OutlinedButton.styleFrom(foregroundColor: GridColors.secondary, padding: const EdgeInsets.all(14), side: const BorderSide(color: GridColors.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ),
              if (_uploading) ...[const SizedBox(height: 8), LinearProgressIndicator(value: _uploadProgress, backgroundColor: GridColors.divider, color: GridColors.secondary)],
              const SizedBox(height: 4),
              const Text('Formatos aceitos: PDF, JPG, PNG, XML — Máximo: 10MB', style: TextStyle(fontSize: 11, color: GridColors.textMuted)),
              const SizedBox(height: 12),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: GridColors.errorLight, borderRadius: BorderRadius.circular(6)),
                  child: Text(_error!, style: const TextStyle(color: GridColors.error, fontSize: 12)),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _anexos.isEmpty
                        ? const Center(child: Text('Nenhum anexo encontrado', style: TextStyle(color: GridColors.textMuted)))
                        : ListView.separated(
                            itemCount: _anexos.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final anexo = _anexos[i];
                              return ListTile(
                                dense: true,
                                leading: Icon(_iconForFile(anexo), color: _colorForFile(anexo), size: 24),
                                title: Text(anexo.fileName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                subtitle: anexo.tamanhoBytes != null ? Text(anexo.tamanhoFormatado, style: const TextStyle(fontSize: 11)) : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.download, size: 18), onPressed: () => _download(anexo), tooltip: 'Baixar'),
                                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: GridColors.error), onPressed: () => _delete(anexo), tooltip: 'Remover'),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: GridColors.primary, foregroundColor: Colors.white),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
