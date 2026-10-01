import 'package:flutter/material.dart';
import '../../../services/orcamento_service.dart';
import '../../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_texts.dart';
import '../../../constants/custom_colors.dart';

class OrcamentoFormDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;

  const OrcamentoFormDialog({super.key, this.item, required this.onSaved});

  @override
  State<OrcamentoFormDialog> createState() => _OrcamentoFormDialogState();
}

class _OrcamentoFormDialogState extends State<OrcamentoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  int? _clienteId;
  String? _clienteNome;
  final _observacaoCtrl = TextEditingController();
  final _descontoGeralCtrl = TextEditingController();

  DateTime? _dataEmissao;
  DateTime? _dataValidade;

  final List<_ItemRow> _itens = [];
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _produtos = [];
  bool _loadingClientes = true;
  bool _loadingProdutos = true;

  @override
  void initState() {
    super.initState();
    _dataEmissao = DateTime.now();
    _dataValidade = DateTime.now().add(const Duration(days: 30));
    _loadClientes();
    _loadProdutos();
    if (widget.item != null) {
      final item = widget.item!;
      _clienteId = item['clienteId'];
      _clienteNome = item['clienteNome'];
      _observacaoCtrl.text = item['observacao'] ?? '';
      _descontoGeralCtrl.text = (item['descontoGeral'] ?? 0.0).toString();
      if (item['dataEmissao'] != null) {
        _dataEmissao = DateTime.tryParse(item['dataEmissao']);
      }
      if (item['dataValidade'] != null) {
        _dataValidade = DateTime.tryParse(item['dataValidade']);
      }
      if (item['itens'] != null) {
        for (final i in item['itens']) {
          _itens.add(_ItemRow(
            produtoId: i['produtoId'],
            produtoNome: i['produtoNome'],
            descricaoCtrl: TextEditingController(text: i['descricao'] ?? ''),
            quantidadeCtrl: TextEditingController(text: (i['quantidade'] ?? 1.0).toString()),
            valorUnitarioCtrl: TextEditingController(text: (i['valorUnitario'] ?? 0.0).toString()),
            descontoCtrl: TextEditingController(text: (i['desconto'] ?? 0.0).toString()),
            total: (i['total'] ?? 0.0).toDouble(),
          ));
        }
      }
    }
  }

  Future<void> _loadClientes() async {
    try {
      final response = await NetworkCaller().getRequest(ApiLinks.allParceiros);
      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (data is List) {
          _clientes = data
              .map((e) => Map<String, dynamic>.from(e))
              .where((e) => e['tipoCliente'] == 'CLIENTE' || e['tipoCliente'] == null)
              .toList();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingClientes = false);
  }

  Future<void> _loadProdutos() async {
    try {
      final response = await NetworkCaller().getRequest(ApiLinks.allVendas);
      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (data is List) {
          _produtos = data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingProdutos = false);
  }

  void _addItem() {
    setState(() {
      _itens.add(_ItemRow(
        descricaoCtrl: TextEditingController(),
        quantidadeCtrl: TextEditingController(text: '1'),
        valorUnitarioCtrl: TextEditingController(),
        descontoCtrl: TextEditingController(text: '0'),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() => _itens.removeAt(index));
  }

  double _calcularTotalItem(_ItemRow item) {
    final qtd = double.tryParse(item.quantidadeCtrl.text) ?? 0;
    final vlr = double.tryParse(item.valorUnitarioCtrl.text) ?? 0;
    final desc = double.tryParse(item.descontoCtrl.text) ?? 0;
    return (qtd * vlr) - desc;
  }

  double _calcularTotalGeral() {
    double total = 0;
    for (final item in _itens) {
      total += _calcularTotalItem(item);
    }
    final descGeral = double.tryParse(_descontoGeralCtrl.text) ?? 0;
    return total - descGeral;
  }

  Future<void> _pickDate({required bool isEmissao}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEmissao ? (_dataEmissao ?? DateTime.now()) : (_dataValidade ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isEmissao) _dataEmissao = picked;
        else _dataValidade = picked;
      });
    }
  }

  Map<String, dynamic> _buildPayload() {
    final itensJson = _itens.map((i) => {
      if (i.produtoId != null) 'produtoId': i.produtoId,
      'produtoNome': i.produtoNome ?? i.descricaoCtrl.text,
      'descricao': i.descricaoCtrl.text,
      'quantidade': double.tryParse(i.quantidadeCtrl.text) ?? 0,
      'valorUnitario': double.tryParse(i.valorUnitarioCtrl.text) ?? 0,
      'desconto': double.tryParse(i.descontoCtrl.text) ?? 0,
      'total': _calcularTotalItem(i),
    }).toList();

    return {
      if (widget.item?['caseid'] != null) 'id': widget.item!['id'],
      'clienteId': _clienteId,
      'clienteNome': _clienteNome,
      'dataEmissao': _dataEmissao?.toIso8601String().substring(0, 10),
      'dataValidade': _dataValidade?.toIso8601String().substring(0, 10),
      'observacao': _observacaoCtrl.text,
      'descontoGeral': double.tryParse(_descontoGeralCtrl.text) ?? 0,
      'totalGeral': _calcularTotalGeral(),
      'itens': itensJson,
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um item'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    final payload = _buildPayload();
    final success = widget.item != null
        ? await OrcamentoService.update(widget.item!['id'], payload)
        : await OrcamentoService.create(payload);
    setState(() => _isLoading = false);
    if (success && mounted) {
      Navigator.pop(context);
      widget.onSaved();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 900),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppBar(
                title: Text(widget.item != null ? 'Editar Orçamento' : 'Novo Orçamento'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Dados do Orçamento'),
                      const SizedBox(height: 12),
                      _row([
                        _clienteDropdown(),
                        _dateField('Data Emissão', _dataEmissao, () => _pickDate(isEmissao: true)),
                        _dateField('Data Validade', _dataValidade, () => _pickDate(isEmissao: false)),
                      ]),
                      const SizedBox(height: 24),
                      _sectionTitle('Itens'),
                      const SizedBox(height: 12),
                      ..._buildItemRows(),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar Item'),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Totais'),
                      const SizedBox(height: 12),
                      _row([
                        SizedBox(
                          width: 200,
                          child: TextFormField(
                            controller: _descontoGeralCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Desconto Geral',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: GridColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Total Geral: R\$ ${_calcularTotalGeral().toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _sectionTitle('Observação'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _observacaoCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Observações...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(GridTexts.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _save,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text(GridTexts.save),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItemRows() {
    final rows = <Widget>[];
    for (int i = 0; i < _itens.length; i++) {
      final item = _itens[i];
      final total = _calcularTotalItem(item);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                child: _produtoDropdown(item, i),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 180,
                child: TextFormField(
                  controller: item.descricaoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: item.quantidadeCtrl,
                  decoration: const InputDecoration(labelText: 'Qtd', border: OutlineInputBorder(), isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: item.valorUnitarioCtrl,
                  decoration: const InputDecoration(labelText: 'Valor Unit.', border: OutlineInputBorder(), isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: item.descontoCtrl,
                  decoration: const InputDecoration(labelText: 'Desc.', border: OutlineInputBorder(), isDense: true),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text('R\$ ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removeItem(i),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Widget _clienteDropdown() {
    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<int>(
        value: _clienteId,
        isDense: true,
        decoration: const InputDecoration(
          labelText: 'Cliente',
          border: OutlineInputBorder(),
        ),
        items: _clientes.map((c) {
          final id = c['id'] as int?;
          final nome = c['nome']?.toString() ?? '';
          return DropdownMenuItem(value: id, child: Text(nome));
        }).toList(),
        onChanged: (v) {
          setState(() {
            _clienteId = v;
            _clienteNome = _clientes.firstWhere((c) => c['id'] == v)['nome'];
          });
        },
      ),
    );
  }

  Widget _produtoDropdown(_ItemRow item, int index) {
    return DropdownButtonFormField<int>(
      value: item.produtoId,
      isDense: true,
      decoration: const InputDecoration(
        labelText: 'Produto',
        border: OutlineInputBorder(),
      ),
      items: _produtos.map((p) {
        final id = p['id'] as int?;
        final nome = p['nome']?.toString() ?? p['descricao']?.toString() ?? '';
        return DropdownMenuItem(value: id, child: Text(nome));
      }).toList(),
      onChanged: (v) {
        setState(() {
          item.produtoId = v;
          final prod = _produtos.firstWhere((p) => p['id'] == v);
          item.produtoNome = prod['nome']?.toString() ?? prod['descricao']?.toString() ?? '';
          if (item.descricaoCtrl.text.isEmpty) item.descricaoCtrl.text = item.produtoNome!;
          item.valorUnitarioCtrl.text = (prod['precoVenda']?.toString() ?? prod['valor']?.toString() ?? '0');
        });
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Text(
            date != null
                ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                : label,
          ),
        ]),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Wrap(spacing: 12, runSpacing: 12, children: children);
  }
}

class _ItemRow {
  int? produtoId;
  String? produtoNome;
  TextEditingController descricaoCtrl;
  TextEditingController quantidadeCtrl;
  TextEditingController valorUnitarioCtrl;
  TextEditingController descontoCtrl;
  double? total;

  _ItemRow({
    this.produtoId,
    this.produtoNome,
    TextEditingController? descricaoCtrl,
    TextEditingController? quantidadeCtrl,
    TextEditingController? valorUnitarioCtrl,
    TextEditingController? descontoCtrl,
    this.total,
  })  : descricaoCtrl = descricaoCtrl ?? TextEditingController(),
        quantidadeCtrl = quantidadeCtrl ?? TextEditingController(text: '1'),
        valorUnitarioCtrl = valorUnitarioCtrl ?? TextEditingController(),
        descontoCtrl = descontoCtrl ?? TextEditingController(text: '0');
}
