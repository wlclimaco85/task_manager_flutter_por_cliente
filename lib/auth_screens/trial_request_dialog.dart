import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';

class TrialRequestDialog extends StatefulWidget {
  const TrialRequestDialog({super.key});

  @override
  State<TrialRequestDialog> createState() => _TrialRequestDialogState();
}

class _TrialRequestDialogState extends State<TrialRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _localizacaoController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _papelSelecionado;
  final List<String> _papeis = [
    'Sócio / Proprietário',
    'Diretor',
    'Gerente',
    'Funcionário',
    'Outro'
  ];

  List<Map<String, dynamic>> _modulosDisponiveis = [];
  String _termoContrato = '';
  bool _isLoadingData = true;


  
  final Set<String> _modulosSelecionados = {};
  bool _aceitouTermo = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final modulosRes = await http.get(Uri.parse('${ApiLinks.baseUrl}/api/public/modulos'));
      if (modulosRes.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(modulosRes.bodyBytes));
        if (mounted) {
          setState(() {
            _modulosDisponiveis = data.map((e) => e as Map<String, dynamic>).toList();
          });
        }
      }

      final termoRes = await http.get(Uri.parse('${ApiLinks.baseUrl}/api/public/termo-contrato/ativo'));
      if (termoRes.statusCode == 200) {
        final data = jsonDecode(utf8.decode(termoRes.bodyBytes));
        if (mounted) {
          setState(() {
            _termoContrato = data['conteudo'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados iniciais: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }


  Future<void> _fetchLocation() async {
    try {
      final response = await http.get(Uri.parse('https://ipwho.is/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['city'] != null && data['region_code'] != null) {
          if (mounted) {
            setState(() {
              _localizacaoController.text = '${data['city']}/${data['region_code']}';
            });
          }
        }
      }
    } catch (e) {
      // Ignora erro e mantém vazio para não travar o form
    }
  }

  double get _valorTotal {
    double total = 0.0;
    for (var nome in _modulosSelecionados) {
      final mod = _modulosDisponiveis.firstWhere((m) => m['nome'] == nome, orElse: () => {});
      if (mod.isNotEmpty && mod['valorMensal'] != null) {
        total += (mod['valorMensal'] as num).toDouble();
      }
    }
    return total;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modulosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um módulo.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!_aceitouTermo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve aceitar o Contrato de Prestação de Serviço.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      "cpf": _cpfController.text.trim(),
      "localizacao": _localizacaoController.text.trim(),
      "cnpj": _cnpjController.text.trim(),
      "nome": _nomeController.text.trim(),
      "email": _emailController.text.trim(),
      "papel": _papelSelecionado ?? '',
      "modulos": _modulosSelecionados.toList(),
      "contratoTextoAceito": _termoContrato,
      "valorTotal": _valorTotal,
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiLinks.baseUrl}/api/public/trial-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close the form dialog
        
        // Show explicit alert that it is pending approval
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Solicitação Enviada'),
            content: const Text(
              'Sua solicitação foi enviada com sucesso e está aguardando aprovação.\n\n'
              'Você receberá um retorno em breve.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar solicitação: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _localizacaoController.dispose();
    _cnpjController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const SizedBox(
          width: 600,
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: GridColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Experimente nossos pacotes',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWarningBanner(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(labelText: 'Nome completo *', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cpfController,
                              decoration: const InputDecoration(labelText: 'CPF *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cnpjController,
                              decoration: const InputDecoration(labelText: 'CNPJ da Empresa *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _papelSelecionado,
                              decoration: const InputDecoration(labelText: 'Papel na empresa *', border: OutlineInputBorder()),
                              items: _papeis.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (v) => setState(() => _papelSelecionado = v),
                              validator: (v) => v == null ? 'Campo obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _localizacaoController,
                              decoration: const InputDecoration(labelText: 'Localização (Cidade/UF)', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Selecione os módulos desejados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _modulosDisponiveis.map((mapItem) {
                          final m = mapItem['nome'] as String;
                          final isSelected = _modulosSelecionados.contains(m);
                          return FilterChip(
                            label: Text(m),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _modulosSelecionados.add(m);
                                } else {
                                  _modulosSelecionados.remove(m);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Valor Total Estimado:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('R\$ ${_valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: GridColors.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Termo de Contrato de Prestação de Serviço de Software:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: SingleChildScrollView(
                          child: Text(_termoContrato, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text('Aceito os termos do contrato e estou ciente do período de teste.'),
                        value: _aceitouTermo,
                        onChanged: (v) => setState(() => _aceitouTermo = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Enviar Solicitação e Iniciar Teste', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade600),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Você tem 30 dias grátis para testar! A cobrança será realizada apenas após esse período. '
              'Você pode cancelar sua assinatura a qualquer momento.',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}


