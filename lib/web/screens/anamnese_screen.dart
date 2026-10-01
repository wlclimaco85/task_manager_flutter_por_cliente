import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

/// Tela de Anamnese Digital — formulário de histórico de saúde do aluno.
/// Persiste em /api/anamnese (JSONB no backend via tabela simples).
class AnamneseScreen extends StatefulWidget {
  final int alunoId;
  final String? nomeAluno;

  const AnamneseScreen({super.key, required this.alunoId, this.nomeAluno});

  @override
  State<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends State<AnamneseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _carregando = true;
  bool _salvando = false;
  int? _anamneseId;

  // ── Campos da anamnese ───────────────────────────────────────────────────────
  final _objetivoCtrl = TextEditingController();
  final _doencasCtrl = TextEditingController();
  final _medicamentosCtrl = TextEditingController();
  final _cirurgiasCtrl = TextEditingController();
  final _lesaoCtrl = TextEditingController();
  final _atividadesCtrl = TextEditingController();
  final _alimentacaoCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  bool _fumante = false;
  bool _alcool = false;
  bool _sedentario = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    for (final c in [
      _objetivoCtrl, _doencasCtrl, _medicamentosCtrl, _cirurgiasCtrl,
      _lesaoCtrl, _atividadesCtrl, _alimentacaoCtrl, _observacoesCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/anamnese?alunoId=${widget.alunoId}');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final data = body['data'] ?? body;
        if (data is Map && data['id'] != null) {
          _anamneseId = data['id'];
          _objetivoCtrl.text = data['objetivo'] ?? '';
          _doencasCtrl.text = data['doencas'] ?? '';
          _medicamentosCtrl.text = data['medicamentos'] ?? '';
          _cirurgiasCtrl.text = data['cirurgias'] ?? '';
          _lesaoCtrl.text = data['lesao'] ?? '';
          _atividadesCtrl.text = data['atividades'] ?? '';
          _alimentacaoCtrl.text = data['alimentacao'] ?? '';
          _observacoesCtrl.text = data['observacoes'] ?? '';
          _fumante = data['fumante'] == true;
          _alcool = data['alcool'] == true;
          _sedentario = data['sedentario'] == true;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _carregando = false);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final payload = {
        'alunoId': widget.alunoId,
        'objetivo': _objetivoCtrl.text.trim(),
        'doencas': _doencasCtrl.text.trim(),
        'medicamentos': _medicamentosCtrl.text.trim(),
        'cirurgias': _cirurgiasCtrl.text.trim(),
        'lesao': _lesaoCtrl.text.trim(),
        'atividades': _atividadesCtrl.text.trim(),
        'alimentacao': _alimentacaoCtrl.text.trim(),
        'observacoes': _observacoesCtrl.text.trim(),
        'fumante': _fumante,
        'alcool': _alcool,
        'sedentario': _sedentario,
      };
      final token = AuthUtility.userInfo?.token;
      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final http.Response resp;
      if (_anamneseId != null) {
        resp = await http.put(
          Uri.parse(TenantContext.applyToUrl(
              '${ApiLinks.baseUrl}/api/anamnese/$_anamneseId')),
          headers: headers,
          body: jsonEncode(payload),
        );
      } else {
        resp = await http.post(
          Uri.parse(TenantContext.applyToUrl('${ApiLinks.baseUrl}/api/anamnese')),
          headers: headers,
          body: jsonEncode(payload),
        );
      }
      if (!mounted) return;
      setState(() => _salvando = false);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (resp.statusCode == 201) {
          final body = jsonDecode(resp.body);
          _anamneseId = body['data']?['id'] ?? _anamneseId;
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Anamnese salva com sucesso!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar (${resp.statusCode})')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anamnese — ${widget.nomeAluno ?? 'Aluno'}'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            icon: _salvando
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Salvar', style: TextStyle(color: Colors.white)),
            onPressed: _salvando ? null : _salvar,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _secao('Objetivo e Histórico Geral'),
                    _campo('Objetivo do treino', _objetivoCtrl, maxLines: 2),
                    _campo('Doenças/condições pré-existentes', _doencasCtrl, maxLines: 2),
                    _campo('Medicamentos em uso', _medicamentosCtrl, maxLines: 2),
                    _campo('Cirurgias realizadas', _cirurgiasCtrl, maxLines: 2),
                    _campo('Lesões ou restrições físicas', _lesaoCtrl, maxLines: 2),
                    const SizedBox(height: 16),
                    _secao('Hábitos de Vida'),
                    _campo('Atividades físicas anteriores', _atividadesCtrl, maxLines: 2),
                    _campo('Alimentação (descreva brevemente)', _alimentacaoCtrl, maxLines: 2),
                    const SizedBox(height: 8),
                    _toggle('Fumante', _fumante, (v) => setState(() => _fumante = v)),
                    _toggle('Consome álcool regularmente', _alcool, (v) => setState(() => _alcool = v)),
                    _toggle('Sedentário antes da academia', _sedentario,
                        (v) => setState(() => _sedentario = v)),
                    const SizedBox(height: 16),
                    _secao('Observações do Avaliador'),
                    _campo('Observações', _observacoesCtrl, maxLines: 3),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _secao(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(titulo,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: GridColors.primary)),
      );

  Widget _campo(String label, TextEditingController ctrl, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      );

  Widget _toggle(String label, bool valor, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        dense: true,
        title: Text(label),
        value: valor,
        activeColor: GridColors.primary,
        onChanged: onChanged,
      );
}
