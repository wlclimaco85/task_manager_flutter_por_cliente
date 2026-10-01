import 'package:flutter/material.dart';
import '../../../services/regra_fiscal_caller.dart';
import '../../../utils/grid_colors.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType;
import '../../../customization/dynamic_grid_windows_screen.dart';

class RegraFiscalScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  const RegraFiscalScreen({super.key, required this.hasPermission});

  @override
  State<RegraFiscalScreen> createState() => _RegraFiscalScreenState();
}

class _RegraFiscalScreenState extends State<RegraFiscalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          color: GridColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.rule, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Regras Fiscais Avançadas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 280,
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Regras'),
                    Tab(text: 'Validação Manual'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildGridTab(),
              _buildValidacaoTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridTab() {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'regra_fiscal',
      hasPermission: widget.hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      showAppBar: false,
      fieldOverrides: const [
        FieldConfigWindows(
          fieldName: 'descricao',
          label: 'Descrição',
          isInForm: true,
          isFilterable: true,
        ),
        FieldConfigWindows(
          fieldName: 'regra',
          label: 'Regra (JSON)',
          isInForm: true,
          fieldType: FieldType.multiline,
          maxLines: 4,
        ),
        FieldConfigWindows(
          fieldName: 'aplicavelPara',
          label: 'Aplicável Para',
          isInForm: true,
          fieldType: FieldType.dropdown,
          dropdownOptions: [
            {'value': 'TODOS', 'label': 'Todos'},
            {'value': 'CLIENTE', 'label': 'Cliente'},
            {'value': 'FORNECEDOR', 'label': 'Fornecedor'},
            {'value': 'PRODUTO', 'label': 'Produto'},
            {'value': 'SERVICO', 'label': 'Serviço'},
          ],
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
        ),
        FieldConfigWindows(
          fieldName: 'tipo',
          label: 'Tipo',
          isInForm: true,
          fieldType: FieldType.dropdown,
          dropdownOptions: [
            {'value': 'TRIBUTACAO', 'label': 'Tributação'},
            {'value': 'ALIQUOTA', 'label': 'Alíquota'},
            {'value': 'RETENCAO', 'label': 'Retenção'},
            {'value': 'BENEFICIO', 'label': 'Benefício'},
            {'value': 'OBRIGACAO', 'label': 'Obrigação Acessória'},
          ],
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
        ),
        FieldConfigWindows(
          fieldName: 'ativo',
          label: 'Ativo',
          fieldType: FieldType.boolean,
          isInForm: true,
          isFilterable: true,
        ),
      ],
    );
  }

  Widget _buildValidacaoTab() {
    return _ValidacaoManualForm();
  }
}

class _ValidacaoManualForm extends StatefulWidget {
  @override
  State<_ValidacaoManualForm> createState() => _ValidacaoManualFormState();
}

class _ValidacaoManualFormState extends State<_ValidacaoManualForm> {
  final _formKey = GlobalKey<FormState>();
  final _cnpjCpfController = TextEditingController();
  final _ufController = TextEditingController();
  final _valorController = TextEditingController();
  String? _regraFiscalId;
  Map<String, dynamic>? _resultado;
  bool _loading = false;
  List<Map<String, dynamic>> _regras = [];
  bool _loadingRegras = false;

  @override
  void initState() {
    super.initState();
    _carregarRegras();
  }

  @override
  void dispose() {
    _cnpjCpfController.dispose();
    _ufController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _carregarRegras() async {
    setState(() => _loadingRegras = true);
    final res = await RegraFiscalCaller.listar();
    if (res.isSuccess && res.body != null) {
      final data = res.body!['data'] ?? res.body!['dados'] ?? [];
      if (data is List) {
        setState(() => _regras = data.cast<Map<String, dynamic>>());
      }
    }
    setState(() => _loadingRegras = false);
  }

  Future<void> _validar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _resultado = null;
    });
    final body = <String, dynamic>{
      'cnpjCpf': _cnpjCpfController.text,
      'uf': _ufController.text.toUpperCase(),
      'valor': double.tryParse(_valorController.text) ?? 0,
    };
    if (_regraFiscalId != null && _regraFiscalId!.isNotEmpty) {
      body['regraFiscalId'] = int.tryParse(_regraFiscalId!);
    }
    final res = await RegraFiscalCaller.validar(body);
    if (res.isSuccess && res.body != null) {
      setState(() => _resultado = res.body);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao validar regra fiscal')),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Validar Regra Fiscal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Informe os dados abaixo para simular a aplicação das regras fiscais cadastradas.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _regraFiscalId,
                decoration: const InputDecoration(
                  labelText: 'Regra Fiscal (opcional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as regras'),
                  ),
                  ..._regras.map((r) => DropdownMenuItem(
                        value: r['id']?.toString(),
                        child: Text(r['descricao']?.toString() ?? ''),
                      )),
                ],
                onChanged: (v) => setState(() => _regraFiscalId = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cnpjCpfController,
                decoration: const InputDecoration(
                  labelText: 'CNPJ/CPF',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ufController,
                decoration: const InputDecoration(
                  labelText: 'UF',
                  border: OutlineInputBorder(),
                  hintText: 'SP',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 2,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _validar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Validar', style: TextStyle(fontSize: 16)),
                ),
              ),
              if (_resultado != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _resultado!['valido'] == true
                        ? GridColors.secondaryLight
                        : GridColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _resultado!['valido'] == true
                          ? GridColors.success
                          : GridColors.error,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _resultado!['valido'] == true
                                ? Icons.check_circle
                                : Icons.error,
                            color: _resultado!['valido'] == true
                                ? GridColors.success
                                : GridColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _resultado!['valido'] == true
                                ? 'Regra válida'
                                : 'Regra inválida',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _resultado!['valido'] == true
                                  ? GridColors.success
                                  : GridColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _resultado!['mensagem']?.toString() ??
                            _resultado!.toString(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
