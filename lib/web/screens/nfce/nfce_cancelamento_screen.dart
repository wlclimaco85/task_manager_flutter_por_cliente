import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/nfce/nfce_resultado_model.dart';
import '../../../services/nfce_service.dart';
import '../../../utils/tenant_context.dart';

/// Tela para cancelar uma NFC-e já autorizada.
/// Cancela apenas dentro do prazo de 30 minutos após a autorização.
class NfceCancelamentoScreen extends StatefulWidget {
  final NfceResultadoModel resultado;

  const NfceCancelamentoScreen({super.key, required this.resultado});

  @override
  State<NfceCancelamentoScreen> createState() => _NfceCancelamentoScreenState();
}

class _NfceCancelamentoScreenState extends State<NfceCancelamentoScreen> {
  final NfceService _service = NfceService();
  final TextEditingController _justificativaCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Timer? _countdownTimer;
  Duration _tempoRestante = Duration.zero;
  bool _cancelando = false;
  bool _prazoExpirado = false;

  static const _prazoCancelamento = Duration(minutes: 30);
  static const _minCaracteres = 15;

  @override
  void initState() {
    super.initState();
    _calcularTempoRestante();
    _iniciarCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _justificativaCtrl.dispose();
    super.dispose();
  }

  void _calcularTempoRestante() {
    final dataAuth = widget.resultado.dataAutorizacao;
    if (dataAuth == null) {
      setState(() => _prazoExpirado = true);
      return;
    }
    final prazoFim = dataAuth.add(_prazoCancelamento);
    final agora = DateTime.now();
    final restante = prazoFim.difference(agora);

    if (restante.isNegative) {
      setState(() {
        _prazoExpirado = true;
        _tempoRestante = Duration.zero;
      });
    } else {
      setState(() => _tempoRestante = restante);
    }
  }

  void _iniciarCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_tempoRestante.inSeconds <= 0) {
        setState(() => _prazoExpirado = true);
        _countdownTimer?.cancel();
      } else {
        setState(() => _tempoRestante -= const Duration(seconds: 1));
      }
    });
  }

  String _formatarCountdown() {
    final m = _tempoRestante.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _tempoRestante.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _confirmarCancelamento() async {
    if (!_formKey.currentState!.validate()) return;

    final empresaId = TenantContext.empresaId;
    if (empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empresa não identificada para o cancelamento.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar cancelamento'),
        content: const Text(
          'Essa ação é irreversível.\nDeseja realmente cancelar esta NFC-e?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Sim, cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirma != true || !mounted) return;

    setState(() => _cancelando = true);
    try {
      await _service.cancelarNfce(
        widget.resultado.id,
        _justificativaCtrl.text.trim(),
        empresaId: empresaId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NFC-e cancelada com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on NfceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cancelar: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cancelar NFC-e'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _prazoExpirado
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      border: Border.all(
                        color: _prazoExpirado ? Colors.red : Colors.orange,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              color: _prazoExpirado ? Colors.red : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Cancelamento permitido por até 30 minutos após a autorização',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_prazoExpirado)
                          const Text(
                            'Prazo expirado ou data de autorização indisponível. Não é possível cancelar esta NFC-e pelo app neste momento.',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            'Tempo restante: ${_formatarCountdown()}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _tempoRestante.inMinutes < 5
                                  ? Colors.red
                                  : Colors.orange.shade800,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chave de acesso:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SelectableText(
                    widget.resultado.chaveAcessoFormatada,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if ((widget.resultado.protocolo).isNotEmpty) ...[
                    Text(
                      'Protocolo:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SelectableText(widget.resultado.protocolo),
                    const SizedBox(height: 12),
                  ],
                  if ((widget.resultado.codigoRetorno ?? '').isNotEmpty) ...[
                    Text(
                      'Código SEFAZ:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SelectableText(widget.resultado.codigoRetorno!),
                    const SizedBox(height: 12),
                  ],
                  if ((widget.resultado.dhRecbto ?? '').isNotEmpty) ...[
                    Text(
                      'Recebido em:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SelectableText(widget.resultado.dhRecbto!),
                    const SizedBox(height: 20),
                  ] else
                    const SizedBox(height: 20),
                  TextFormField(
                    controller: _justificativaCtrl,
                    enabled: !_prazoExpirado,
                    maxLines: 4,
                    maxLength: 255,
                    decoration: const InputDecoration(
                      labelText: 'Justificativa do cancelamento *',
                      hintText: 'Mínimo de 15 caracteres',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < _minCaracteres) {
                        return 'Informe pelo menos $_minCaracteres caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _cancelando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cancel),
                      label: const Text('Confirmar cancelamento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: (_prazoExpirado || _cancelando)
                          ? null
                          : _confirmarCancelamento,
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
