import 'package:flutter/material.dart';

import '../../models/crm_deal_model.dart';
import '../../services/crm_deal_service.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

class CrmPipelineScreen extends StatefulWidget {
  const CrmPipelineScreen({super.key});

  @override
  State<CrmPipelineScreen> createState() => _CrmPipelineScreenState();
}

class _CrmPipelineScreenState extends State<CrmPipelineScreen> {
  static const _stages = [
    'LEAD',
    'QUALIFICADO',
    'PROPOSTA',
    'NEGOCIACAO',
    'GANHO',
    'PERDIDO',
  ];

  final _service = CrmDealService();
  bool _loading = false;
  List<CrmDeal> _deals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.listDeals();
      if (mounted) setState(() => _deals = data);
    } catch (e) {
      _snack('Erro ao carregar funil: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _move(CrmDeal deal, String stage) async {
    if (deal.id == null) return;
    try {
      await _service.updateStage(
        dealId: deal.id!,
        stage: stage,
        status: stage == 'GANHO' || stage == 'PERDIDO' ? 'CLOSED' : 'OPEN',
      );
      await _load();
    } catch (e) {
      _snack('Erro ao mover oportunidade: $e', error: true);
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
        title: const Text('CRM e Funil'),
        actions: [
          IconButton(
            tooltip: 'Importar pedido',
            onPressed: () => _showMarketplaceDialog(),
            icon: const Icon(Icons.storefront),
          ),
          IconButton(
            tooltip: 'Nova oportunidade',
            onPressed: () => _showDealDialog(),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 820;
                final columns = _stages.map(_stageColumn).toList();
                return compact
                    ? ListView(
                        padding: const EdgeInsets.all(12),
                        children: columns,
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: columns
                              .map(
                                (child) => SizedBox(
                                  width: 280,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: child,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
              },
            ),
    );
  }

  Widget _stageColumn(String stage) {
    final items = _deals.where((deal) => deal.stage == stage).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _stageLabel(stage),
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 12,
                backgroundColor: GridColors.primary.withValues(alpha: 0.1),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(fontSize: 11, color: GridColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              'Sem oportunidades',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.48)),
            )
          else
            ...items.map(_dealCard),
        ],
      ),
    );
  }

  Widget _dealCard(CrmDeal deal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.divider.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deal.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Mover etapa',
                icon: const Icon(Icons.more_horiz),
                onSelected: (stage) => _move(deal, stage),
                itemBuilder: (_) => _stages
                    .where((stage) => stage != deal.stage)
                    .map(
                      (stage) => PopupMenuItem(
                        value: stage,
                        child: Text(_stageLabel(stage)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          if (deal.customerName != null && deal.customerName!.isNotEmpty)
            Text(
              deal.customerName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.black.withValues(alpha: 0.58)),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(deal.source),
              if (deal.marketplace != null) _chip(deal.marketplace!),
              if (deal.externalOrderId != null) _chip('#${deal.externalOrderId}'),
            ],
          ),
          if (deal.amount != null) ...[
            const SizedBox(height: 8),
            Text(
              'R\$ ${deal.amount!.toStringAsFixed(2)}',
              style: const TextStyle(
                color: GridColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: GridColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Future<void> _showDealDialog() async {
    final title = TextEditingController();
    final customer = TextEditingController();
    final amount = TextEditingController();
    final notes = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova oportunidade'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Titulo')),
              TextField(controller: customer, decoration: const InputDecoration(labelText: 'Cliente')),
              TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor')),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'Observacao')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(GridTexts.cancel)),
          FilledButton(
            onPressed: () async {
              if (title.text.trim().isEmpty) return;
              await _service.createDeal(
                title: title.text.trim(),
                customerName: customer.text.trim().isEmpty ? null : customer.text.trim(),
                amount: double.tryParse(amount.text.replaceAll(',', '.')),
                notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
              );
              if (mounted) Navigator.pop(context);
              await _load();
            },
            child: const Text(GridTexts.save),
          ),
        ],
      ),
    );
  }

  Future<void> _showMarketplaceDialog() async {
    final source = TextEditingController(text: 'ECOMMERCE');
    final marketplace = TextEditingController();
    final orderId = TextEditingController();
    final customer = TextEditingController();
    final amount = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importar pedido'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: source, decoration: const InputDecoration(labelText: 'Origem')),
              TextField(controller: marketplace, decoration: const InputDecoration(labelText: 'Marketplace')),
              TextField(controller: orderId, decoration: const InputDecoration(labelText: 'Pedido externo')),
              TextField(controller: customer, decoration: const InputDecoration(labelText: 'Cliente')),
              TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(GridTexts.cancel)),
          FilledButton(
            onPressed: () async {
              if (source.text.trim().isEmpty || orderId.text.trim().isEmpty) return;
              await _service.importMarketplaceOrder(
                source: source.text.trim(),
                marketplace: marketplace.text.trim().isEmpty ? null : marketplace.text.trim(),
                externalOrderId: orderId.text.trim(),
                customerName: customer.text.trim().isEmpty ? null : customer.text.trim(),
                amount: double.tryParse(amount.text.replaceAll(',', '.')),
                paymentStatus: 'PENDING',
              );
              if (mounted) Navigator.pop(context);
              await _load();
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'LEAD':
        return 'Lead';
      case 'QUALIFICADO':
        return 'Qualificado';
      case 'PROPOSTA':
        return 'Proposta';
      case 'NEGOCIACAO':
        return 'Negociacao';
      case 'GANHO':
        return 'Ganho';
      case 'PERDIDO':
        return 'Perdido';
      default:
        return stage;
    }
  }
}
