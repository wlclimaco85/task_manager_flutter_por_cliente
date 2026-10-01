import 'package:flutter/material.dart';
import '../../utils/api_links.dart';
import '../../services/network_caller.dart';
import '../../utils/app_logger.dart';

class CnabConfigScreen extends StatefulWidget {
  final int? empresaId;
  final int? parceiroId;

  const CnabConfigScreen({super.key, this.empresaId, this.parceiroId});

  @override
  State<CnabConfigScreen> createState() => _CnabConfigScreenState();

  /// O endpoint de contas usa os nomes de filtro do controller (`empresa` e
  /// `parceiro`). Mantemos a montagem aqui para que as telas de detalhe não
  /// repitam um contrato diferente.
  static String buildContasQuery({int? empresaId, int? parceiroId}) {
    final params = <String>[];
    if (empresaId != null && empresaId > 0) {
      params.add('empresa=$empresaId');
    }
    if (parceiroId != null && parceiroId > 0) {
      params.add('parceiro=$parceiroId');
    }
    return params.join('&');
  }

  static List<Map<String, dynamic>> extractContas(dynamic responseBody) {
    dynamic data = responseBody;
    if (data is Map) {
      data = data['data'] ?? data['content'] ?? data['dados'] ?? data['items'];
      if (data is Map) {
        data = data['dados'] ?? data['content'] ?? data['items'];
      }
    }
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Map<String, dynamic> buildContaCadastroPayload({
    required String banco,
    required String agencia,
    required String numero,
    required String descricao,
    required String tipo,
    required String saldoInicial,
    required int empresaId,
    int? parceiroId,
  }) =>
      {
        'banco': banco.trim(),
        'agencia': agencia.trim(),
        'numero': numero.trim(),
        'descricao': descricao.trim(),
        'tipo': tipo,
        'saldoInicial': double.tryParse(saldoInicial.replaceAll(',', '.')) ?? 0,
        'dataAbertura': DateTime.now().toIso8601String().substring(0, 10),
        'empresaId': empresaId,
        if (parceiroId != null) 'parceiroId': parceiroId,
        'ativo': true,
      };
}

class _CnabConfigScreenState extends State<CnabConfigScreen> {
  bool _loading = false;
  List<dynamic> _contasBancarias = [];
  int? _selectedContaId;
  Map<String, dynamic> _config = {};

  final _formKey = GlobalKey<FormState>();
  final _layoutCtrl = TextEditingController();
  final _beneficiarioCtrl = TextEditingController();
  final _carteiraCtrl = TextEditingController();
  final _variacaoCtrl = TextEditingController();
  final _transmissaoCtrl = TextEditingController();
  final _postoCtrl = TextEditingController();
  final _sequencialRemessaCtrl = TextEditingController();
  final _sequencialNossoNumeroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContas();
  }

  Future<void> _loadContas() async {
    setState(() => _loading = true);
    try {
      final query = CnabConfigScreen.buildContasQuery(
        empresaId: widget.empresaId,
        parceiroId: widget.parceiroId,
      );
      if (query.isEmpty) {
        return;
      }
      final res = await NetworkCaller()
          .getRequest('${ApiLinks.contasBancarias}?$query');
      if (res.isSuccess && res.body != null) {
        setState(
            () => _contasBancarias = CnabConfigScreen.extractContas(res.body));
      }
    } catch (e, stack) {
      AppLogger.i.error('Erro ao carregar contas bancárias', stack);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadConfig(int contaId) async {
    setState(() => _loading = true);
    try {
      final res = await NetworkCaller().getRequest(
          '${ApiLinks.baseUrl}/api/conta-bancaria-cnab-config/conta/$contaId');
      if (res.isSuccess && res.body != null) {
        _config = res.body!;
        _layoutCtrl.text = _config['layoutCnab']?.toString() ?? '240';
        _beneficiarioCtrl.text =
            _config['codigoBeneficiario']?.toString() ?? '';
        _carteiraCtrl.text = _config['carteira']?.toString() ?? '';
        _variacaoCtrl.text = _config['variacaoCarteira']?.toString() ?? '';
        _transmissaoCtrl.text = _config['codigoTransmissao']?.toString() ?? '';
        _postoCtrl.text = _config['postoBeneficiario']?.toString() ?? '';
        _sequencialRemessaCtrl.text =
            _config['sequencialRemessa']?.toString() ?? '1';
        _sequencialNossoNumeroCtrl.text =
            _config['sequencialNossoNumero']?.toString() ?? '1';
      }
    } catch (e, stack) {
      AppLogger.i.error('Erro ao carregar config CNAB', stack);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirCadastroConta() async {
    if ((widget.empresaId ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Empresa do parceiro nao identificada para cadastrar a conta.'),
      ));
      return;
    }
    final dados = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _NovaContaBancariaDialog(),
    );
    if (dados == null || !mounted) return;
    setState(() => _loading = true);
    try {
      final payload = CnabConfigScreen.buildContaCadastroPayload(
        banco: dados['banco']!,
        agencia: dados['agencia']!,
        numero: dados['numero']!,
        descricao: dados['descricao']!,
        tipo: dados['tipo']!,
        saldoInicial: dados['saldoInicial']!,
        empresaId: widget.empresaId!,
        parceiroId: widget.parceiroId,
      );
      final result =
          await NetworkCaller().postRequest(ApiLinks.contasBancarias, payload);
      final Map<String, dynamic>? body = result.body;
      final conta = body != null && body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body != null
              ? body
              : null;
      final id = int.tryParse(conta?['id']?.toString() ?? '');
      if (!result.isSuccess || conta == null || id == null) {
        throw StateError(
            'A API nao retornou a conta criada (HTTP ${result.statusCode}).');
      }
      if (!mounted) return;
      setState(() {
        _contasBancarias = [..._contasBancarias, conta];
        _selectedContaId = id;
      });
      await _loadConfig(id);
    } catch (e, stack) {
      AppLogger.i
          .error('Erro ao cadastrar conta bancaria para CNAB: $e', stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nao foi possivel cadastrar a conta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContaId == null) return;

    setState(() => _loading = true);
    try {
      final payload = {
        'layoutCnab': _layoutCtrl.text,
        'codigoBeneficiario': _beneficiarioCtrl.text,
        'carteira': _carteiraCtrl.text,
        'variacaoCarteira': _variacaoCtrl.text,
        'codigoTransmissao': _transmissaoCtrl.text,
        'postoBeneficiario': _postoCtrl.text,
        'sequencialRemessa': int.tryParse(_sequencialRemessaCtrl.text) ?? 1,
        'sequencialNossoNumero':
            int.tryParse(_sequencialNossoNumeroCtrl.text) ?? 1,
      };

      final res = await NetworkCaller().postRequest(
          '${ApiLinks.baseUrl}/api/conta-bancaria-cnab-config/conta/$_selectedContaId',
          payload);
      if (res.isSuccess) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuração salva com sucesso!')));
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao salvar: ${res.statusCode}')));
      }
    } catch (e, stack) {
      AppLogger.i.error('Erro ao salvar config CNAB', stack);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _contasBancarias.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contasBancarias.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nenhuma conta bancaria cadastrada para este registro.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _abrirCadastroConta,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar conta bancaria'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selecione a Conta Bancária',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedContaId,
            items: _contasBancarias.map((c) {
              final id = c['id'] as int;
              final nome = c['descricao'] ?? c['banco'] ?? 'Conta $id';
              return DropdownMenuItem<int>(
                value: id,
                child: Text('$nome (Ag: ${c['agencia']} CC: ${c['numero']})'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedContaId = val);
                _loadConfig(val);
              }
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          if (_selectedContaId != null) ...[
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value:
                            _layoutCtrl.text.isEmpty ? '240' : _layoutCtrl.text,
                        items: const [
                          DropdownMenuItem(
                              value: '240',
                              child: Text(
                                  'CNAB 240 (Banco do Brasil, Sicoob, etc)')),
                          DropdownMenuItem(
                              value: '400',
                              child: Text('CNAB 400 (Itaú, Bradesco, etc)')),
                        ],
                        onChanged: (val) =>
                            setState(() => _layoutCtrl.text = val ?? '240'),
                        decoration: const InputDecoration(
                            labelText: 'Layout CNAB',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _beneficiarioCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Código do Beneficiário / Convênio',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _carteiraCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Carteira',
                                  border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _variacaoCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Variação da Carteira (BB)',
                                  border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _transmissaoCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Código Transmissão (Itaú)',
                                  border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _postoCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Posto Beneficiário (Sicoob)',
                                  border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sequencialRemessaCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Sequencial Atual da Remessa',
                                  border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _sequencialNossoNumeroCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Sequencial Atual Nosso Número',
                                  border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Salvar Configuração CNAB'),
                        onPressed: _loading ? null : _saveConfig,
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _NovaContaBancariaDialog extends StatefulWidget {
  const _NovaContaBancariaDialog();

  @override
  State<_NovaContaBancariaDialog> createState() =>
      _NovaContaBancariaDialogState();
}

class _NovaContaBancariaDialogState extends State<_NovaContaBancariaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _banco = TextEditingController();
  final _agencia = TextEditingController();
  final _numero = TextEditingController();
  final _descricao = TextEditingController();
  final _saldoInicial = TextEditingController(text: '0');
  String _tipo = 'CONTA_CORRENTE';

  @override
  void dispose() {
    _banco.dispose();
    _agencia.dispose();
    _numero.dispose();
    _descricao.dispose();
    _saldoInicial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Cadastrar conta bancaria'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _campo(_banco, 'Banco', obrigatorio: true),
              _campo(_agencia, 'Agencia'),
              _campo(_numero, 'Numero', obrigatorio: true),
              _campo(_descricao, 'Descricao'),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                      value: 'CONTA_CORRENTE', child: Text('Conta corrente')),
                  DropdownMenuItem(value: 'POUPANCA', child: Text('Poupanca')),
                  DropdownMenuItem(value: 'CAIXA', child: Text('Caixa')),
                  DropdownMenuItem(value: 'CARTEIRA', child: Text('Carteira')),
                  DropdownMenuItem(
                      value: 'INVESTIMENTO', child: Text('Investimento')),
                ],
                onChanged: (value) => setState(() => _tipo = value ?? _tipo),
              ),
              _campo(_saldoInicial, 'Saldo inicial',
                  obrigatorio: true,
                  teclado:
                      const TextInputType.numberWithOptions(decimal: true)),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, {
                'banco': _banco.text,
                'agencia': _agencia.text,
                'numero': _numero.text,
                'descricao': _descricao.text,
                'tipo': _tipo,
                'saldoInicial': _saldoInicial.text,
              });
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar conta'),
          ),
        ],
      );

  Widget _campo(TextEditingController controller, String label,
          {bool obrigatorio = false, TextInputType? teclado}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: controller,
          keyboardType: teclado,
          decoration: InputDecoration(labelText: label),
          validator: obrigatorio
              ? (value) => value == null || value.trim().isEmpty
                  ? 'Informe $label.'
                  : null
              : null,
        ),
      );
}
