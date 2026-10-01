import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/grid_texts.dart';
import '../../../utils/tenant_context.dart';

class TradingConfigScreen extends StatefulWidget {
  const TradingConfigScreen({super.key});

  @override
  State<TradingConfigScreen> createState() => _TradingConfigScreenState();
}

class _TradingConfigScreenState extends State<TradingConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenantController =
      TextEditingController(text: TenantContext.empresaId?.toString() ?? '');
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _accountController = TextEditingController();

  String _ambiente = 'TESTE';
  bool _ativo = true;
  bool _loading = true;
  bool _saving = false;
  bool _hasPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tenantController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Uri _uri() {
    final tenantText = _tenantController.text.trim();
    final base = Uri.parse(ApiLinks.tradingBrokerConfig);
    if (tenantText.isEmpty) return base;
    return base.replace(queryParameters: {
      ...base.queryParameters,
      'empId': tenantText,
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(_uri(), headers: TenantContext.headers);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _loginController.text = data['brokerLogin']?.toString() ?? '';
          _accountController.text = data['accountId']?.toString() ?? '';
          _ambiente = data['ambientePadrao']?.toString() ?? 'TESTE';
          _ativo = data['ativo'] != false;
          _hasPassword = data['hasBrokerPassword'] == true;
          _loading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() => _loading = false);
      } else {
        setState(() {
          _error =
              'Erro ao carregar configuracao (${response.statusCode}): ${response.body}';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar configuracao: $e';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'brokerLogin': _loginController.text.trim(),
      'accountId': int.parse(_accountController.text.trim()),
      'ambientePadrao': _ambiente,
      'ativo': _ativo,
    };
    final password = _passwordController.text.trim();
    if (password.isNotEmpty) body['brokerPassword'] = password;

    try {
      final response = await http.put(
        _uri(),
        headers: TenantContext.jsonHeaders,
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GridColors.success,
            content: const Text('Configuracao de trading salva.'),
          ),
        );
        await _load();
      } else {
        setState(() {
          _error = 'Erro ao salvar (${response.statusCode}): ${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuracao da Corretora'),
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _tenantController,
                        decoration: const InputDecoration(
                          labelText: 'Empresa / Tenant ID',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe a empresa/tenant'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _loginController,
                        decoration: const InputDecoration(
                          labelText: 'Login da corretora',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Informe o login'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _hasPassword
                              ? 'Senha da corretora (preencha para trocar)'
                              : 'Senha da corretora',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (!_hasPassword &&
                              (value == null || value.trim().isEmpty)) {
                            return GridTexts.tradingPasswordFirstConfig;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _accountController,
                        decoration: const InputDecoration(
                          labelText: 'Conta / Account ID',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          return parsed == null || parsed <= 0
                              ? 'Informe uma conta valida'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _ambiente,
                        decoration: const InputDecoration(
                          labelText: 'Ambiente padrao',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'TESTE', child: Text('TESTE')),
                          DropdownMenuItem(
                              value: 'PRODUCAO', child: Text('PRODUCAO')),
                        ],
                        onChanged: (value) =>
                            setState(() => _ambiente = value ?? 'TESTE'),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _ativo,
                        onChanged: (value) => setState(() => _ativo = value),
                        title: const Text('Configuracao ativa'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Salvar configuracao'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
