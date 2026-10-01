import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

/// Análise Inteligente de Dados Contábeis com IA
class AnaliseIaContabilScreen extends StatefulWidget {
  const AnaliseIaContabilScreen({super.key});

  @override
  State<AnaliseIaContabilScreen> createState() => _AnaliseIaContabilScreenState();
}

class _AnaliseIaContabilScreenState extends State<AnaliseIaContabilScreen> {
  final _perguntaCtrl = TextEditingController();
  bool _analisando = false;
  bool _carregando = true;

  Map<String, dynamic>? _resumoFinanceiro;
  String? _respostaIa;
  List<String> _sugestoes = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  @override
  void dispose() {
    _perguntaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarResumo() async {
    setState(() => _carregando = true);
    try {
      final token = AuthUtility.userInfo?.token;
      final headers = {if (token != null) 'Authorization': 'Bearer $token'};
      final results = await Future.wait([
        http.get(Uri.parse(TenantContext.applyToUrl(
            '${ApiLinks.baseUrl}/api/dashboard/obrigacoes')), headers: headers),
        http.get(Uri.parse(TenantContext.applyToUrl(
            '${ApiLinks.baseUrl}/api/ia/sugestoes-contabeis')), headers: headers),
      ]);
      if (!mounted) return;
      if (results[0].statusCode == 200) {
        final b = jsonDecode(results[0].body);
        _resumoFinanceiro = Map<String, dynamic>.from(b['data'] ?? b);
      }
      if (results[1].statusCode == 200) {
        final b = jsonDecode(results[1].body);
        final lista = b['data'] ?? b['sugestoes'] ?? [];
        if (lista is List) _sugestoes = lista.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _carregando = false);
  }

  Future<void> _analisar() async {
    final pergunta = _perguntaCtrl.text.trim();
    if (pergunta.isEmpty) return;
    setState(() { _analisando = true; _respostaIa = null; _erro = null; });
    try {
      final token = AuthUtility.userInfo?.token;
      final url = TenantContext.applyToUrl('${ApiLinks.baseUrl}/api/ia/analise-contabil');
      final resp = await http.post(Uri.parse(url),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'pergunta': pergunta}));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final b = jsonDecode(resp.body);
        setState(() {
          _respostaIa = b['data']?.toString() ?? b['resposta']?.toString() ?? b.toString();
          _analisando = false;
        });
      } else {
        setState(() {
          _erro = 'Erro ${resp.statusCode}: ${resp.body}';
          _analisando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _erro = 'Falha na comunicação: $e'; _analisando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise IA Contábil'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar dados',
            onPressed: _carregarResumo,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (_resumoFinanceiro != null) _buildResumoBar(),
              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_sugestoes.isNotEmpty) ...[
                    _titulo('Sugestões automáticas', Icons.lightbulb_outline),
                    const SizedBox(height: 8),
                    ..._sugestoes.map((s) => _sugestaoCard(s)),
                    const SizedBox(height: 20),
                  ],
                  _titulo('Pergunte à IA', Icons.psychology),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(
                      controller: _perguntaCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Ex: "Qual a situação das contas a pagar este mês?"',
                        border: OutlineInputBorder(),
                      ),
                    )),
                    const SizedBox(width: 8),
                    SizedBox(height: 56, child: ElevatedButton(
                      onPressed: _analisando ? null : _analisar,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: GridColors.primary, foregroundColor: Colors.white),
                      child: _analisando
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                    )),
                  ]),
                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200)),
                      child: Text(_erro!, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                  if (_respostaIa != null) ...[
                    const SizedBox(height: 16),
                    _titulo('Resposta da IA', Icons.smart_toy),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GridColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GridColors.primary.withOpacity(0.2)),
                      ),
                      child: SelectableText(_respostaIa!,
                          style: const TextStyle(height: 1.5, fontSize: 14)),
                    ),
                  ],
                ]),
              )),
            ]),
    );
  }

  Widget _buildResumoBar() {
    final r = _resumoFinanceiro!;
    return Container(
      color: GridColors.primary.withOpacity(0.07),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _metricaChip('Vencidas', '${r['vencidas'] ?? 0}', Colors.red),
        _metricaChip('Hoje', '${r['vencendoHoje'] ?? 0}', Colors.orange),
        _metricaChip('7 dias', '${r['proximos7dias'] ?? 0}', Colors.amber),
        _metricaChip('30 dias', '${r['proximos30dias'] ?? 0}', Colors.green),
      ]),
    );
  }

  Widget _metricaChip(String label, String valor, Color cor) => Column(children: [
    Text(valor, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cor)),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ]);

  Widget _titulo(String texto, IconData icone) => Row(children: [
    Icon(icone, color: GridColors.primary, size: 18),
    const SizedBox(width: 6),
    Text(texto, style: TextStyle(fontWeight: FontWeight.bold, color: GridColors.primary, fontSize: 14)),
  ]);

  Widget _sugestaoCard(String texto) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      dense: true,
      leading: const Icon(Icons.tips_and_updates, color: Colors.amber, size: 20),
      title: Text(texto, style: const TextStyle(fontSize: 13)),
      onTap: () {
        _perguntaCtrl.text = texto;
        _analisar();
      },
    ),
  );
}
