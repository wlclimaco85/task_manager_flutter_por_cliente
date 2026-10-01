import 'package:flutter/material.dart';

import '../../models/obrigacao_fiscal_model.dart';
import '../../services/obrigacao_fiscal_service.dart';
import '../../utils/grid_colors.dart';

class FiscalAutomationScreen extends StatefulWidget {
  const FiscalAutomationScreen({super.key});

  @override
  State<FiscalAutomationScreen> createState() => _FiscalAutomationScreenState();
}

class _FiscalAutomationScreenState extends State<FiscalAutomationScreen> {
  final _service = ObrigacaoFiscalService();
  final _idCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _channel = 'EMAIL';
  bool _loading = false;
  List<ObrigacaoFiscal> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.listarLembretesPendentes();
      if (mounted) setState(() => _items = data);
    } catch (e) {
      _snack('Erro ao carregar lembretes: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registerSend({int? id}) async {
    final targetId = id ?? int.tryParse(_idCtrl.text.trim());
    if (targetId == null) {
      _snack('Informe o ID da obrigacao.', error: true);
      return;
    }
    try {
      await _service.registrarEnvio(
        obrigacaoId: targetId,
        canalEnvio: _channel,
        mensagemEnvio: _messageCtrl.text.trim().isEmpty
            ? null
            : _messageCtrl.text.trim(),
      );
      _idCtrl.clear();
      _messageCtrl.clear();
      _snack('Envio registrado.');
      await _load();
    } catch (e) {
      _snack('Erro ao registrar envio: $e', error: true);
    }
  }

  Future<void> _finish(int id) async {
    try {
      await _service.atualizarStatusEnvio(
        obrigacaoId: id,
        statusEnvio: 'CONCLUIDA',
      );
      _snack('Obrigacao concluida.');
      await _load();
    } catch (e) {
      _snack('Erro ao concluir obrigacao: $e', error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? GridColors.error : GridColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: const Text('Automacao de Obrigacoes'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 360, child: _manualPanel()),
                      const SizedBox(width: 16),
                      Expanded(child: _queuePanel()),
                    ],
                  )
                : ListView(
                    children: [
                      _manualPanel(),
                      const SizedBox(height: 16),
                      _queuePanel(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _manualPanel() {
    return _Panel(
      title: 'Registrar envio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _idCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ID da obrigacao',
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _channel,
            decoration: const InputDecoration(
              labelText: 'Canal',
              prefixIcon: Icon(Icons.outgoing_mail),
            ),
            items: const [
              DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
              DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp')),
              DropdownMenuItem(value: 'PORTAL', child: Text('Portal')),
              DropdownMenuItem(value: 'SISTEMA', child: Text('Sistema')),
            ],
            onChanged: (value) => setState(() => _channel = value ?? 'EMAIL'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Mensagem',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _registerSend,
            icon: const Icon(Icons.send),
            label: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Widget _queuePanel() {
    return _Panel(
      title: 'Lembretes pendentes',
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          : _items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Nenhum lembrete pendente.'),
                )
              : Column(
                  children: _items.map(_queueItem).toList(),
                ),
    );
  }

  Widget _queueItem(ObrigacaoFiscal item) {
    final id = item.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_late_outlined, color: GridColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.codigo} - ${item.descricao}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${item.statusEnvio ?? 'PENDENTE'} | Protocolo: ${item.protocoloEnvio ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.62)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Registrar envio',
            onPressed: id == null ? null : () => _registerSend(id: id),
            icon: const Icon(Icons.send_outlined),
          ),
          IconButton(
            tooltip: 'Concluir',
            onPressed: id == null ? null : () => _finish(id),
            icon: const Icon(Icons.check_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: GridColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
