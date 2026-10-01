import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class PainelClientesScreen extends StatefulWidget {
  const PainelClientesScreen({super.key});

  @override
  State<PainelClientesScreen> createState() => _PainelClientesScreenState();
}

class _PainelClientesScreenState extends State<PainelClientesScreen> {
  bool _carregando = true;
  List<Map<String, dynamic>> _clientes = [];
  String _busca = '';
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/dashboard/painel-clientes');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final lista = body['data'] ?? body['content'] ?? [];
        setState(() {
          _clientes = List<Map<String, dynamic>>.from(lista);
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = 'Erro HTTP ${resp.statusCode}';
          _carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro: $e';
        _carregando = false;
      });
    }
  }

  List<Map<String, dynamic>> get _clientesFiltrados {
    if (_busca.isEmpty) return _clientes;
    final q = _busca.toLowerCase();
    return _clientes
        .where((c) =>
            (c['nome']?.toString().toLowerCase().contains(q) ?? false) ||
            (c['cnpj']?.toString().toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Clientes'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _carregando = true;
                _erro = null;
              });
              _carregar();
            },
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar cliente...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onChanged: (v) => setState(() => _busca = v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text('${_clientesFiltrados.length} clientes',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: _clientesFiltrados.isEmpty
                          ? const Center(
                              child: Text('Nenhum cliente encontrado',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _clientesFiltrados.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (_, i) =>
                                  _buildCardCliente(_clientesFiltrados[i]),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCardCliente(Map<String, dynamic> c) {
    final nome = c['nome']?.toString() ?? 'Sem nome';
    final cnpj = c['cnpj']?.toString() ?? '';
    final obrigacoesPendentes = c['obrigacoesPendentes'] ?? 0;
    final mensagensNaoLidas = c['mensagensNaoLidas'] ?? 0;
    final cor = obrigacoesPendentes > 0 ? Colors.orange : Colors.green;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: GridColors.primary.withOpacity(0.12),
              child: Text(
                nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                style: TextStyle(
                    color: GridColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (cnpj.isNotEmpty)
                    Text(cnpj,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Column(
              children: [
                if (obrigacoesPendentes > 0)
                  _badge('$obrigacoesPendentes guias', cor),
                if (mensagensNaoLidas > 0)
                  _badge('$mensagensNaoLidas msg', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String texto, Color cor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.4)),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
    );
  }
}
