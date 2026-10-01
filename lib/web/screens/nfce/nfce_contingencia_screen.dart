import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/nfce_provider.dart';
import '../../../services/nfce_service.dart';
import '../../../utils/grid_colors.dart';

/// Tela de modo offline / contingência.
/// Salva vendas localmente quando a SEFAZ está indisponível e permite
/// regularização posterior.
class NfceContingenciaScreen extends StatefulWidget {
  final String motivo;
  final NfceProvider provider;
  final VoidCallback onNovaVenda;
  final bool persistirVendaAtual;

  const NfceContingenciaScreen({
    super.key,
    required this.motivo,
    required this.provider,
    required this.onNovaVenda,
    this.persistirVendaAtual = true,
  });

  @override
  State<NfceContingenciaScreen> createState() => _NfceContingenciaScreenState();
}

class _NfceContingenciaScreenState extends State<NfceContingenciaScreen> {
  static const _storageKey = 'vendas_contingencia';
  final NfceService _service = NfceService();

  List<Map<String, dynamic>> _vendasPendentes = [];
  bool _salvando = false;
  bool _regularizando = false;

  @override
  void initState() {
    super.initState();
    if (widget.persistirVendaAtual) {
      _salvarVendaAtual();
    }
    _carregarVendasPendentes();
  }

  Future<void> _salvarVendaAtual() async {
    final venda = widget.provider.buildVendaJson();
    if (venda == null) return;

    setState(() => _salvando = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_storageKey) ?? [];
      final registro = {
        'timestamp': DateTime.now().toIso8601String(),
        'motivo': widget.motivo,
        'epecStatus': 'PENDENTE_BACKEND',
        'venda': venda,
      };
      existing.add(jsonEncode(registro));
      await prefs.setStringList(_storageKey, existing);
    } catch (e) {
      debugPrint('Erro ao salvar venda em contingência: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _carregarVendasPendentes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    setState(() {
      _vendasPendentes = raw
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> _regularizar() async {
    setState(() => _regularizando = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey) ?? [];
      final pendentes =
          raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();

      final naoEnviadas = <String>[];
      var enviadas = 0;

      for (final registro in pendentes) {
        final payloadVenda = _extrairPayloadVenda(registro);
        if (payloadVenda == null) {
          naoEnviadas.add(jsonEncode(registro));
          continue;
        }

        try {
          final vendaId = await _service.criarVenda(payloadVenda);
          final resultado = await _service.emitirNfce(
            vendaId,
            vendaJson: payloadVenda,
          );

          if (resultado.isAutorizada) {
            enviadas++;
            continue;
          }

          naoEnviadas.add(
            jsonEncode({
              ...registro,
              'timestamp':
                  registro['timestamp'] ?? DateTime.now().toIso8601String(),
              'motivo': resultado.motivoRejeicao ?? registro['motivo'],
              'epecStatus': resultado.isContingencia
                  ? 'PENDENTE_BACKEND'
                  : (resultado.statusSefaz.isEmpty
                      ? 'PENDENTE_BACKEND'
                      : resultado.statusSefaz),
              'venda': payloadVenda,
            }),
          );
        } catch (e) {
          naoEnviadas.add(
            jsonEncode({
              ...registro,
              'venda': payloadVenda,
            }),
          );
        }
      }

      await prefs.setStringList(_storageKey, naoEnviadas);
      await _carregarVendasPendentes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enviadas > 0
                ? '$enviadas venda(s) regularizada(s) com sucesso.'
                : 'Nenhuma venda pôde ser regularizada. A SEFAZ ou o backend de contingência ainda estão indisponíveis.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _regularizando = false);
    }
  }

  Map<String, dynamic>? _extrairPayloadVenda(Map<String, dynamic> registro) {
    final nested = registro['venda'];
    if (nested is Map<String, dynamic>) return nested;

    final itens = registro['itens'];
    final pagamentos = registro['pagamentos'];
    if (itens is List && pagamentos is List) {
      return {
        'empresaId': registro['empresaId'],
        'itens': itens,
        'pagamentos': pagamentos,
        if (registro['clienteCpfCnpj'] != null)
          'clienteCpfCnpj': registro['clienteCpfCnpj'],
        'desconto': registro['desconto'] ?? 0,
      };
    }
    return null;
  }

  int _contarItens(Map<String, dynamic> registro) {
    final payload = _extrairPayloadVenda(registro);
    return (payload?['itens'] as List?)?.length ?? 0;
  }

  double _calcularTotal(Map<String, dynamic> registro) {
    final payload = _extrairPayloadVenda(registro);
    final itens = (payload?['itens'] as List?) ?? const [];
    double total = 0;
    for (final item in itens) {
      if (item is Map<String, dynamic>) {
        final preco = (item['precoUnitario'] ?? 0) as num;
        final quantidade = (item['quantidade'] ?? 0) as num;
        final desconto = (item['desconto'] ?? 0) as num;
        total +=
            (preco.toDouble() * quantidade.toDouble()) - desconto.toDouble();
      }
    }
    final descontoGeral = (payload?['desconto'] as num?)?.toDouble() ?? 0;
    return total - descontoGeral;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AUTORIZADA':
        return Colors.green;
      case 'REJEITADA':
        return Colors.red;
      case 'PENDENTE_BACKEND':
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'AUTORIZADA':
        return 'Autorizada';
      case 'REJEITADA':
        return 'Rejeitada';
      case 'CONTINGENCIA':
        return 'Contingência';
      case 'PENDENTE_BACKEND':
      default:
        return 'EPEC pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Contingência'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SEFAZ indisponível — venda salva em contingência',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.motivo,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'O fluxo local já cobre a fila de contingência. O registro automático em EPEC ainda depende da implementação backend e permanece como pendência técnica.',
                    style: TextStyle(color: Colors.black87, height: 1.35),
                  ),
                  if (_salvando) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 4),
                    const Text('Salvando venda localmente...'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vendas pendentes: ${_vendasPendentes.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                ElevatedButton.icon(
                  icon: _regularizando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: const Text('Regularizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _regularizando ? null : _regularizar,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _vendasPendentes.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma venda pendente.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _vendasPendentes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final v = _vendasPendentes[i];
                        final ts = v['timestamp'] as String? ?? '';
                        final itens = _contarItens(v);
                        final total = _calcularTotal(v);
                        final status =
                            v['epecStatus']?.toString() ?? 'PENDENTE_BACKEND';
                        final motivo = v['motivo']?.toString();

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _statusColor(status).withValues(alpha: 0.12),
                              child: Icon(Icons.receipt_long,
                                  color: _statusColor(status)),
                            ),
                            title: Text(
                                'Venda com $itens item(ns) • R\$ ${total.toStringAsFixed(2)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ts.isNotEmpty)
                                  Text(
                                      ts.substring(0, 16).replaceAll('T', ' ')),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (motivo != null && motivo.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    motivo,
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Nova venda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: widget.onNovaVenda,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
