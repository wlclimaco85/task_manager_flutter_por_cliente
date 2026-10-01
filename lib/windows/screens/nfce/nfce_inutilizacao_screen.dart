import 'package:flutter/material.dart';

import '../../../services/nfce_service.dart';
import '../../../utils/grid_texts.dart';

/// Tela para inutilização de faixa de numeração NFC-e.
/// Apenas para perfis FISCAL/ADMIN.
/// Permite inutilizar sequências de números que não foram emitidos.
class NfceInutilizacaoScreen extends StatefulWidget {
  final int empresaId;
  final String uf;
  final String ambiente;

  const NfceInutilizacaoScreen({
    super.key,
    required this.empresaId,
    required this.uf,
    this.ambiente = 'HOMOLOGACAO',
  });

  @override
  State<NfceInutilizacaoScreen> createState() => _NfceInutilizacaoScreenState();
}

class _NfceInutilizacaoScreenState extends State<NfceInutilizacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serieCtrl = TextEditingController(text: '1');
  final _numInicioCtrl = TextEditingController();
  final _numFimCtrl = TextEditingController();
  final _justificativaCtrl = TextEditingController();
  final NfceService _service = NfceService();

  bool _enviando = false;
  String? _erro;
  String? _sucesso;

  static const _minCaracteres = 15;

  @override
  void dispose() {
    _serieCtrl.dispose();
    _numInicioCtrl.dispose();
    _numFimCtrl.dispose();
    _justificativaCtrl.dispose();
    super.dispose();
  }

  Future<void> _inutilizar() async {
    if (!_formKey.currentState!.validate()) return;

    final numInicio = int.tryParse(_numInicioCtrl.text.trim());
    final numFim = int.tryParse(_numFimCtrl.text.trim());
    final serie = int.tryParse(_serieCtrl.text.trim());

    if (numInicio == null || numFim == null || serie == null) {
      setState(() => _erro = GridTexts.invalidSeriesAndNumbers);
      return;
    }
    if (numFim < numInicio) {
      setState(() => _erro = GridTexts.finalNumberMustBeGreaterOrEqual);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(GridTexts.confirmInvalidationTitle),
        content: Text(
          '${GridTexts.confirmInvalidationMessage(numInicio, numFim, serie, widget.uf, widget.ambiente)}\n\n'
          '${GridTexts.invalidationIrreversibleNotice}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              GridTexts.confirm,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _enviando = true;
      _erro = null;
      _sucesso = null;
    });

    try {
      await _service.inutilizar(
        empresaId: widget.empresaId,
        uf: widget.uf,
        ambiente: widget.ambiente,
        serie: serie,
        numeroInicio: numInicio,
        numeroFim: numFim,
        justificativa: _justificativaCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _sucesso =
              GridTexts.rangeInvalidationSuccess;
          _numInicioCtrl.clear();
          _numFimCtrl.clear();
          _justificativaCtrl.clear();
        });
      }
    } on NfceException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } catch (e) {
      if (mounted) setState(() => _erro = GridTexts.invalidationError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(GridTexts.nfceNumberInvalidationTitle),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            GridTexts.invalidationWarningBanner,
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: widget.uf,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: GridTexts.uf,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: widget.ambiente,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: GridTexts.environment,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _serieCtrl,
                    decoration: const InputDecoration(
                      labelText: GridTexts.series,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return GridTexts.informSeries;
                      if (int.tryParse(v.trim()) == null) return GridTexts.seriesMustBeNumber;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _numInicioCtrl,
                          decoration: const InputDecoration(
                            labelText: GridTexts.initialNumber,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return GridTexts.requiredField;
                            if (int.tryParse(v.trim()) == null) return GridTexts.invalidValue;
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _numFimCtrl,
                          decoration: const InputDecoration(
                            labelText: GridTexts.finalNumber,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return GridTexts.requiredField;
                            if (int.tryParse(v.trim()) == null) return GridTexts.invalidValue;
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _justificativaCtrl,
                    decoration: const InputDecoration(
                      labelText: GridTexts.justification,
                      border: OutlineInputBorder(),
                      helperText: GridTexts.invalidationReasonHelper,
                    ),
                    maxLines: 3,
                    validator: (v) {
                      if (v == null || v.trim().length < _minCaracteres) {
                        return GridTexts.justificationMinLength(_minCaracteres);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_erro != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(_erro!, style: const TextStyle(color: Colors.red)),
                    ),
                  if (_erro != null) const SizedBox(height: 12),
                  if (_sucesso != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _sucesso!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_sucesso != null) const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: _enviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.block),
                      label: Text(
                        _enviando ? GridTexts.invalidating : GridTexts.invalidateNumbering,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _enviando ? null : _inutilizar,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
