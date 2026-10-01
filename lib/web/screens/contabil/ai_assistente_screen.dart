import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../services/ai_analise_service.dart';

const _primary = Color(0xFF1A237E);
const _bg = Color(0xFFF5F5F5);
const _botBg = Color(0xFFE8EAF6);
const _userBg = Color(0xFF1A237E);

class WebAiAssistenteScreen extends StatefulWidget {
  const WebAiAssistenteScreen({super.key});
  @override
  State<WebAiAssistenteScreen> createState() => _WebAiAssistenteScreenState();
}

class _WebAiAssistenteScreenState extends State<WebAiAssistenteScreen> {
  final _service = AiAnaliseService();
  final _chatCtrl = TextEditingController();
  final _msgs = <Map<String, String>>[];
  final _scrollCtrl = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _msgs.add({'role': 'bot', 'text': 'Olá! Pergunte sobre dados contábeis: DAS, ICMS, receitas, despesas, obrigações pendentes ou fechamento de período.'});
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _chatCtrl.text.trim();
    if (texto.isEmpty) return;
    final login = AuthUtility.userInfo?.login;
    final empId = int.tryParse(login?.empresa?.id?.toString() ?? '');
    if (empId == null) return;

    setState(() {
      _msgs.add({'role': 'user', 'text': texto});
      _loading = true;
    });
    _chatCtrl.clear();

    try {
      final resp = await _service.perguntar(empId, texto);
      if (mounted) {
        setState(() {
          _msgs.add({'role': 'bot', 'text': resp?['resposta']?.toString() ?? 'Não entendi. Tente perguntar de outra forma.'});
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _msgs.add({'role': 'bot', 'text': 'Erro: $e'});
        _loading = false;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Assistente Contábil IA'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _msgs.length) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
              }
              final msg = _msgs[i];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: isUser ? _userBg : _botBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    msg['text'] ?? '',
                    style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 13),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _chatCtrl,
                decoration: const InputDecoration(
                  hintText: 'Pergunte algo...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                onSubmitted: (_) => _enviar(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _loading ? null : _enviar,
              icon: const Icon(Icons.send, size: 18),
              color: Colors.white,
              style: IconButton.styleFrom(backgroundColor: _primary),
            ),
          ]),
        ),
      ]),
    );
  }
}
