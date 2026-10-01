// lib/screens/contabil/mensagens_screen.dart
import 'package:flutter/material.dart';

class MensagensScreen extends StatefulWidget {
  const MensagensScreen({Key? key}) : super(key: key);

  @override
  State<MensagensScreen> createState() => _MensagensScreenState();
}

class _MensagensScreenState extends State<MensagensScreen> {
  final TextEditingController _textoController = TextEditingController();
  final List<Map<String, String>> _mensagens = [
    {'autor': 'Sistema', 'texto': 'Bem-vindo ao chat'},
    {'autor': 'Suporte', 'texto': 'Como podemos ajudar?'},
    {'autor': 'Você', 'texto': 'Gostaria de informações sobre impostos'},
  ];

  void _enviarMensagem() {
    if (_textoController.text.isNotEmpty) {
      setState(() {
        _mensagens.add({
          'autor': 'Você',
          'texto': _textoController.text,
        });
        _textoController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Mensagens',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Container(
            height: 300,
            child: ListView.builder(
              itemCount: _mensagens.length,
              itemBuilder: (context, index) {
                final msg = _mensagens[index];
                final isUsuario = msg['autor'] == 'Você';
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    alignment:
                        isUsuario ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isUsuario
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(msg['autor']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(msg['texto']!,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _textoController,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _enviarMensagem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }
}
