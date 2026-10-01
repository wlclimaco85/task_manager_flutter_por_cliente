import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class CanalMensagensScreen extends StatefulWidget {
  final int? parceiroId;
  final String? nomeContato;

  const CanalMensagensScreen({super.key, this.parceiroId, this.nomeContato});

  @override
  State<CanalMensagensScreen> createState() => _CanalMensagensScreenState();
}

class _CanalMensagensScreenState extends State<CanalMensagensScreen> {
  final _scrollCtrl = ScrollController();
  final _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _mensagens = [];
  bool _carregando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final parceiroParam = widget.parceiroId != null ? '?parceiroId=${widget.parceiroId}' : '';
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/mensagens$parceiroParam');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final lista = body is List ? body : (body['data'] ?? body['content'] ?? []);
        setState(() {
          _mensagens = List<Map<String, dynamic>>.from(lista);
          _carregando = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _carregando = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _enviar() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _enviando = true);
    try {
      final url = TenantContext.applyToUrl('${ApiLinks.baseUrl}/api/mensagens');
      final token = AuthUtility.userInfo?.token;
      final payload = <String, dynamic>{
        'texto': texto,
        if (widget.parceiroId != null) 'parceiroId': widget.parceiroId,
        'enviadoPor': AuthUtility.userInfo?.data?.codDadosPessoal?.nome ?? 'Sistema',
      };
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      if (!mounted) return;
      setState(() => _enviando = false);
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        _msgCtrl.clear();
        _carregar();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nomeContato ?? 'Canal de Mensagens'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _mensagens.isEmpty
                    ? const Center(
                        child: Text('Nenhuma mensagem',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(12),
                        itemCount: _mensagens.length,
                        itemBuilder: (_, i) => _buildBalao(_mensagens[i]),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBalao(Map<String, dynamic> msg) {
    final eu = msg['enviadoPor']?.toString() ==
        (AuthUtility.userInfo?.data?.codDadosPessoal?.nome ?? '');
    return Align(
      alignment: eu ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: eu ? GridColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!eu)
              Text(msg['enviadoPor']?.toString() ?? '',
                  style: TextStyle(
                      fontSize: 11,
                      color: GridColors.primary,
                      fontWeight: FontWeight.bold)),
            Text(msg['texto']?.toString() ?? '',
                style: TextStyle(color: eu ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              decoration: InputDecoration(
                hintText: 'Digite uma mensagem...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onSubmitted: (_) => _enviar(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _enviando
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.send, color: GridColors.primary),
            onPressed: _enviando ? null : _enviar,
          ),
        ],
      ),
    );
  }
}
