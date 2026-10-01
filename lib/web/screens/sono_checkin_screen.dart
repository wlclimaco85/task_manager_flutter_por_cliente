import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

/// Tela de Sono + Check-in Diário (V003 Fase 4)
class SonoCheckinScreen extends StatefulWidget {
  final int? alunoId;
  const SonoCheckinScreen({super.key, this.alunoId});

  @override
  State<SonoCheckinScreen> createState() => _SonoCheckinScreenState();
}

class _SonoCheckinScreenState extends State<SonoCheckinScreen> {
  bool _carregando = true;
  bool _salvando = false;
  DateTime _dataSelecionada = DateTime.now();

  // Sono
  final _horasSonoCtrl = TextEditingController();
  double _qualidadeSono = 3; // 1-5

  // Humor e energia
  double _humor = 3;
  double _energia = 3;

  // Hábitos do dia
  bool _bebeuAgua = false;
  bool _fezTreino = false;
  bool _comeuBem = false;
  bool _meditou = false;

  // Observações
  final _obsCtrl = TextEditingController();

  int? _registroId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _horasSonoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  String get _dataStr {
    final d = _dataSelecionada;
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final alunoId = widget.alunoId ?? AuthUtility.userInfo?.data?.id;
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/checkin-diario?data=$_dataStr${alunoId != null ? '&alunoId=$alunoId' : ''}');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url),
          headers: {if (token != null) 'Authorization': 'Bearer $token'});
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final data = body['data'] ?? body;
        if (data is Map && data['id'] != null) {
          _registroId = data['id'];
          _horasSonoCtrl.text = data['horasSono']?.toString() ?? '';
          _qualidadeSono = (data['qualidadeSono'] as num?)?.toDouble() ?? 3;
          _humor = (data['humor'] as num?)?.toDouble() ?? 3;
          _energia = (data['energia'] as num?)?.toDouble() ?? 3;
          _bebeuAgua = data['bebeuAgua'] == true;
          _fezTreino = data['fezTreino'] == true;
          _comeuBem = data['comeuBem'] == true;
          _meditou = data['meditou'] == true;
          _obsCtrl.text = data['observacoes']?.toString() ?? '';
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _carregando = false);
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final alunoId = widget.alunoId ?? AuthUtility.userInfo?.data?.id;
      final payload = {
        'data': _dataStr,
        if (alunoId != null) 'alunoId': alunoId,
        'horasSono': double.tryParse(_horasSonoCtrl.text) ?? 0,
        'qualidadeSono': _qualidadeSono.toInt(),
        'humor': _humor.toInt(),
        'energia': _energia.toInt(),
        'bebeuAgua': _bebeuAgua,
        'fezTreino': _fezTreino,
        'comeuBem': _comeuBem,
        'meditou': _meditou,
        'observacoes': _obsCtrl.text.trim(),
      };
      final token = AuthUtility.userInfo?.token;
      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final http.Response resp;
      if (_registroId != null) {
        resp = await http.put(
          Uri.parse(TenantContext.applyToUrl(
              '${ApiLinks.baseUrl}/api/checkin-diario/$_registroId')),
          headers: headers, body: jsonEncode(payload));
      } else {
        resp = await http.post(
          Uri.parse(TenantContext.applyToUrl('${ApiLinks.baseUrl}/api/checkin-diario')),
          headers: headers, body: jsonEncode(payload));
      }
      if (!mounted) return;
      setState(() => _salvando = false);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (resp.statusCode == 201) {
          _registroId = jsonDecode(resp.body)['data']?['id'];
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Check-in salvo!')));
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
    final d = _dataSelecionada;
    final label = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sono & Check-in Diário'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () async {
            final picked = await showDatePicker(
              context: context, initialDate: _dataSelecionada,
              firstDate: DateTime(2020), lastDate: DateTime.now());
            if (picked != null) { setState(() => _dataSelecionada = picked); _carregar(); }
          }),
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Text(label,
                    style: TextStyle(fontWeight: FontWeight.bold, color: GridColors.primary, fontSize: 15))),
                const SizedBox(height: 20),

                _secao('Sono', Icons.bedtime),
                Row(children: [
                  Expanded(child: TextField(
                    controller: _horasSonoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: const InputDecoration(
                      labelText: 'Horas dormidas', border: OutlineInputBorder()),
                  )),
                ]),
                const SizedBox(height: 8),
                Text('Qualidade do sono: ${_qualidadeSono.toInt()}/5'),
                Slider(value: _qualidadeSono, min: 1, max: 5, divisions: 4,
                    activeColor: GridColors.primary,
                    onChanged: (v) => setState(() => _qualidadeSono = v)),

                const SizedBox(height: 16),
                _secao('Humor & Energia', Icons.mood),
                Text('Humor: ${_humor.toInt()}/5'),
                Slider(value: _humor, min: 1, max: 5, divisions: 4,
                    activeColor: Colors.amber,
                    onChanged: (v) => setState(() => _humor = v)),
                Text('Nível de energia: ${_energia.toInt()}/5'),
                Slider(value: _energia, min: 1, max: 5, divisions: 4,
                    activeColor: Colors.orange,
                    onChanged: (v) => setState(() => _energia = v)),

                const SizedBox(height: 16),
                _secao('Hábitos do dia', Icons.checklist),
                _habitoTile('Bebeu 2L+ de água', Icons.water_drop, _bebeuAgua,
                    (v) => setState(() => _bebeuAgua = v), Colors.blue),
                _habitoTile('Fez treino', Icons.fitness_center, _fezTreino,
                    (v) => setState(() => _fezTreino = v), GridColors.primary),
                _habitoTile('Comeu bem / seguiu dieta', Icons.restaurant, _comeuBem,
                    (v) => setState(() => _comeuBem = v), Colors.green),
                _habitoTile('Meditou / respiração consciente', Icons.self_improvement, _meditou,
                    (v) => setState(() => _meditou = v), Colors.purple),

                const SizedBox(height: 16),
                _secao('Observações', Icons.notes),
                TextField(
                  controller: _obsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Como foi o seu dia?',
                    border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
              ]),
            ),
    );
  }

  Widget _secao(String titulo, IconData icone) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icone, color: GridColors.primary, size: 18),
      const SizedBox(width: 6),
      Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: GridColors.primary, fontSize: 14)),
    ]),
  );

  Widget _habitoTile(String label, IconData icone, bool valor, ValueChanged<bool> cb, Color cor) =>
      CheckboxListTile(
        dense: true,
        secondary: Icon(icone, color: cor, size: 20),
        title: Text(label),
        value: valor,
        activeColor: cor,
        onChanged: (v) => cb(v ?? false),
      );
}
