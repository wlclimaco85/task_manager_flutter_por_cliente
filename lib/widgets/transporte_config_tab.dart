import 'package:flutter/material.dart';

import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';

/// Opcoes do esquema do MDF-e: tpEmit (tipo do emitente) e tpTransp (tipo do transportador).
const List<Map<String, dynamic>> kTransporteTiposEmitente = [
  {'value': 1, 'label': '1 - Prestador de serviço de transporte'},
  {'value': 2, 'label': '2 - Transportador de carga própria'},
  {'value': 3, 'label': '3 - Prestador que emitirá CT-e globalizado'},
];

const List<Map<String, dynamic>> kTransporteTiposTransportador = [
  {'value': 1, 'label': '1 - ETC'},
  {'value': 2, 'label': '2 - TAC'},
  {'value': 3, 'label': '3 - CTC'},
];

/// Aba "Transporte" do cadastro de Parceiro: RNTRC, serie do MDF-e e tipos
/// de emitente/transportador. Le e grava em `/api/transporte/config`.
class TransporteConfigTab extends StatefulWidget {
  final int parceiroId;
  final String? nome;

  const TransporteConfigTab({super.key, required this.parceiroId, this.nome});

  @override
  State<TransporteConfigTab> createState() => _TransporteConfigTabState();
}

class _TransporteConfigTabState extends State<TransporteConfigTab> {
  final _formKey = GlobalKey<FormState>();
  final _rntrcController = TextEditingController();
  final _serieController = TextEditingController(text: '1');

  int _tpEmit = 1;
  int? _tpTransp;
  bool _loading = true;
  bool _saving = false;
  String? _erro;

  String get _urlLeitura =>
      '${ApiLinks.transporteConfig}?parceiroId=${widget.parceiroId}';

  @override
  void initState() {
    super.initState();
    if (widget.parceiroId <= 0) {
      _loading = false;
    } else {
      _carregar();
    }
  }

  @override
  void dispose() {
    _rntrcController.dispose();
    _serieController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final response = await NetworkCaller().getRequest(_urlLeitura);
      if (!mounted) return;
      if (response.isSuccess && response.body is Map<String, dynamic>) {
        _preencher(response.body as Map<String, dynamic>);
      } else {
        _erro =
            'Não foi possível carregar a configuração (HTTP ${response.statusCode}).';
      }
    } catch (e, st) {
      AppLogger.i.error('TransporteConfigTab: erro ao carregar: $e', st);
      _erro = 'Não foi possível carregar a configuração.';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _preencher(Map<String, dynamic> json) {
    _rntrcController.text = json['rntrc']?.toString() ?? '';
    _serieController.text = json['serieMdfe']?.toString() ?? '1';
    _tpEmit = (json['tpEmit'] as num?)?.toInt() ?? 1;
    _tpTransp = (json['tpTransp'] as num?)?.toInt();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _erro = null;
    });
    try {
      final response =
          await NetworkCaller().putRequest(ApiLinks.transporteConfig, {
        'parceiroId': widget.parceiroId,
        'rntrc': _rntrcController.text.trim(),
        'serieMdfe': int.tryParse(_serieController.text.trim()) ?? 1,
        'tpEmit': _tpEmit,
        'tpTransp': _tpTransp,
      });
      if (!mounted) return;
      if (response.isSuccess && response.body is Map<String, dynamic>) {
        _preencher(response.body as Map<String, dynamic>);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuração de transporte salva.')),
        );
      } else {
        _erro =
            'Não foi possível salvar (HTTP ${response.statusCode}). Confira o RNTRC (8 dígitos) e a série.';
      }
    } catch (e, st) {
      AppLogger.i.error('TransporteConfigTab: erro ao salvar: $e', st);
      _erro = 'Não foi possível salvar a configuração.';
    }
    if (mounted) setState(() => _saving = false);
  }

  String? _validarRntrc(String? value) {
    final texto = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (texto.isEmpty) return null;
    return RegExp(r'^\d{8}$').hasMatch(texto) ? null : 'RNTRC deve ter 8 dígitos.';
  }

  String? _validarSerie(String? value) {
    final serie = int.tryParse(value?.trim() ?? '');
    if (serie == null || serie < 1 || serie > 999) {
      return 'Série deve ficar entre 1 e 999.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parceiroId <= 0) {
      return const Center(child: Text('ID do parceiro não disponível'));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transporte${widget.nome == null ? '' : ' - ${widget.nome}'}',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Recarregar',
                    onPressed: _carregar,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_erro != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_erro!,
                      style: TextStyle(color: Colors.red.shade800)),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _caixa(TextFormField(
                    controller: _rntrcController,
                    keyboardType: TextInputType.number,
                    validator: _validarRntrc,
                    decoration: _decoracao('RNTRC'),
                  )),
                  _caixa(TextFormField(
                    controller: _serieController,
                    keyboardType: TextInputType.number,
                    validator: _validarSerie,
                    decoration: _decoracao('Série do MDF-e'),
                  )),
                  _caixa(DropdownButtonFormField<int>(
                    key: ValueKey('tpEmit-$_tpEmit'),
                    initialValue: _tpEmit,
                    isExpanded: true,
                    decoration: _decoracao('Tipo de emitente'),
                    items: [
                      for (final o in kTransporteTiposEmitente)
                        DropdownMenuItem<int>(
                            value: o['value'] as int,
                            child: Text(o['label'] as String,
                                overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _tpEmit = v ?? 1),
                  )),
                  _caixa(DropdownButtonFormField<int?>(
                    key: ValueKey('tpTransp-$_tpTransp'),
                    initialValue: _tpTransp,
                    isExpanded: true,
                    decoration: _decoracao('Tipo de transportador'),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('Não informado')),
                      for (final o in kTransporteTiposTransportador)
                        DropdownMenuItem<int?>(
                            value: o['value'] as int,
                            child: Text(o['label'] as String)),
                    ],
                    onChanged: (v) => setState(() => _tpTransp = v),
                  )),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _saving ? null : _salvar,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _caixa(Widget child) => SizedBox(width: 300, child: child);

  InputDecoration _decoracao(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      );
}
