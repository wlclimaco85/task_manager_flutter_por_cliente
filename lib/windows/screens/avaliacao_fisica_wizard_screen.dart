import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../services/pdf_export_service.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class AvaliacaoFisicaWizardScreen extends StatefulWidget {
  final Map<String, dynamic>? avaliacaoExistente;

  const AvaliacaoFisicaWizardScreen({super.key, this.avaliacaoExistente});

  @override
  State<AvaliacaoFisicaWizardScreen> createState() =>
      _AvaliacaoFisicaWizardScreenState();
}

class _AvaliacaoFisicaWizardScreenState
    extends State<AvaliacaoFisicaWizardScreen> {
  int _passo = 0;
  bool _carregandoProtocolos = true;
  bool _calculando = false;
  bool _salvando = false;
  String? _erro;

  List<Map<String, dynamic>> _protocolos = [];
  Map<String, dynamic>? _protocoloSelecionado;
  final Map<String, TextEditingController> _controllers = {};
  Map<String, dynamic>? _resultado;

  @override
  void initState() {
    super.initState();
    _carregarProtocolos();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarProtocolos() async {
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/avaliacoes-fisicas/protocolos');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final lista = body is Map ? (body['data'] ?? []) : body;
        setState(() {
          _protocolos = List<Map<String, dynamic>>.from(lista);
          _carregandoProtocolos = false;
        });
      } else {
        setState(() {
          _carregandoProtocolos = false;
          _erro = 'Erro ao carregar protocolos';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoProtocolos = false;
        _erro = 'Erro: $e';
      });
    }
  }

  List<Map<String, dynamic>> get _camposProtocolo {
    if (_protocoloSelecionado == null) return [];
    return List<Map<String, dynamic>>.from(
        _protocoloSelecionado!['campos'] ?? []);
  }

  TextEditingController _ctrl(String fieldName) {
    return _controllers.putIfAbsent(
        fieldName, () => TextEditingController());
  }

  Future<void> _calcular() async {
    setState(() => _calculando = true);
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/avaliacoes-fisicas/calcular');
      final token = AuthUtility.userInfo?.token;

      final payload = <String, dynamic>{
        'protocolo': _protocoloSelecionado!['id'],
      };
      for (final campo in _camposProtocolo) {
        final fn = campo['fieldName'] as String;
        final val = _controllers[fn]?.text.trim();
        if (val != null && val.isNotEmpty) {
          payload[fn] = val;
        }
      }

      final resp = await http.post(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _resultado = Map<String, dynamic>.from(body['data'] ?? body);
          _calculando = false;
          _passo = 2;
        });
      } else {
        setState(() => _calculando = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro no cálculo (${resp.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _calculando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/avaliacoes-fisicas');
      final token = AuthUtility.userInfo?.token;

      final payload = <String, dynamic>{
        'protocolo': _protocoloSelecionado!['id'],
        ...?_resultado,
      };
      for (final campo in _camposProtocolo) {
        final fn = campo['fieldName'] as String;
        final val = _controllers[fn]?.text.trim();
        if (val != null && val.isNotEmpty) payload[fn] = val;
      }

      final resp = await http.post(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      setState(() => _salvando = false);
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avaliação salva com sucesso!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar (${resp.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _exportarPdf() async {
    final nomeAluno =
        AuthUtility.userInfo?.data?.codDadosPessoal?.nome ?? 'Aluno';
    final linhas = <List<String>>[
      ['Protocolo', _protocoloSelecionado!['nome'] ?? ''],
      for (final campo in _camposProtocolo)
        [campo['label'] as String, _controllers[campo['fieldName']]?.text ?? ''],
      if (_resultado != null)
        for (final entry in _resultado!.entries)
          [_labelResultado(entry.key), entry.value.toString()],
    ];
    await PdfExportService.exportar(
      titulo: 'Avaliação Física — $nomeAluno',
      cabecalhos: const ['Campo', 'Valor'],
      linhas: linhas,
    );
  }

  String _labelResultado(String key) {
    const labels = {
      'imc': 'IMC',
      'classificacaoImc': 'Classificação IMC',
      'percentualGordura': '% Gordura',
      'classificacaoGordura': 'Classificação Gordura',
      'somaDobras': 'Soma das Dobras (mm)',
      'relacaoCinturaQuadril': 'Relação Cintura/Quadril',
    };
    return labels[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliação Física Guiada'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregandoProtocolos
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)))
              : Stepper(
                  currentStep: _passo,
                  onStepTapped: (s) {
                    if (s < _passo) setState(() => _passo = s);
                  },
                  controlsBuilder: (context, details) =>
                      _controles(context, details),
                  steps: [
                    Step(
                      title: const Text('Protocolo'),
                      subtitle: const Text('Selecione o método de avaliação'),
                      isActive: _passo >= 0,
                      state: _passo > 0 ? StepState.complete : StepState.indexed,
                      content: _passoProtocolo(),
                    ),
                    Step(
                      title: const Text('Medidas'),
                      subtitle: const Text('Informe as medidas coletadas'),
                      isActive: _passo >= 1,
                      state: _passo > 1 ? StepState.complete : StepState.indexed,
                      content: _passoMedidas(),
                    ),
                    Step(
                      title: const Text('Resultado'),
                      subtitle: const Text('Resultados calculados automaticamente'),
                      isActive: _passo >= 2,
                      state: StepState.indexed,
                      content: _passoResultado(),
                    ),
                  ],
                ),
    );
  }

  Widget _controles(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (_passo == 0)
            ElevatedButton(
              onPressed: _protocoloSelecionado == null
                  ? null
                  : () => setState(() => _passo = 1),
              style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Próximo'),
            ),
          if (_passo == 1) ...[
            ElevatedButton(
              onPressed: _calculando ? null : _calcular,
              style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white),
              child: _calculando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Calcular'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _passo = 0),
              child: const Text('Voltar'),
            ),
          ],
          if (_passo == 2) ...[
            ElevatedButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: const Icon(Icons.save),
              label: _salvando
                  ? const Text('Salvando...')
                  : const Text('Salvar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _exportarPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exportar PDF'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _passo = 1),
              child: const Text('Refazer medidas'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _passoProtocolo() {
    return Column(
      children: _protocolos.map((p) {
        final selecionado = _protocoloSelecionado?['id'] == p['id'];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selecionado ? GridColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.assignment,
              color: selecionado ? GridColors.primary : Colors.grey,
            ),
            title: Text(p['nome'] ?? ''),
            subtitle: Text(
              '${(p['campos'] as List?)?.length ?? 0} campos',
              style: const TextStyle(fontSize: 12),
            ),
            selected: selecionado,
            selectedColor: GridColors.primary,
            onTap: () => setState(() {
              _protocoloSelecionado = p;
              _controllers.clear();
            }),
          ),
        );
      }).toList(),
    );
  }

  Widget _passoMedidas() {
    if (_protocoloSelecionado == null) {
      return const Text('Selecione um protocolo primeiro.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _protocoloSelecionado!['nome'] ?? '',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: GridColors.primary),
        ),
        const SizedBox(height: 16),
        for (final campo in _camposProtocolo) ...[
          TextFormField(
            controller: _ctrl(campo['fieldName'] as String),
            keyboardType: campo['tipo'] == 'number'
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: campo['tipo'] == 'number'
                ? [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'))
                  ]
                : null,
            decoration: InputDecoration(
              labelText: campo['label'] as String,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _passoResultado() {
    if (_resultado == null) {
      return const Text('Nenhum resultado calculado ainda.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados — ${_protocoloSelecionado?['nome'] ?? ''}',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: GridColors.primary),
        ),
        const SizedBox(height: 16),
        ..._resultado!.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_labelResultado(e.key),
                      style: const TextStyle(color: Colors.grey)),
                  Text(
                    e.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
