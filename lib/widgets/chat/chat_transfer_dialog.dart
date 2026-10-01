import 'package:flutter/material.dart';
import '../../services/chat_caller.dart';
import '../../utils/grid_colors.dart';

class ChatTransferDialog extends StatefulWidget {
  final String chatId;
  final String? sector;

  const ChatTransferDialog({
    super.key,
    required this.chatId,
    this.sector,
  });

  @override
  State<ChatTransferDialog> createState() => _ChatTransferDialogState();
}

class _ChatTransferDialogState extends State<ChatTransferDialog> {
  final ChatCaller _caller = ChatCaller();
  List<Map<String, String>> _usuarios = [];
  bool _loading = true;
  bool _transferindo = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final usuarios = await _caller.fetchUsuariosSetor(widget.sector ?? '');
    if (mounted) setState(() { _usuarios = usuarios; _loading = false; });
  }

  Future<void> _transferir(String usuarioId, String nome) async {
    setState(() => _transferindo = true);
    final ok = await _caller.transferChat(widget.chatId, usuarioId);
    if (!mounted) return;
    setState(() => _transferindo = false);
    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat transferido para $nome')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao transferir chat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transferir Chat'),
      content: SizedBox(
        width: 320,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _usuarios.isEmpty
                ? const Text('Nenhum usuario disponivel para transferencia.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _usuarios.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final u = _usuarios[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: GridColors.secondary.withValues(alpha: 0.12),
                          child: Text(
                            (u['nome']?.isNotEmpty == true ? u['nome']! : '?')[0].toUpperCase(),
                            style: const TextStyle(
                              color: GridColors.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(u['nome'] ?? 'Usuario'),
                        trailing: _transferindo
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: _transferindo
                            ? null
                            : () => _transferir(u['id'] ?? '', u['nome'] ?? ''),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _transferindo ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
