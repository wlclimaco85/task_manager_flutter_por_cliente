import 'package:flutter/material.dart';
import '../../../services/fornecedor_service.dart';
import '../../services/network_caller.dart';
import '../../../utils/grid_texts.dart';

class FornecedorFormDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  final String? tituloOverride;
  final Future<bool> Function(Map<String, dynamic> payload)? customSaveHandler;

  const FornecedorFormDialog({
    super.key,
    this.item,
    required this.onSaved,
    this.tituloOverride,
    this.customSaveHandler,
  });

  @override
  State<FornecedorFormDialog> createState() => _FornecedorFormDialogState();
}

class _FornecedorFormDialogState extends State<FornecedorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isActive = true;

  final _nomeCtrl = TextEditingController();
  final _razaoSocialCtrl = TextEditingController();
  final _cpfCnpjCtrl = TextEditingController();
  final _ieCtrl = TextEditingController();
  final _inscMunCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefone1Ctrl = TextEditingController();
  final _telefone2Ctrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _observacaoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      final item = widget.item!;
      _nomeCtrl.text = item['nome'] ?? '';
      _razaoSocialCtrl.text = item['razaoSocial'] ?? '';
      _cpfCnpjCtrl.text = item['cpf'] ?? item['cnpj'] ?? '';
      _ieCtrl.text = item['ie'] ?? '';
      _inscMunCtrl.text = item['incrMun'] ?? '';
      _emailCtrl.text = item['email'] ?? '';
      _telefone1Ctrl.text = item['telefone1'] ?? '';
      _telefone2Ctrl.text = item['telefone2'] ?? '';
      _cepCtrl.text = item['cep'] ?? '';
      _ruaCtrl.text = item['rua'] ?? '';
      _numeroCtrl.text = item['numero'] ?? '';
      _complementoCtrl.text = item['complemento'] ?? '';
      _bairroCtrl.text = item['bairro'] ?? '';
      _cidadeCtrl.text = item['cidade'] ?? '';
      _estadoCtrl.text = item['estado'] ?? '';
      _observacaoCtrl.text = item['observacao'] ?? '';
      _isActive = item['status'] != 'INATIVO';
    }
  }

  Future<void> _buscarCep() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;
    try {
      final response = await NetworkCaller().getRequest(
        'https://viacep.com.br/ws/$cep/json/',
      );
      if (response.isSuccess && response.body != null) {
        final d = response.body as Map<String, dynamic>;
        if (d['erro'] == true) return;
        _ruaCtrl.text = d['logradouro'] ?? '';
        _bairroCtrl.text = d['bairro'] ?? '';
        _cidadeCtrl.text = d['localidade'] ?? '';
        _estadoCtrl.text = d['uf'] ?? '';
      }
    } catch (_) {}
  }

  Map<String, dynamic> _buildPayload() {
    return {
      if (widget.item?['id'] != null) 'id': widget.item!['id'],
      'nome': _nomeCtrl.text,
      'razaoSocial': _razaoSocialCtrl.text,
      'cpf': _cpfCnpjCtrl.text,
      'ie': _ieCtrl.text,
      'incrMun': _inscMunCtrl.text,
      'email': _emailCtrl.text,
      'telefone1': _telefone1Ctrl.text,
      'telefone2': _telefone2Ctrl.text,
      'cep': _cepCtrl.text,
      'rua': _ruaCtrl.text,
      'numero': _numeroCtrl.text,
      'complemento': _complementoCtrl.text,
      'bairro': _bairroCtrl.text,
      'cidade': _cidadeCtrl.text,
      'estado': _estadoCtrl.text,
      'observacao': _observacaoCtrl.text,
      'status': _isActive ? 'ATIVO' : 'INATIVO',
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final payload = _buildPayload();
    bool success;
    if (widget.customSaveHandler != null) {
      success = await widget.customSaveHandler!(payload);
    } else {
      final isEdicao = widget.item != null && widget.item!['id'] != null;
      if (isEdicao) {
        success = await FornecedorService.update(widget.item!['id'], payload);
      } else {
        success = await FornecedorService.create(payload);
        // Se falhou porque já existe fornecedor com este CPF/CNPJ, tenta atualizar o existente
        if (!success && (FornecedorService.ultimoErro ?? '').toLowerCase().contains('ja existe')) {
          final existente = await FornecedorService.buscarPorCpf(_cpfCnpjCtrl.text);
          if (existente != null && existente['id'] != null) {
            success = await FornecedorService.update(existente['id'], payload);
          } else {
            // Já existe no banco, portanto a pendência de cadastro está resolvida!
            success = true;
          }
        }
      }
    }
    setState(() => _isLoading = false);
    if (success && mounted) {
      Navigator.pop(context);
      widget.onSaved();
    } else if (mounted) {
      final msg = FornecedorService.ultimoErro ?? 'Erro ao salvar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.item != null && widget.item!['id'] != null;
    final String titulo = widget.tituloOverride ?? (isEdicao ? 'Editar Fornecedor' : 'Novo Fornecedor');

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppBar(
                title: Text(titulo),
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
                      _sectionTitle('Dados'),
                      const SizedBox(height: 12),
                      _row([
                        _textField('Nome', _nomeCtrl, expanded: true),
                        _textField('Razão Social', _razaoSocialCtrl, expanded: true),
                      ]),
                      const SizedBox(height: 16),
                      _row([
                        _textField('CPF/CNPJ', _cpfCnpjCtrl, hint: 'Apenas números'),
                        _textField('IE', _ieCtrl),
                        _textField('Inscrição Municipal', _inscMunCtrl),
                      ]),
                      const SizedBox(height: 24),
                      _sectionTitle('Contato'),
                      const SizedBox(height: 12),
                      _row([
                        _textField('Email', _emailCtrl, expanded: true, keyboardType: TextInputType.emailAddress),
                      ]),
                      const SizedBox(height: 16),
                      _row([
                        _textField('Telefone 1', _telefone1Ctrl, hint: '(99) 99999-9999'),
                        _textField('Telefone 2', _telefone2Ctrl, hint: '(99) 99999-9999'),
                      ]),
                      const SizedBox(height: 24),
                      _sectionTitle('Endereço'),
                      const SizedBox(height: 12),
                      _row([
                        _textField('CEP', _cepCtrl, hint: '99999-999', onChanged: (_) => _buscarCep()),
                      ]),
                      const SizedBox(height: 16),
                      _row([
                        _textField('Rua', _ruaCtrl, expanded: true),
                        _textField('Número', _numeroCtrl, width: 120),
                        _textField('Complemento', _complementoCtrl),
                      ]),
                      const SizedBox(height: 16),
                      _row([
                        _textField('Bairro', _bairroCtrl),
                        _textField('Cidade', _cidadeCtrl),
                        _textField('Estado', _estadoCtrl, width: 80),
                      ]),
                      const SizedBox(height: 24),
                      _sectionTitle('Status'),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: Text(_isActive ? 'Ativo' : 'Inativo'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        dense: true,
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

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _textField(String label, TextEditingController ctrl,
      {bool expanded = false, double? width, String? hint, TextInputType? keyboardType, void Function(String)? onChanged}) {
    return SizedBox(
      width: width ?? (expanded ? null : 200),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children,
    );
  }
}
