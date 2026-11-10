import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../services/fornecedor_service.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/grid_texts.dart';
import '../../services/network_caller.dart';

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
  bool _buscandoCep = false;

  int? _empresaId;
  String? _empresaNome;
  int? _parceiroId;
  String? _parceiroNome;

  List<Map<String, dynamic>> _listaEmpresas = [];
  List<Map<String, dynamic>> _listaParceiros = [];
  bool _carregandoVinculos = false;

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
    _inicializarVinculos();
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

  void _inicializarVinculos() {
    final item = widget.item;
    final login = AuthUtility.userInfo?.login;

    // 1. Empresa
    if (item != null && item['empresaId'] != null) {
      _empresaId = int.tryParse(item['empresaId'].toString());
      _empresaNome = item['empresaNome']?.toString();
    } else if (item != null && item['empresa'] != null && item['empresa'] is Map) {
      _empresaId = int.tryParse(item['empresa']['id']?.toString() ?? '');
      _empresaNome = item['empresa']['nome']?.toString();
    } else if (login?.empresa != null) {
      _empresaId = login!.empresa!.id;
      _empresaNome = login.empresa!.nome;
    }

    // 2. Parceiro
    if (item != null && item['parceiroId'] != null) {
      _parceiroId = int.tryParse(item['parceiroId'].toString());
      _parceiroNome = item['parceiroNome']?.toString();
    } else if (item != null && item['parceiro'] != null && item['parceiro'] is Map) {
      _parceiroId = int.tryParse(item['parceiro']['id']?.toString() ?? '');
      _parceiroNome = item['parceiro']['nome']?.toString() ?? item['parceiro']['razaoSocial']?.toString();
    } else if (login?.parceiro != null) {
      _parceiroId = login!.parceiro!.id;
      _parceiroNome = login.parceiro!.nome ?? login.parceiro!.razaoSocial;
    }

    // Popula lista de empresas
    final empresasTemp = <Map<String, dynamic>>[];
    if (AuthUtility.empresasAcesso.isNotEmpty) {
      for (final ea in AuthUtility.empresasAcesso) {
        empresasTemp.add({'id': ea.empresaId, 'nome': ea.empresaNome ?? 'Empresa ${ea.empresaId}'});
      }
    }
    if (_empresaId != null && !empresasTemp.any((e) => e['id'] == _empresaId)) {
      empresasTemp.insert(0, {'id': _empresaId, 'nome': _empresaNome ?? 'Empresa $_empresaId'});
    }
    _listaEmpresas = empresasTemp;

    // Popula lista inicial de parceiros com o selecionado
    if (_parceiroId != null) {
      _listaParceiros = [
        {'id': _parceiroId, 'nome': _parceiroNome ?? 'Parceiro $_parceiroId'}
      ];
    }

    _carregarParceirosDaEmpresa();
  }

  Future<void> _carregarParceirosDaEmpresa() async {
    if (_empresaId == null) return;
    try {
      setState(() => _carregandoVinculos = true);
      final resp = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/parceiro?empresaId=$_empresaId&tamanho=50',
      );
      if (resp.isSuccess && resp.body != null) {
        List? lista;
        final dynamic rawData = resp.body?['data'] ?? resp.body;
        if (rawData is List) {
          lista = rawData;
        } else if (rawData is Map && rawData['dados'] is List) {
          lista = rawData['dados'] as List;
        }
        if (lista != null) {
          final parceiros = lista
              .whereType<Map>()
              .map((p) => {
                    'id': p['id'],
                    'nome': (p['nome'] ?? p['razaoSocial'] ?? 'Parceiro ${p['id']}').toString(),
                  })
              .toList();

          if (mounted) {
            setState(() {
              if (_parceiroId != null && !parceiros.any((p) => p['id'] == _parceiroId)) {
                parceiros.insert(0, {'id': _parceiroId, 'nome': _parceiroNome ?? 'Parceiro $_parceiroId'});
              }
              _listaParceiros = parceiros;
              if (_parceiroId == null && _listaParceiros.isNotEmpty) {
                _parceiroId = _listaParceiros.first['id'] as int?;
                _parceiroNome = _listaParceiros.first['nome'] as String?;
              }
            });
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _carregandoVinculos = false);
    }
  }

  Future<void> _buscarCep() async {
    final cep = _cepCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um CEP válido com 8 dígitos para buscar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _buscandoCep = true);
    try {
      final response = await NetworkCaller().getRequest(
        'https://viacep.com.br/ws/$cep/json/',
      );
      if (response.isSuccess && response.body != null) {
        final d = response.body as Map<String, dynamic>;
        if (d['erro'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CEP não encontrado.'), backgroundColor: Colors.red),
            );
          }
          return;
        }
        setState(() {
          _ruaCtrl.text = (d['logradouro'] ?? '').toString();
          _bairroCtrl.text = (d['bairro'] ?? '').toString();
          _cidadeCtrl.text = (d['localidade'] ?? '').toString();
          _estadoCtrl.text = (d['uf'] ?? '').toString();
          if ((d['complemento'] ?? '').toString().isNotEmpty && _complementoCtrl.text.isEmpty) {
            _complementoCtrl.text = d['complemento'].toString();
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Endereço preenchido com sucesso pelo CEP!'),
              backgroundColor: GridColors.success,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível consultar o CEP.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao consultar CEP: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      if (widget.item?['id'] != null) 'id': widget.item!['id'],
      if (_empresaId != null) 'empresaId': _empresaId,
      if (_empresaId != null) 'empresa': {'id': _empresaId, 'nome': _empresaNome},
      if (_parceiroId != null) 'parceiroId': _parceiroId,
      if (_parceiroId != null) 'parceiro': {'id': _parceiroId, 'nome': _parceiroNome},
      'nome': _nomeCtrl.text,
      'razaoSocial': _razaoSocialCtrl.text,
      'cpf': _cpfCnpjCtrl.text,
      'cnpj': _cpfCnpjCtrl.text,
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
    if (_empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A Empresa é obrigatória para vincular o cadastro.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_parceiroId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O Parceiro vinculado é obrigatório.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 850),
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
                      _sectionTitle('Vínculo Obrigatório (Empresa e Parceiro) *'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 320,
                            child: DropdownButtonFormField<int>(
                              key: const Key('dropdown_empresa_fornecedor'),
                              isExpanded: true,
                              value: _empresaId,
                              decoration: const InputDecoration(
                                labelText: 'Empresa *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: _listaEmpresas.map((e) {
                                return DropdownMenuItem<int>(
                                  value: e['id'] as int,
                                  child: Text(
                                    '${e['id']} - ${e['nome']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              validator: (v) => v == null ? 'Selecione a empresa' : null,
                              onChanged: (v) {
                                setState(() {
                                  _empresaId = v;
                                  final match = _listaEmpresas.firstWhere(
                                      (e) => e['id'] == v,
                                      orElse: () => {});
                                  _empresaNome = match['nome']?.toString();
                                  _parceiroId = null;
                                  _parceiroNome = null;
                                  _listaParceiros = [];
                                });
                                _carregarParceirosDaEmpresa();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 320,
                            child: _carregandoVinculos
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2)),
                                        SizedBox(width: 8),
                                        Text('Carregando parceiros...',
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  )
                                : DropdownButtonFormField<int>(
                                    key: const Key('dropdown_parceiro_fornecedor'),
                                    isExpanded: true,
                                    value: _parceiroId,
                                    decoration: const InputDecoration(
                                      labelText: 'Parceiro Vinculado *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: _listaParceiros.map((p) {
                                      return DropdownMenuItem<int>(
                                        value: p['id'] as int,
                                        child: Text(
                                          '${p['id']} - ${p['nome']}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    validator: (v) =>
                                        v == null ? 'Selecione o parceiro vinculado' : null,
                                    onChanged: (v) {
                                      setState(() {
                                        _parceiroId = v;
                                        final match = _listaParceiros.firstWhere(
                                            (p) => p['id'] == v,
                                            orElse: () => {});
                                        _parceiroNome = match['nome']?.toString();
                                      });
                                    },
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextFormField(
                              key: const Key('input_cep_fornecedor'),
                              controller: _cepCtrl,
                              decoration: const InputDecoration(
                                labelText: 'CEP',
                                hintText: '99999-999',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                if (v.replaceAll(RegExp(r'\D'), '').length == 8) {
                                  _buscarCep();
                                }
                              },
                            ),
                          ),
                          ElevatedButton.icon(
                            key: const Key('btn_buscar_cep_fornecedor'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GridColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            icon: _buscandoCep
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.search, size: 18),
                            label: const Text('Buscar endereço pelo CEP'),
                            onPressed: _buscandoCep ? null : _buscarCep,
                          ),
                        ],
                      ),
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
