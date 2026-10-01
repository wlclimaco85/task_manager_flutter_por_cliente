import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';

/// Aba de cobrança de módulos do parceiro.
/// Grid 3 colunas: modulo (nome), valor_mensal, dia_vencimento.
/// Edição inline: clica valor/dia → ativa TextField → PUT automático ao blur.
class ModuloCobrancaScreen extends StatefulWidget {
  final int parceiroId;
  final String parceiroNome;

  const ModuloCobrancaScreen({
    super.key,
    required this.parceiroId,
    required this.parceiroNome,
  });

  @override
  State<ModuloCobrancaScreen> createState() => _ModuloCobrancaScreenState();
}

class _ModuloCobrancaScreenState extends State<ModuloCobrancaScreen> {
  static const _primary = GridColors.primary;
  static const _success = GridColors.success;
  static const _warning = Color(0xFFF57F17);

  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _modulos = [];

  /// Estado de edição: Map<moduloId, {valor, dia}>
  final Map<int, Map<String, dynamic>> _edicao = {};

  /// Controllers inline por módulo
  final Map<int, TextEditingController> _controllerValor = {};
  final Map<int, TextEditingController> _controllerDia = {};

  @override
  void initState() {
    super.initState();
    _carregarModulos();
  }

  @override
  void dispose() {
    for (final ctrl in _controllerValor.values) ctrl.dispose();
    for (final ctrl in _controllerDia.values) ctrl.dispose();
    super.dispose();
  }

  /// GET /api/parceiro-modulo — carrega módulos do parceiro
  Future<void> _carregarModulos() async {
    if (!mounted) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/parceiro-modulo?parceiroId=${widget.parceiroId}'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final List<dynamic> dados = body is List ? body : (body['data'] ?? body['content'] ?? []);
        if (mounted) {
          setState(() {
            _modulos = dados.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _carregando = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _erro = 'Erro ${resp.statusCode} ao carregar módulos';
            _carregando = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Erro de conexão: $e';
          _carregando = false;
        });
      }
    }
  }

  /// PUT /api/parceiro-modulo/{moduloId} — atualiza valor/dia_vencimento
  Future<void> _salvarModulo(int moduloId, Map<String, dynamic> dados) async {
    try {
      final token = AuthUtility.userInfo?.token;
      final resp = await http.put(
        Uri.parse('${ApiLinks.baseUrl}/api/parceiro-modulo/$moduloId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'parceiroId': widget.parceiroId,
          'valor': dados['valor'] ?? 0.0,
          'diaVencimento': dados['diaVencimento'] ?? 0,
        }),
      );

      if (resp.statusCode == 200) {
        // Sucesso: remove estado de edição, recarrega
        if (mounted) {
          setState(() {
            _edicao.remove(moduloId);
            _controllerValor[moduloId]?.dispose();
            _controllerValor.remove(moduloId);
            _controllerDia[moduloId]?.dispose();
            _controllerDia.remove(moduloId);
          });
        }
        // Recarrega para confirmação
        await _carregarModulos();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: ${resp.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  /// Inicia edição inline de valor
  void _iniciarEdicaoValor(int moduloId, dynamic valor) {
    if (!_edicao.containsKey(moduloId)) {
      _edicao[moduloId] = {'valor': valor, 'diaVencimento': null};
      _controllerValor[moduloId] = TextEditingController(text: valor.toString());
    }
    setState(() {});
    _controllerValor[moduloId]?.selection =
        TextSelection(baseOffset: 0, extentOffset: _controllerValor[moduloId]!.text.length);
  }

  /// Inicia edição inline de dia_vencimento
  void _iniciarEdicaoDia(int moduloId, dynamic dia) {
    if (!_edicao.containsKey(moduloId)) {
      _edicao[moduloId] = {'valor': null, 'diaVencimento': dia};
      _controllerDia[moduloId] = TextEditingController(text: dia.toString());
    }
    setState(() {});
    _controllerDia[moduloId]?.selection =
        TextSelection(baseOffset: 0, extentOffset: _controllerDia[moduloId]!.text.length);
  }

  /// Conclui edição de valor e envia PUT
  Future<void> _finalizarEdicaoValor(int moduloId) async {
    final novoValor = double.tryParse(_controllerValor[moduloId]?.text ?? '') ?? 0.0;
    final modulo = _modulos.firstWhere((m) => m['id'] == moduloId, orElse: () => {});
    await _salvarModulo(moduloId, {
      'valor': novoValor,
      'diaVencimento': modulo['dia_vencimento'] ?? 0,
    });
  }

  /// Conclui edição de dia_vencimento e envia PUT
  Future<void> _finalizarEdicaoDia(int moduloId) async {
    final novoDia = int.tryParse(_controllerDia[moduloId]?.text ?? '') ?? 0;
    final modulo = _modulos.firstWhere((m) => m['id'] == moduloId, orElse: () => {});
    await _salvarModulo(moduloId, {
      'valor': modulo['valor'] ?? 0.0,
      'diaVencimento': novoDia,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(child: Text('Erro: $_erro'));
    }

    if (_modulos.isEmpty) {
      return const Center(child: Text('Nenhum módulo contratado'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: _primary, width: 2)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text('Módulo', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Valor Mensal', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Dia Vencimento', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // Linhas de dados
          ..._modulos.map((modulo) {
            final moduloId = modulo['id'] as int? ?? 0;
            final moduloNome = modulo['nome']?.toString() ?? 'Sem nome';
            final valorAtual = modulo['valor'] ?? 0.0;
            final diaAtual = modulo['dia_vencimento'] ?? 0;

            final emEdicaoValor = _edicao.containsKey(moduloId) && _edicao[moduloId]!['valor'] != null;
            final emEdicaoDia = _edicao.containsKey(moduloId) && _edicao[moduloId]!['diaVencimento'] != null;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                color: emEdicaoValor || emEdicaoDia ? Colors.yellow[50] : Colors.transparent,
              ),
              child: Row(
                children: [
                  // Módulo (não editável)
                  Expanded(flex: 2, child: Text(moduloNome)),
                  // Valor mensal (editável inline)
                  Expanded(
                    flex: 1,
                    child: emEdicaoValor
                        ? Focus(
                            onFocusChange: (hasFocus) {
                              if (!hasFocus) {
                                _finalizarEdicaoValor(moduloId);
                              }
                            },
                            child: TextField(
                              controller: _controllerValor[moduloId],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              autofocus: true,
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _iniciarEdicaoValor(moduloId, valorAtual),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('$valorAtual', style: const TextStyle()),
                            ),
                          ),
                  ),
                  // Dia vencimento (editável inline)
                  Expanded(
                    flex: 1,
                    child: emEdicaoDia
                        ? Focus(
                            onFocusChange: (hasFocus) {
                              if (!hasFocus) {
                                _finalizarEdicaoDia(moduloId);
                              }
                            },
                            child: TextField(
                              controller: _controllerDia[moduloId],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              autofocus: true,
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _iniciarEdicaoDia(moduloId, diaAtual),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('$diaAtual', style: const TextStyle()),
                            ),
                          ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
