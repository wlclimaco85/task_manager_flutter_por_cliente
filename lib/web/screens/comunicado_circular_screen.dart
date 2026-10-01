import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class ComunicadoCircularScreen extends StatefulWidget {
  const ComunicadoCircularScreen({super.key});

  @override
  State<ComunicadoCircularScreen> createState() =>
      _ComunicadoCircularScreenState();
}

class _ComunicadoCircularScreenState extends State<ComunicadoCircularScreen> {
  bool _carregando = true;
  List<Map<String, dynamic>> _comunicados = [];
  List<Map<String, dynamic>> _empresas = [];
  final Set<int> _selecionadas = {};
  int? _comunicadoSelecionadoId;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final token = AuthUtility.userInfo?.token;
    final headers = {if (token != null) 'Authorization': 'Bearer $token'};
    try {
      final urls = await Future.wait([
        http.get(Uri.parse(TenantContext.applyToUrl(
            '${ApiLinks.baseUrl}/api/comunicado?pagina=0&tamanho=50')), headers: headers),
        http.get(Uri.parse(TenantContext.applyToUrl(
            '${ApiLinks.baseUrl}/api/empresa?pagina=0&tamanho=200')), headers: headers),
      ]);
      if (!mounted) return;
      final bodyComun = jsonDecode(urls[0].body);
      final bodyEmp = jsonDecode(urls[1].body);
      setState(() {
        _comunicados = List<Map<String, dynamic>>.from(
            bodyComun['data']?['content'] ?? bodyComun['data'] ?? []);
        _empresas = List<Map<String, dynamic>>.from(
            bodyEmp['data']?['content'] ?? bodyEmp['data'] ?? []);
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _enviarCircular() async {
    if (_comunicadoSelecionadoId == null || _selecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um comunicado e ao menos uma empresa')));
      return;
    }
    setState(() => _enviando = true);
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/comunicado/$_comunicadoSelecionadoId/circular');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'empresaIds': _selecionadas.toList()}),
      );
      if (!mounted) return;
      setState(() => _enviando = false);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final qtd = body['data']?['destinatariosAdicionados'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Comunicado enviado para $qtd empresa(s)!')));
        setState(() {
          _selecionadas.clear();
          _comunicadoSelecionadoId = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro HTTP ${resp.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicado Circular'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Selecione o comunicado',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: GridColors.primary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _comunicadoSelecionadoId,
                    hint: const Text('Selecionar comunicado...'),
                    items: _comunicados.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'] as int?,
                        child: Text(c['titulo']?.toString() ?? 'Sem título',
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _comunicadoSelecionadoId = v),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('2. Selecione as empresas (${_selecionadas.length} marcadas)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: GridColors.primary)),
                      TextButton(
                        onPressed: () => setState(() {
                          if (_selecionadas.length == _empresas.length) {
                            _selecionadas.clear();
                          } else {
                            _selecionadas.addAll(
                                _empresas.map((e) => e['id'] as int? ?? 0));
                          }
                        }),
                        child: Text(_selecionadas.length == _empresas.length
                            ? 'Desmarcar todas'
                            : 'Marcar todas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _empresas.length,
                      itemBuilder: (_, i) {
                        final emp = _empresas[i];
                        final id = emp['id'] as int? ?? 0;
                        return CheckboxListTile(
                          dense: true,
                          title: Text(emp['nome']?.toString() ?? ''),
                          subtitle: Text(emp['cnpj']?.toString() ?? '',
                              style: const TextStyle(fontSize: 11)),
                          value: _selecionadas.contains(id),
                          onChanged: (v) => setState(() {
                            v == true
                                ? _selecionadas.add(id)
                                : _selecionadas.remove(id);
                          }),
                          activeColor: GridColors.primary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(_enviando ? 'Enviando...' : 'Enviar Circular'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: GridColors.primary,
                          foregroundColor: Colors.white),
                      onPressed: _enviando ? null : _enviarCircular,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
