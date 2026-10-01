import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/ged_file_type.dart';

SliverGridDelegateWithFixedCrossAxisCount gedFileGridDelegate(
  double availableWidth,
) {
  final columns = availableWidth < 520
      ? 1
      : availableWidth < 860
          ? 2
          : availableWidth < 1200
              ? 3
              : 4;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    mainAxisExtent: 210,
  );
}

/// Card de arquivo do GED (versão web), com ações de download, exclusão,
/// renomear inline e classificação via IA.
class GedFileCard extends StatefulWidget {
  final Map<String, dynamic> arq;
  final bool podeExcluir;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final Future<bool> Function(String novoNome) onRename;
  final VoidCallback onClassify;

  const GedFileCard({
    super.key,
    required this.arq,
    required this.podeExcluir,
    required this.onDownload,
    required this.onDelete,
    required this.onRename,
    required this.onClassify,
  });

  @override
  State<GedFileCard> createState() => _GedFileCardState();
}

class _GedFileCardState extends State<GedFileCard> {
  bool _editando = false;
  late final TextEditingController _nomeCtrl;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: _fileName);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  String get _fileName => widget.arq['fileName']?.toString() ?? '—';

  Future<void> _confirmarRenomear() async {
    final novoNome = _nomeCtrl.text.trim();
    if (novoNome.isEmpty || novoNome == _fileName) {
      setState(() => _editando = false);
      return;
    }
    final ok = await widget.onRename(novoNome);
    if (!mounted) return;
    if (ok) {
      setState(() => _editando = false);
    }
  }

  void _cancelarRenomear() {
    setState(() {
      _editando = false;
      _nomeCtrl.text = _fileName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.arq['fileType']?.toString() ?? '';
    final corTipo = corParaTipoArquivo(tipo);
    final icone = iconeParaTipoArquivo(tipo);
    final diretorioNome = widget.arq['diretorioNome']?.toString();
    final parceiroNome = widget.arq['parceiroNome']?.toString();
    final uploadDate = widget.arq['uploadDate']?.toString();

    return Container(
      key: ValueKey(widget.arq['id']),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: corTipo, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: corTipo.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ícone tipo + chip tipo
          Row(
            children: [
              Icon(icone, size: 32, color: corTipo),
              const Spacer(),
              _chipTipo(tipo, corTipo),
            ],
          ),
          const SizedBox(height: 8),

          // Nome do arquivo (texto ou edição inline)
          _editando
              ? TextField(
                  controller: _nomeCtrl,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                )
              : Text(
                  _fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
          const SizedBox(height: 4),

          // Diretório
          if (diretorioNome != null && diretorioNome.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.folder, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    diretorioNome,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          // Parceiro
          if (parceiroNome != null && parceiroNome.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.person, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    parceiroNome,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 4),

          // Data
          if (uploadDate != null)
            Text(
              _formatarData(uploadDate),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),

          const Spacer(),

          // Botões de ação
          _buildAcoes(),
        ],
      ),
    );
  }

  Widget _buildAcoes() {
    if (_editando) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green, size: 20),
            tooltip: 'Salvar',
            onPressed: _confirmarRenomear,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            tooltip: 'Cancelar',
            onPressed: _cancelarRenomear,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.download, color: Colors.blue, size: 20),
          tooltip: 'Download',
          onPressed: widget.onDownload,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
        ),
        if (widget.podeExcluir)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            tooltip: 'Excluir',
            onPressed: widget.onDelete,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          tooltip: 'Mais ações',
          onSelected: (acao) {
            if (acao == 'renomear') {
              setState(() => _editando = true);
            } else if (acao == 'classificar') {
              widget.onClassify();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'renomear',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Renomear'),
              ),
            ),
            PopupMenuItem(
              value: 'classificar',
              child: ListTile(
                leading: Icon(Icons.auto_awesome),
                title: Text('Classificar com IA'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chipTipo(String tipo, Color cor) {
    final ext = tipo.contains('/')
        ? tipo.split('/').last.toUpperCase()
        : tipo.toUpperCase();
    final label = ext.length > 8 ? ext.substring(0, 8) : ext;

    return Chip(
      label: Text(label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          )),
      backgroundColor: cor,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatarData(String raw) {
    try {
      final fmt = DateFormat('dd/MM/yyyy');
      return fmt.format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}
