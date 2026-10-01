import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class DiarioNutricionalScreen extends StatefulWidget {
  final int? alunoId;
  const DiarioNutricionalScreen({super.key, this.alunoId});

  @override
  State<DiarioNutricionalScreen> createState() => _DiarioNutricionalScreenState();
}

class _DiarioNutricionalScreenState extends State<DiarioNutricionalScreen> {
  bool _carregando = true;
  DateTime _dataSelecionada = DateTime.now();
  List<Map<String, dynamic>> _refeicoes = [];

  @override
  void initState() {
    super.initState();
    _carregar();
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
          '${ApiLinks.baseUrl}/api/diario-refeicao?data=$_dataStr${alunoId != null ? '&alunoId=$alunoId' : ''}');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final lista = body['data'] ?? body['content'] ?? body ?? [];
        setState(() {
          _refeicoes = List<Map<String, dynamic>>.from(lista is List ? lista : []);
          _carregando = false;
        });
      } else {
        setState(() { _refeicoes = []; _carregando = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _refeicoes = []; _carregando = false; });
    }
  }

  double get _totalCalorias => _refeicoes.fold(0.0,
      (s, r) => s + ((r['calorias'] as num?)?.toDouble() ?? 0.0));
  double get _totalProteinas => _refeicoes.fold(0.0,
      (s, r) => s + ((r['proteinas'] as num?)?.toDouble() ?? 0.0));
  double get _totalCarbs => _refeicoes.fold(0.0,
      (s, r) => s + ((r['carboidratos'] as num?)?.toDouble() ?? 0.0));
  double get _totalGorduras => _refeicoes.fold(0.0,
      (s, r) => s + ((r['gorduras'] as num?)?.toDouble() ?? 0.0));

  Future<void> _adicionarRefeicao() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _DialogRefeicao(),
    );
    if (result == null) return;
    try {
      final alunoId = widget.alunoId ?? AuthUtility.userInfo?.data?.id;
      final url = TenantContext.applyToUrl('${ApiLinks.baseUrl}/api/diario-refeicao');
      final token = AuthUtility.userInfo?.token;
      final payload = {...result, 'data': _dataStr, if (alunoId != null) 'alunoId': alunoId};
      final resp = await http.post(Uri.parse(url),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload));
      if (resp.statusCode == 201 || resp.statusCode == 200) _carregar();
    } catch (_) {}
  }

  Future<void> _remover(int id) async {
    try {
      final url = TenantContext.applyToUrl('${ApiLinks.baseUrl}/api/diario-refeicao/$id');
      final token = AuthUtility.userInfo?.token;
      await http.delete(Uri.parse(url),
          headers: {if (token != null) 'Authorization': 'Bearer $token'});
      _carregar();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final d = _dataSelecionada;
    final label = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário Nutricional'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Escolher data',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dataSelecionada,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _dataSelecionada = picked);
                _carregar();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarRefeicao,
        icon: const Icon(Icons.add),
        label: const Text('Refeição'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Container(
          color: GridColors.primary.withOpacity(0.07),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: GridColors.primary)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _macroChip('Kcal', _totalCalorias.toStringAsFixed(0), Colors.orange),
              _macroChip('Prot', '${_totalProteinas.toStringAsFixed(1)}g', Colors.blue),
              _macroChip('Carb', '${_totalCarbs.toStringAsFixed(1)}g', Colors.green),
              _macroChip('Gord', '${_totalGorduras.toStringAsFixed(1)}g', Colors.red),
            ]),
          ]),
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : _refeicoes.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.restaurant, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Nenhuma refeição registrada', style: TextStyle(color: Colors.grey)),
                    ]))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _refeicoes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _buildCard(_refeicoes[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _macroChip(String label, String valor, Color cor) => Column(children: [
    Text(valor, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cor)),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ]);

  Widget _buildCard(Map<String, dynamic> r) {
    final nome = r['descricao']?.toString() ?? r['nome']?.toString() ?? '';
    final tipo = r['tipoRefeicao']?.toString() ?? '';
    final kcal = (r['calorias'] as num?)?.toStringAsFixed(0) ?? '0';
    final id = r['id'] as int?;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: GridColors.primary.withOpacity(0.12),
          child: Icon(_iconeRefeicao(tipo), color: GridColors.primary, size: 20),
        ),
        title: Text(nome),
        subtitle: Text(tipo.isNotEmpty ? tipo : 'Refeição',
            style: const TextStyle(fontSize: 12)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$kcal kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (id != null) IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
            onPressed: () => _remover(id),
          ),
        ]),
      ),
    );
  }

  IconData _iconeRefeicao(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'CAFE_DA_MANHA': return Icons.free_breakfast;
      case 'ALMOCO': return Icons.lunch_dining;
      case 'JANTAR': return Icons.dinner_dining;
      case 'LANCHE': return Icons.cookie;
      default: return Icons.restaurant;
    }
  }
}

class _DialogRefeicao extends StatefulWidget {
  const _DialogRefeicao();
  @override
  State<_DialogRefeicao> createState() => _DialogRefeicaoState();
}

class _DialogRefeicaoState extends State<_DialogRefeicao> {
  final _descCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _protCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _gordCtrl = TextEditingController();
  String _tipo = 'ALMOCO';
  final _tipos = ['CAFE_DA_MANHA', 'ALMOCO', 'JANTAR', 'LANCHE', 'PRE_TREINO', 'POS_TREINO'];

  @override
  void dispose() {
    for (final c in [_descCtrl, _calCtrl, _protCtrl, _carbCtrl, _gordCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Refeição'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Descrição / alimento', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _tipo,
          items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
          onChanged: (v) => setState(() => _tipo = v ?? _tipo),
          decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        _numField(_calCtrl, 'Calorias (kcal)'),
        _numField(_protCtrl, 'Proteínas (g)'),
        _numField(_carbCtrl, 'Carboidratos (g)'),
        _numField(_gordCtrl, 'Gorduras (g)'),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'descricao': _descCtrl.text.trim(),
            'tipoRefeicao': _tipo,
            'calorias': double.tryParse(_calCtrl.text) ?? 0,
            'proteinas': double.tryParse(_protCtrl.text) ?? 0,
            'carboidratos': double.tryParse(_carbCtrl.text) ?? 0,
            'gorduras': double.tryParse(_gordCtrl.text) ?? 0,
          }),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _numField(TextEditingController ctrl, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
  );
}
