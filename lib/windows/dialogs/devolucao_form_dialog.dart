import 'package:flutter/material.dart';
import '../../../services/devolucao_service.dart';
import '../../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_texts.dart';

class DevolucaoFormDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;

  const DevolucaoFormDialog({super.key, this.item, required this.onSaved});

  @override
  State<DevolucaoFormDialog> createState() => _DevolucaoFormDialogState();
}

class _DevolucaoFormDialogState extends State<DevolucaoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _tipo;
  int? _clienteFornecedorId;
  String? _clienteFornecedorNome;
  int? _documentoOrigemId;
  String? _documentoOrigemNumero;
  String? _documentoOrigemTipo;
  final _motivoCtrl = TextEditingController();
  final _observacaoCtrl = TextEditingController();

  DateTime? _data;

  final List<_ItemRow> _itens = [];
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _produtos = [];
  bool _loadingClientes = true;
  bool _loadingProdutos = true;

  final _tipoOptions = ['DEVOLUCAO_VENDA', 'DEVOLUCAO_COMPRA'];

  @override
  void initState() {
    super.initState();
    _data = DateTime.now();
    _loadClientes();
    _loadProdutos();
    if (widget.item != null) {
      final item = widget.item!;
      _tipo = item['tipo'];
      _clienteFornecedorId = item['clienteFornecedorId'];
      _clienteFornecedorNome = item['clienteFornecedorNome'];
      _documentoOrigemId = item['documentoOrigemId'];
      _documentoOrigemNumero = item['documentoOrigemNumero'];
      _documentoOrigemTipo = item['documentoOrigemTipo'];
      _motivoCtrl.text = item['motivo'] ?? '';
      _observacaoCtrl.text = item['observacao'] ?? '';
      if (item['data'] != null) {
        _data = DateTime.tryParse(item['data']);
      }
      if (item['itens'] != null) {
        for (final i in item['itens']) {
          _itens.add(_ItemRow(
            produtoId: i['produtoId'],
            produtoNome: i['produtoNome'],
            quantidadeCtrl: TextEditingController(text: (i['quantidade'] ?? 1.0).toString()),
            valorUnitarioCtrl: TextEditingController(text: (i['valorUnitario'] ?? 0.0).toString()),
            motivoCtrl: TextEditingController(text: i['motivo'] ?? ''),
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
        quantidadeCtrl: TextEditingController(text: '1'),
        valorUnitarioCtrl: TextEditingController(),
        motivoCtrl: TextEditingController(),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() => _itens.removeAt(index));
  }

  double _calcularTotalItem(_ItemRow item) {
    final qtd = double.tryParse(item.quantidadeCtrl.text) ?? 0;
    final vlr = double.tryParse(item.valorUnitarioCtrl.text) ?? 0;
    return qtd * vlr;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _data = picked);
    }
  }

  Map<String, dynamic> _buildPayload() {
    final itensJson = _itens.map((i) => {
      if (i.produtoId != null) 'produtoId': i.produtoId,
      'produtoNome': i.produtoNome ?? '',
      'quantidade': double.tryParse(i.quantidadeCtrl.text) ?? 0,
      'valorUnitario': double.tryParse(i.valorUnitarioCtrl.text) ?? 0,
      'motivo': i.motivoCtrl.text,
    }).toList();

    return {
      if (widget.item?['id'] != null) 'id': widget.item!['id'],
      'tipo': _tipo,
      'clienteFornecedorId': _clienteFornecedorId,
      'clienteFornecedorNome': _clienteFornecedorNome,
      'documentoOrigemId': _documentoOrigemId,
      'documentoOrigemNumero': _documentoOrigemNumero,
      'documentoOrigemTipo': _documentoOrigemTipo,
      'data': _data?.toIso8601String().substring(0, 10),
      'motivo': _motivoCtrl.text,
      'observacao': _observacaoCtrl.text,
      'itens': itensJson,
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo de devolução'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_clienteFornecedorId == null) {
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
        ? await DevolucaoService.update(widget.item!['id'], payload)
        : await DevolucaoService.create(payload);
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
                title: Text(widget.item != null ? 'Editar Devolução' : 'Nova Devolução'),
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
                      _sectionTitle('Dados da Devolução'),
                      const SizedBox(height: 12),
                      _row([
                        _tipoDropdown(),
                        _clienteDropdown(),
                        _dateField('Data', _data, _pickDate),
                      ]),
                      const SizedBox(height: 12),
                      _row([
                        _documentoOrigemField(),
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
                      _sectionTitle('Motivo'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _motivoCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Motivo da devolução...',
                        ),
                      ),
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
                width: 200,
                child: TextFormField(
                  controller: item.motivoCtrl,
                  decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder(), isDense: true),
                ),
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

  Widget _tipoDropdown() {
    return SizedBox(
      width: 250,
      child: DropdownButtonFormField<String>(
        value: _tipo,
        isDense: true,
        decoration: const InputDecoration(
          labelText: 'Tipo',
          border: OutlineInputBorder(),
        ),
        items: _tipoOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (v) => setState(() => _tipo = v),
      ),
    );
  }

  Widget _clienteDropdown() {
    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<int>(
        value: _clienteFornecedorId,
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
            _clienteFornecedorId = v;
            _clienteFornecedorNome = _clientes.firstWhere((c) => c['id'] == v)['nome'];
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
          if (item.valorUnitarioCtrl.text.isEmpty) {
            item.valorUnitarioCtrl.text = (prod['precoVenda']?.toString() ?? prod['valor']?.toString() ?? '0');
          }
        });
      },
    );
  }

  Widget _documentoOrigemField() {
    return SizedBox(
      width: 300,
      child: TextFormField(
        decoration: const InputDecoration(
          labelText: 'Documento Origem (Nº)',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        initialValue: _documentoOrigemNumero ?? '',
        onChanged: (v) => _documentoOrigemNumero = v,
      ),
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
  TextEditingController quantidadeCtrl;
  TextEditingController valorUnitarioCtrl;
  TextEditingController motivoCtrl;

  _ItemRow({
    this.produtoId,
    this.produtoNome,
    TextEditingController? quantidadeCtrl,
    TextEditingController? valorUnitarioCtrl,
    TextEditingController? motivoCtrl,
  })  : quantidadeCtrl = quantidadeCtrl ?? TextEditingController(text: '1'),
        valorUnitarioCtrl = valorUnitarioCtrl ?? TextEditingController(),
        motivoCtrl = motivoCtrl ?? TextEditingController();
}
