import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/ged_file_type.dart';

/// Card de arquivo GED mobile com botões Baixar e Renomear
/// Suporta layout responsivo (portrait/landscape)
class GedFileCardMobile extends StatefulWidget {
  /// Dados do arquivo (id, fileName, fileType, diretorioNome, parceiroNome, uploadDate)
  final Map<String, dynamic> arq;

  /// Permissão para excluir arquivo
  final bool podeExcluir;

  /// Callback disparado ao clicar botão Baixar
  final VoidCallback onDownload;

  /// Callback disparado ao clicar Excluir
  final VoidCallback onDelete;

  /// Callback para renomear arquivo (retorna true se sucesso)
  final Future<bool> Function(String novoNome) onRename;

  /// Callback opcional para classificar com IA
  final VoidCallback? onClassify;

  const GedFileCardMobile({
    super.key,
    required this.arq,
    required this.podeExcluir,
    required this.onDownload,
    required this.onDelete,
    required this.onRename,
    this.onClassify,
  });

  @override
  State<GedFileCardMobile> createState() => _GedFileCardMobileState();
}

class _GedFileCardMobileState extends State<GedFileCardMobile> {
  bool _editando = false;
  late TextEditingController _nomeCtrl;

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

  /// Extrai nome do arquivo dos dados
  String get _fileName => widget.arq['fileName']?.toString() ?? '—';

  /// Confirma renomeação e chama callback
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

  /// Cancela renomeação sem salvar
  void _cancelarRenomear() {
    setState(() {
      _editando = false;
      _nomeCtrl.text = _fileName;
    });
  }

  /// Formata data para string dd/MM/yyyy
  String _formatarData(String raw) {
    try {
      final fmt = DateFormat('dd/MM/yyyy');
      return fmt.format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.arq['fileType']?.toString() ?? '';
    final corTipo = corParaTipoArquivo(tipo);
    final icone = iconeParaTipoArquivo(tipo);
    final diretorioNome = widget.arq['diretorioNome']?.toString();
    final parceiroNome = widget.arq['parceiroNome']?.toString();
    final uploadDate = widget.arq['uploadDate']?.toString();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: ícone + nome + ações
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icone, size: 24, color: corTipo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _editando
                        ? TextField(
                            controller: _nomeCtrl,
                            autofocus: true,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(8),
                            ),
                          )
                        : Text(
                            _fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                  if (!_editando)
                    Flexible(
                      fit: FlexFit.loose,
                      child: _buildAcoes(),
                    ),
                ],
              ),
              if (_editando) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      iconSize: 20,
                      onPressed: _confirmarRenomear,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      tooltip: 'Salvar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      iconSize: 20,
                      onPressed: _cancelarRenomear,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      tooltip: 'Cancelar',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),

              // Metadados
              if (diretorioNome != null && diretorioNome.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          diretorioNome,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (parceiroNome != null && parceiroNome.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          parceiroNome,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (uploadDate != null)
                Text(
                  _formatarData(uploadDate),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói row com botões de ação
  Widget _buildAcoes() {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão Baixar
          IconButton(
            icon: const Icon(Icons.download, color: Colors.blue, size: 18),
            tooltip: 'Baixar',
            onPressed: widget.onDownload,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
          // Menu com Renomear, Excluir, Classificar
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            tooltip: 'Mais ações',
            onSelected: (acao) {
              if (acao == 'renomear') {
                setState(() => _editando = true);
              } else if (acao == 'excluir') {
                widget.onDelete();
              } else if (acao == 'classificar') {
                widget.onClassify?.call();
              }
            },
            itemBuilder: (context) => [
              // Excluir (apenas se podeExcluir)
              if (widget.podeExcluir)
                const PopupMenuItem<String>(
                  value: 'excluir',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Excluir'),
                    dense: true,
                  ),
                ),
              // Renomear
              const PopupMenuItem<String>(
                value: 'renomear',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Renomear'),
                  dense: true,
                ),
              ),
              // Classificar com IA (opcional)
              if (widget.onClassify != null)
                const PopupMenuItem<String>(
                  value: 'classificar',
                  child: ListTile(
                    leading: Icon(Icons.auto_awesome),
                    title: Text('Classificar com IA'),
                    dense: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
