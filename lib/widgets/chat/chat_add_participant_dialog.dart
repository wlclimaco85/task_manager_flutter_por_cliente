import 'package:flutter/material.dart';
import '../../services/chat_caller.dart';
import '../../utils/grid_colors.dart';

/// Card #474 (Fase 3 fila de atendimento): inclui um participante adicional
/// numa conversa de chat já em andamento. Mesmo padrão visual do
/// ChatTransferDialog (card #448 Fase 2) -- lista usuários do setor,
/// seleciona um, chama o backend.
class ChatAddParticipantDialog extends StatefulWidget {
  final String chatId;

  const ChatAddParticipantDialog({super.key, required this.chatId});

  @override
  State<ChatAddParticipantDialog> createState() =>
      _ChatAddParticipantDialogState();
}

class _ChatAddParticipantDialogState extends State<ChatAddParticipantDialog> {
  final ChatCaller _caller = ChatCaller();
  List<Map<String, String>> _usuarios = [];
  bool _loading = true;
  bool _incluindo = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final usuarios = await _caller.fetchUsuariosSetor('');
    if (mounted) setState(() { _usuarios = usuarios; _loading = false; });
  }

  Future<void> _incluir(String usuarioId, String nome) async {
    setState(() => _incluindo = true);
    final ok = await _caller.incluirParticipante(widget.chatId, usuarioId);
    if (!mounted) return;
    setState(() => _incluindo = false);
    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nome incluído na conversa')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao incluir participante')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Incluir Participante'),
      content: SizedBox(
        width: 320,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _usuarios.isEmpty
                ? const Text('Nenhum usuario disponivel para incluir.')
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
                        trailing: _incluindo
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add_alt, size: 18),
                        onTap: _incluindo
                            ? null
                            : () => _incluir(u['id'] ?? '', u['nome'] ?? ''),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _incluindo ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
