// lib/web/dialogs/rateio_dialog.dart
import 'package:flutter/material.dart';
import '../../services/rateio_service.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';

/// Dialog to configure rateio entre centros de custo for a lancamento.
class RateioDialog extends StatefulWidget {
  final int lancamentoId;
  final String lancamentoTipo; // 'CONTA_PAGAR' or 'CONTA_RECEBER'
  final String? lancamentoDescricao;

  const RateioDialog({
    super.key,
    required this.lancamentoId,
    required this.lancamentoTipo,
    this.lancamentoDescricao,
  });

  @override
  State<RateioDialog> createState() => _RateioDialogState();
}

class _RateioDialogState extends State<RateioDialog> {
  final _service = RateioService();
  final List<_RateioItemRow> _itens = [];
  List<Map<String, dynamic>> _centrosCusto = [];
  List<Map<String, dynamic>> _categorias = [];
  bool _loading = true;
  bool _saving = false;
  bool _loadingDropdowns = true;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    _loadExistingRateio();
  }

  Future<void> _loadDropdowns() async {
    setState(() => _loadingDropdowns = true);
    try {
      final ccRes = await NetworkCaller().getRequest(ApiLinks.allCentrosCusto);
      final catRes = await NetworkCaller().getRequest(ApiLinks.allCategoriasFinanceiras);
      if (ccRes.isSuccess && ccRes.body != null) {
        _centrosCusto = _extractList(ccRes.body!);
      }
      if (catRes.isSuccess && catRes.body != null) {
        _categorias = _extractList(catRes.body!);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingDropdowns = false);
  }

  Future<void> _loadExistingRateio() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getRateio(
        tipo: widget.lancamentoTipo,
        id: widget.lancamentoId,
      );
      if (items.isNotEmpty && mounted) {
        setState(() {
          _itens.clear();
          _itens.addAll(items.map((j) => _RateioItemRow.fromJson(j)));
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is List) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    if (body.containsKey('content') && body['content'] is List) {
      return List<Map<String, dynamic>>.from(body['content']);
    }
    final values = body.values.whereType<List>();
    if (values.isNotEmpty) {
      return List<Map<String, dynamic>>.from(values.first);
    }
    return [];
  }

  void _addItem() {
    setState(() => _itens.add(_RateioItemRow()));
  }

  void _removeItem(int index) {
    setState(() => _itens.removeAt(index));
  }

  double get _totalPercentual {
    return _itens.fold<double>(
      0,
      (sum, i) => sum + (i.tipo == 'PERCENTUAL' ? (i.percentual ?? 0) : 0),
    );
  }

  double get _remainingPercentual => 100 - _totalPercentual;

  bool get _isValid {
    if (_itens.isEmpty) return false;
    if (_itens.any((i) => i.centroCustoId == null)) return false;
    final total = _totalPercentual;
    return (total - 100).abs() < 0.01;
  }

  Future<void> _save() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GridColors.error,
          content: Text('Verifique: todos os centros de custo devem estar selecionados e a soma dos percentuais deve ser 100%'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final body = {
        'lancamentoId': widget.lancamentoId,
        'lancamentoTipo': widget.lancamentoTipo,
        'itens': _itens.map((i) => i.toJson()).toList(),
      };
      final success = await _service.saveRateio(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: success ? GridColors.success : GridColors.error,
          content: Text(success ? 'Rateio salvo com sucesso!' : 'Erro ao salvar rateio'),
        ));
        if (success) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: GridColors.error, content: Text('Erro: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.scale, color: GridColors.secondary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configurar Rateio',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: GridColors.textSecondary),
                        ),
                        Text(
                          '${widget.lancamentoTipo} #${widget.lancamentoId}${widget.lancamentoDescricao != null ? ' — ${widget.lancamentoDescricao}' : ''}',
                          style: const TextStyle(fontSize: 12, color: GridColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: GridColors.divider),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isValid ? GridColors.successLight : GridColors.filterBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isValid ? GridColors.success : GridColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Total %', '${_totalPercentual.toStringAsFixed(1)}%', _isValid ? GridColors.success : GridColors.textSecondary),
                    _buildStat('Restante', '${_remainingPercentual.toStringAsFixed(1)}%', _remainingPercentual == 0 ? GridColors.success : GridColors.warning),
                    _buildStat('Itens', '${_itens.length}', GridColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadingDropdowns
                        ? const Center(child: Text('Carregando centros de custo...'))
                        : _itens.isEmpty
                            ? const Center(child: Text('Nenhum item de rateio. Clique em "Adicionar" para começar.', style: TextStyle(color: GridColors.textMuted)))
                            : ListView.builder(shrinkWrap: true, itemCount: _itens.length, itemBuilder: (ctx, i) => _buildItemCard(i)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadingDropdowns ? null : _addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                    style: OutlinedButton.styleFrom(foregroundColor: GridColors.secondary, side: const BorderSide(color: GridColors.divider)),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: (_saving || !_isValid) ? null : _save,
                    icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save, size: 18),
                    label: Text(_saving ? 'Salvando...' : 'Salvar Rateio'),
                    style: ElevatedButton.styleFrom(backgroundColor: GridColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: GridColors.textMuted)),
    ]);
  }

  Widget _buildItemCard(int index) {
    final item = _itens[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: GridColors.borderSubtle)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                value: item.centroCustoId,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Centro de Custo', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                items: _centrosCusto.map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text('${c['nome'] ?? ''}', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => item.centroCustoId = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                value: item.categoriaId,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Categoria (opc.)', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                items: _categorias.map((c) => DropdownMenuItem<int>(value: c['id'] as int, child: Text('${c['descricao'] ?? c['nome'] ?? ''}', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => item.categoriaId = v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<String>(
                value: item.tipo,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                items: const [DropdownMenuItem(value: 'PERCENTUAL', child: Text('% Percentual')), DropdownMenuItem(value: 'VALOR', child: Text('Valor Fixo'))],
                onChanged: (v) { if (v != null) setState(() => item.tipo = v); },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: item.tipo == 'PERCENTUAL' ? (item.percentual != null ? item.percentual!.toStringAsFixed(1) : '') : (item.valor != null ? item.valor!.toStringAsFixed(2) : ''),
                decoration: InputDecoration(
                  labelText: item.tipo == 'PERCENTUAL' ? '%' : 'Valor',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  suffixText: item.tipo == 'PERCENTUAL' ? '%' : 'R\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (item.tipo == 'PERCENTUAL') { item.percentual = parsed; } else { item.valor = parsed; }
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: GridColors.error),
              onPressed: () => _removeItem(index),
              tooltip: 'Remover',
            ),
          ],
        ),
      ),
    );
  }
}

class _RateioItemRow {
  int? categoriaId;
  int? centroCustoId;
  String tipo;
  double? percentual;
  double? valor;

  _RateioItemRow({this.categoriaId, this.centroCustoId, this.tipo = 'PERCENTUAL', this.percentual, this.valor});

  factory _RateioItemRow.fromJson(Map<String, dynamic> json) {
    return _RateioItemRow(
      categoriaId: json['categoriaId'],
      centroCustoId: json['centroCustoId'],
      tipo: json['tipoRateio']?.toString() ?? 'PERCENTUAL',
      percentual: (json['percentual'] as num?)?.toDouble(),
      valor: (json['valor'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (centroCustoId != null) 'centroCustoId': centroCustoId,
      'tipoRateio': tipo,
      if (percentual != null) 'percentual': percentual,
      if (valor != null) 'valor': valor,
    };
  }
}
