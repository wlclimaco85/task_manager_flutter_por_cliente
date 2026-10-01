import 'dart:io';
import '../../widgets/user_banners.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/services/network_caller.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/widgets/edit_form_helpers.dart';
import 'package:task_manager_flutter/widgets/searchable_dropdown.dart';

class ParceiroEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const ParceiroEditScreen({super.key, required this.initialData});

  @override
  State<ParceiroEditScreen> createState() => _ParceiroEditScreenState();
}

class _ParceiroEditScreenState extends State<ParceiroEditScreen> {
  final _formKey = GlobalKey<FormState>();

  File? _logo;
  String? _logoBase64;
  bool _imageTooLarge = false;

  late TextEditingController _nome;
  late TextEditingController _cpf;
  late TextEditingController _telefone1;
  late TextEditingController _telefone2;
  late TextEditingController _email;
  late TextEditingController _razaoSocial;
  late TextEditingController _incrMun;
  late TextEditingController _observacao;
  late TextEditingController _valorMensal;
  late TextEditingController _ie;
  late TextEditingController _logradouro;
  late TextEditingController _numero;
  late TextEditingController _cep;
  late TextEditingController _bairro;

  List<PaisModel> _paises = [];
  List<EstadoModel> _estados = [];
  List<CidadeModel> _cidades = [];
  PaisModel? _paisSelecionado;
  EstadoModel? _estadoSelecionado;
  CidadeModel? _cidadeSelecionada;

  bool _loadingEstados = false;
  bool _loadingCidades = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nome = TextEditingController(text: safeToString(d['nome']));
    _cpf = TextEditingController(text: safeToString(d['cpf']));
    _telefone1 = TextEditingController(text: safeToString(d['telefone1']));
    _telefone2 = TextEditingController(text: safeToString(d['telefone2']));
    _email = TextEditingController(text: safeToString(d['email']));
    _razaoSocial = TextEditingController(text: safeToString(d['razaoSocial']));
    _incrMun = TextEditingController(text: safeToString(d['incrMun']));
    _observacao = TextEditingController(text: safeToString(d['observacao']));
    _valorMensal = TextEditingController(text: safeToString(d['valorMensal']));
    _ie = TextEditingController(text: safeToString(d['ie']));

    final end = (d['endereco'] is Map<String, dynamic>)
        ? d['endereco'] as Map<String, dynamic>
        : <String, dynamic>{};
    _logradouro = TextEditingController(text: safeToString(end['logradouro']));
    _numero = TextEditingController(text: safeToString(end['numero']));
    _cep = TextEditingController(text: safeToString(end['cep']));
    _bairro = TextEditingController(text: safeToString(end['bairro']));

    final paisId = safeToInt(end['paisId'] ?? d['paisId']);
    final estadoId = safeToInt(end['estadoId'] ?? d['estadoId']);
    final cidadeId = safeToInt(end['cidadeId'] ?? d['cidadeId']);
    _bootstrap(paisId, estadoId, cidadeId);
  }

  Future<void> _bootstrap(int? paisId, int? estadoId, int? cidadeId) async {
    _paises = await fetchPaises();
    if (paisId != null) {
      _paisSelecionado = _paises.firstWhere(
        (p) => p.id == paisId,
        orElse: () => PaisModel(id: 0, nome: ''),
      );
      if (_paisSelecionado!.id != 0) {
        setState(() => _loadingEstados = true);
        _estados = await fetchEstados(_paisSelecionado!.id);
        setState(() => _loadingEstados = false);
        if (estadoId != null) {
          _estadoSelecionado = _estados.firstWhere(
            (e) => e.id == estadoId,
            orElse: () => EstadoModel(id: 0, nome: '', paisId: 0),
          );
          if (_estadoSelecionado!.id != 0) {
            setState(() => _loadingCidades = true);
            _cidades = await fetchCidades(_estadoSelecionado!.id);
            setState(() => _loadingCidades = false);
            if (cidadeId != null) {
              _cidadeSelecionada = _cidades.firstWhere(
                (c) => c.id == cidadeId,
                orElse: () => CidadeModel(id: 0, nome: '', estadoId: 0),
              );
            }
          }
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickLogo(dynamic src) async {
    final (file, base64Str) = await pickImageWithValidation(src);
    if (base64Str == 'LIMITE_EXCEDIDO') {
      setState(() => _imageTooLarge = true);
      return;
    }
    if (file != null) {
      setState(() { _logo = file; _logoBase64 = base64Str; _imageTooLarge = false; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      double? valorMensal;
      final rawValor = _valorMensal.text.replaceAll('.', '').replaceAll(',', '.').trim();
      if (rawValor.isNotEmpty) valorMensal = double.tryParse(rawValor);

      final endereco = {
        'logradouro': _logradouro.text.trim(),
        'numero': _numero.text.trim(),
        'cep': _cep.text.trim(),
        'bairro': _bairro.text.trim(),
        'paisId': _paisSelecionado?.id,
        'estadoId': _estadoSelecionado?.id,
        'cidadeId': _cidadeSelecionada?.id,
      };

      final req = {
        'id': safeToInt(widget.initialData['id']),
        'nome': _nome.text.trim(),
        'cpf': _cpf.text.trim(),
        'telefone1': _telefone1.text.trim(),
        'telefone2': _telefone2.text.trim(),
        'email': _email.text.trim(),
        'razaoSocial': _razaoSocial.text.trim(),
        'incrMun': _incrMun.text.trim(),
        'observacao': _observacao.text.trim(),
        'valorMensal': valorMensal,
        'ie': _ie.text.trim(),
        'endereco': endereco,
        'logoBase64': _logoBase64 ?? '',
      };

      final resp = await NetworkCaller()
          .postRequest(ApiLinks.updateParceiro(widget.initialData['id']), req);

      if (!mounted) return;
      Navigator.pop(context);

      if (resp.isSuccess) {
        Navigator.pop(context, req);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Parceiro atualizado!'),
          backgroundColor: GridColors.success,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: ${resp.body ?? "Falha ao atualizar"}'),
          backgroundColor: GridColors.error,
        ));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar: $e'),
        backgroundColor: GridColors.error,
      ));
    }
  }

  @override
  void dispose() {
    _nome.dispose(); _cpf.dispose(); _telefone1.dispose(); _telefone2.dispose();
    _email.dispose(); _razaoSocial.dispose(); _incrMun.dispose();
    _observacao.dispose(); _valorMensal.dispose(); _ie.dispose();
    _logradouro.dispose(); _numero.dispose(); _cep.dispose(); _bairro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: UserBannerAppBar(
        screenTitle: 'Editar Parceiro',
        showBackButton: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Card(
            color: GridColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  EditableImageCircle(
                    file: _logo,
                    imageUrl: widget.initialData['logo'],
                    placeholderIcon: Icons.business,
                    onTap: () => showImageSourceDialog(context, _pickLogo),
                  ),
                  if (_imageTooLarge)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('⚠️ A imagem deve ter no máximo 2MB',
                          style: TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  const SizedBox(height: 24),
                  buildTextField('Nome *', _nome, required: true),
                  buildTextField('CPF', _cpf, type: TextInputType.number),
                  buildTextField('Telefone 1', _telefone1, type: TextInputType.phone),
                  buildTextField('Telefone 2', _telefone2, type: TextInputType.phone),
                  buildTextField('Email', _email, type: TextInputType.emailAddress),
                  buildTextField('Razão Social', _razaoSocial),
                  buildTextField('Inscrição Municipal', _incrMun),
                  buildTextField('IE', _ie, type: TextInputType.number),
                  buildTextField('Valor Mensal', _valorMensal, type: TextInputType.number),
                  buildTextField('Observação', _observacao),
                  buildTextField('Logradouro', _logradouro),
                  Row(children: [
                    Expanded(child: buildTextField('Número', _numero)),
                    const SizedBox(width: 12),
                    Expanded(child: buildTextField('CEP', _cep, type: TextInputType.number)),
                  ]),
                  buildTextField('Bairro', _bairro),
                  const SizedBox(height: 16),
                  _buildPaisDropdown(),
                  const SizedBox(height: 12),
                  _buildEstadoDropdown(),
                  const SizedBox(height: 12),
                  _buildCidadeDropdown(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.buttonBackground,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('SALVAR ALTERAÇÕES',
                        style: TextStyle(color: GridColors.buttonText, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaisDropdown() => SearchableDropdownField(
        label: 'País',
        value: _paisSelecionado?.id.toString(),
        items: _paises
            .map((p) => <String, dynamic>{'id': p.id.toString() ?? '', 'nome': p.nome ?? ''})
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        nullable: true,
        nullLabel: 'Limpar seleção',
        onChanged: (v) async {
          final pais = v != null
              ? _paises.firstWhere((p) => p.id.toString() == v,
                  orElse: () => PaisModel(id: 0, nome: ''))
              : null;
          setState(() {
            _paisSelecionado = (pais?.id ?? 0) != 0 ? pais : null;
            _estadoSelecionado = null; _cidadeSelecionada = null;
            _estados = []; _cidades = [];
            _loadingEstados = pais != null && (pais.id ?? 0) != 0;
          });
          if (pais != null && (pais.id ?? 0) != 0) {
            _estados = await fetchEstados(pais.id);
            if (mounted) setState(() => _loadingEstados = false);
          }
        },
      );

  Widget _buildEstadoDropdown() => SearchableDropdownField(
        label: _loadingEstados ? 'Estado (carregando...)' : 'Estado',
        value: _estadoSelecionado?.id.toString(),
        items: _estados
            .map((e) => <String, dynamic>{'id': e.id.toString() ?? '', 'nome': e.nome ?? ''})
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        enabled: !_loadingEstados && _estados.isNotEmpty,
        nullable: true,
        nullLabel: 'Limpar seleção',
        onChanged: (v) async {
          final estado = v != null
              ? _estados.firstWhere((e) => e.id.toString() == v,
                  orElse: () => EstadoModel(id: 0, nome: '', paisId: 0))
              : null;
          setState(() {
            _estadoSelecionado = (estado?.id ?? 0) != 0 ? estado : null;
            _cidadeSelecionada = null; _cidades = [];
            _loadingCidades = estado != null && (estado.id ?? 0) != 0;
          });
          if (estado != null && (estado.id ?? 0) != 0) {
            _cidades = await fetchCidades(estado.id);
            if (mounted) setState(() => _loadingCidades = false);
          }
        },
      );

  Widget _buildCidadeDropdown() => SearchableDropdownField(
        label: _loadingCidades ? 'Cidade (carregando...)' : 'Cidade',
        value: _cidadeSelecionada?.id.toString(),
        items: _cidades
            .map((c) => <String, dynamic>{'id': c.id.toString() ?? '', 'nome': c.nome ?? ''})
            .toList(),
        valueField: 'id',
        displayField: 'nome',
        enabled: !_loadingCidades && _cidades.isNotEmpty,
        nullable: true,
        nullLabel: 'Limpar seleção',
        onChanged: (v) {
          final cidade = v != null
              ? _cidades.firstWhere((c) => c.id.toString() == v,
                  orElse: () => CidadeModel(id: 0, nome: '', estadoId: 0))
              : null;
          setState(() => _cidadeSelecionada = (cidade?.id ?? 0) != 0 ? cidade : null);
        },
      );
}
