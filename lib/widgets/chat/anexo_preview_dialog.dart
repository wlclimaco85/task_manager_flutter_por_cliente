import 'package:flutter/material.dart';

import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

/// Card #454: popup de pre-visualizacao de anexo do chat, aberto ao clicar
/// no link do arquivo (antes so baixava direto). Design: ui-ux-pro-max.
/// Imagens usam InteractiveViewer nativo (zoom/pan), sem pacote extra.
/// PDF e outros tipos ficam em fallback (icone+nome+baixar) -- nao ha
/// visualizador de PDF multiplataforma instalado no projeto; decisao
/// tecnica de adicionar um pacote fica para card separado (architect).
const _extensoesImagem = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

String _extensaoDe(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return '';
  return fileName.substring(dot + 1).toLowerCase();
}

(IconData, Color) _iconeECorPorExtensao(String extensao) {
  switch (extensao) {
    case 'pdf':
      return (Icons.picture_as_pdf, GridColors.fileTypePdf);
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'webp':
    case 'gif':
      return (Icons.image, GridColors.fileTypeImage);
    case 'xlsx':
    case 'xls':
    case 'csv':
      return (Icons.table_chart, GridColors.fileTypeSheet);
    case 'docx':
    case 'doc':
      return (Icons.description, GridColors.fileTypeWord);
    default:
      return (Icons.insert_drive_file, GridColors.fileTypeDefault);
  }
}

Future<void> showAnexoPreviewDialog(
  BuildContext context, {
  required int fileId,
  required String fileName,
  required Future<void> Function() onBaixar,
}) async {
  final isMobile = MediaQuery.of(context).size.width < 700;
  if (isMobile) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.95,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: _AnexoPreviewContent(
            fileId: fileId,
            fileName: fileName,
            onBaixar: onBaixar,
          ),
        ),
      ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: _AnexoPreviewContent(
          fileId: fileId,
          fileName: fileName,
          onBaixar: onBaixar,
        ),
      ),
    ),
  );
}

class _AnexoPreviewContent extends StatefulWidget {
  final int fileId;
  final String fileName;
  final Future<void> Function() onBaixar;

  const _AnexoPreviewContent({
    required this.fileId,
    required this.fileName,
    required this.onBaixar,
  });

  @override
  State<_AnexoPreviewContent> createState() => _AnexoPreviewContentState();
}

class _AnexoPreviewContentState extends State<_AnexoPreviewContent> {
  bool _baixando = false;
  bool _erroImagem = false;

  Future<void> _baixar() async {
    setState(() => _baixando = true);
    try {
      await widget.onBaixar();
    } finally {
      if (mounted) setState(() => _baixando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final extensao = _extensaoDe(widget.fileName);
    final (icone, cor) = _iconeECorPorExtensao(extensao);
    final ehImagem = _extensoesImagem.contains(extensao);

    return Container(
      color: GridColors.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: GridColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icone, color: cor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        extensao.isEmpty ? 'Arquivo' : extensao.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12, color: GridColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: GridColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Conteudo
          Expanded(
            child: Container(
              color: GridColors.background,
              alignment: Alignment.center,
              child: ehImagem && !_erroImagem
                  ? InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.network(
                        TenantContext.applyToUrl(
                            ApiLinks.downloadArquivo(widget.fileId.toString())),
                        headers: TenantContext.headers,
                        fit: BoxFit.contain,
                        loadingBuilder: (ctx, child, progress) =>
                            progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                        color: GridColors.primary),
                                  ),
                        errorBuilder: (ctx, err, stack) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _erroImagem = true);
                          });
                          return const SizedBox.shrink();
                        },
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icone, size: 72, color: cor),
                          const SizedBox(height: 16),
                          const Text(
                            'Pré-visualização não disponível para este arquivo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: GridColors.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Baixe o arquivo para visualizar',
                            style: TextStyle(
                                color: GridColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: GridColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close,
                        size: 18, color: GridColors.textMuted),
                    label: const Text('Fechar',
                        style: TextStyle(color: GridColors.textMuted)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: GridColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _baixando ? null : _baixar,
                    icon: _baixando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download,
                            size: 18, color: Colors.white),
                    label: Text(_baixando ? 'Baixando...' : 'Baixar arquivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
