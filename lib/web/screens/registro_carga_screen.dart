import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

/// Tela de Registro de Carga — acompanhamento de séries da sessão de treino.
/// Carrega exercícios planejados via GET /api/sessoes-treino/{sessionId}
/// Salva séries executadas via POST /api/sessoes-treino/{sessionId}/series
class RegistroCargaScreen extends StatefulWidget {
  final int sessionId;

  const RegistroCargaScreen({super.key, required this.sessionId});

  @override
  State<RegistroCargaScreen> createState() => _RegistroCargaScreenState();
}

class _RegistroCargaScreenState extends State<RegistroCargaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _carregando = true;
  bool _salvando = false;
  String? _erroCarregamento;

  // ── Estado da sessão e exercícios ──────────────────────────────────────────
  String? _nomeExercicioAtual;
  List<Map<String, dynamic>> _exerciciosPlanos = [];
  int _indiceAtual = 0;

  // ── Controladores do formulário ────────────────────────────────────────────
  final _pesoCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _duracaoCtrl = TextEditingController();

  // ── Séries registradas localmente ─────────────────────────────────────────
  final List<Map<String, dynamic>> _seriesRegistradas = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _repsCtrl.dispose();
    _duracaoCtrl.dispose();
    super.dispose();
  }

  /// Carrega exercícios planejados da sessão via API
  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/sessoes-treino/${widget.sessionId}');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final data = body['data'] ?? body;

        if (data is Map && data['series'] is List) {
          // Agrupa séries por exercício para exibir todos em ordem
          final List<dynamic> seriesData = data['series'] as List<dynamic>;
          final Map<String, List<Map<String, dynamic>>> agrupadoPorExercicio = {};

          for (var serie in seriesData) {
            final nomeExercicio = serie['exercicio']?['nome'] ?? 'Exercício desconhecido';
            if (!agrupadoPorExercicio.containsKey(nomeExercicio)) {
              agrupadoPorExercicio[nomeExercicio] = [];
            }
            agrupadoPorExercicio[nomeExercicio]!.add({
              'nome': nomeExercicio,
              'numeroSerie': serie['numeroSerie'],
              'pesoPlano': serie['peso'],
              'repsPlano': serie['repeticoes'],
              'exercicioId': serie['exercicio']?['id'],
            });
          }

          _exerciciosPlanos = agrupadoPorExercicio.entries
              .expand((e) => e.value)
              .toList();

          if (_exerciciosPlanos.isNotEmpty) {
            _nomeExercicioAtual = _exerciciosPlanos[0]['nome'];
          }
        }
      } else if (resp.statusCode == 404) {
        setState(() => _erroCarregamento = 'Sessão não encontrada.');
      } else {
        setState(() => _erroCarregamento = 'Erro ao carregar (${resp.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erroCarregamento = 'Erro: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  /// Valida e registra uma série na lista local
  void _proximaSerie() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios.')),
      );
      return;
    }

    final peso = double.tryParse(_pesoCtrl.text.trim()) ?? 0;
    final reps = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    final duracao = _duracaoCtrl.text.trim();

    if (peso <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso deve ser maior que 0.')),
      );
      return;
    }

    if (reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reps deve ser maior que 0.')),
      );
      return;
    }

    // Registra a série
    _seriesRegistradas.add({
      'exercicio': _nomeExercicioAtual,
      'numeroSerie': _exerciciosPlanos[_indiceAtual]['numeroSerie'],
      'peso': peso,
      'repeticoes': reps,
      'duracao': duracao.isNotEmpty ? duracao : null,
      'exercicioId': _exerciciosPlanos[_indiceAtual]['exercicioId'],
    });

    // Avança para o próximo exercício
    if (_indiceAtual + 1 < _exerciciosPlanos.length) {
      setState(() {
        _indiceAtual++;
        _nomeExercicioAtual = _exerciciosPlanos[_indiceAtual]['nome'];
        _pesoCtrl.clear();
        _repsCtrl.clear();
        _duracaoCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Série registrada! Próxima: $_nomeExercicioAtual')),
      );
    } else {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Última série registrada. Finalize para salvar.')),
      );
    }
  }

  /// Envia todas as séries ao backend
  Future<void> _finalizar() async {
    if (_seriesRegistradas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registre ao menos uma série.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/sessoes-treino/${widget.sessionId}/series');
      final token = AuthUtility.userInfo?.token;
      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final payload = {
        'series': _seriesRegistradas,
      };

      final resp = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      setState(() => _salvando = false);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão finalizada e salva com sucesso!'),
            backgroundColor: Color(0xFF388E3C),
          ),
        );
        // Retorna à tela anterior
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar (${resp.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  /// Widget do campo de entrada
  Widget _campo(String label, TextEditingController ctrl,
      {String? hint, TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: GridColors.textSecondary),
          filled: true,
          fillColor: readOnly ? GridColors.disabledBackground : GridColors.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: GridColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: GridColors.secondary, width: 2),
          ),
        ),
        validator: (value) {
          if (label.contains('Peso') || label.contains('Reps')) {
            if (value == null || value.isEmpty) {
              return 'Campo obrigatório';
            }
            if (label.contains('Peso')) {
              final peso = double.tryParse(value);
              if (peso == null || peso <= 0) {
                return 'Peso deve ser maior que 0';
              }
            } else if (label.contains('Reps')) {
              final reps = int.tryParse(value);
              if (reps == null || reps <= 0) {
                return 'Reps deve ser maior que 0';
              }
            }
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Carga'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erroCarregamento != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: GridColors.error),
                        const SizedBox(height: 16),
                        Text(_erroCarregamento!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Voltar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _exerciciosPlanos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline,
                                size: 64, color: GridColors.textSecondary),
                            const SizedBox(height: 16),
                            const Text('Nenhum exercício planejado para esta sessão.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Voltar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Indicador de progresso ─────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: GridColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: GridColors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Série ${_indiceAtual + 1} de ${_exerciciosPlanos.length}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: GridColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _nomeExercicioAtual ?? 'Carregando...',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: GridColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Formulário de preenchimento ────────────────────────────
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Exercício (readonly)
                                _campo(
                                  'Exercício',
                                  TextEditingController(text: _nomeExercicioAtual),
                                  readOnly: true,
                                ),

                                // Peso
                                _campo(
                                  'Peso (kg)',
                                  _pesoCtrl,
                                  hint: 'Ex: 20.5',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                ),

                                // Reps
                                _campo(
                                  'Reps',
                                  _repsCtrl,
                                  hint: 'Ex: 12',
                                  keyboardType: TextInputType.number,
                                ),

                                // Duração (opcional)
                                _campo(
                                  'Duração (opcional)',
                                  _duracaoCtrl,
                                  hint: 'Ex: 2m30s',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Botões de ação ────────────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Próxima série'),
                                  onPressed: _proximaSerie,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GridColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: _salvando
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: const Text('Finalizar'),
                                  onPressed: _salvando ? null : _finalizar,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GridColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Lista de séries registradas ────────────────────────────
                          if (_seriesRegistradas.isNotEmpty) ...[
                            const Divider(height: 32),
                            const Text(
                              'Séries Registradas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: GridColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _seriesRegistradas.length,
                              itemBuilder: (ctx, idx) {
                                final serie = _seriesRegistradas[idx];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: GridColors.success,
                                      foregroundColor: Colors.white,
                                      child: Text('${idx + 1}'),
                                    ),
                                    title: Text(serie['exercicio'] ?? '—'),
                                    subtitle: Text(
                                      '${serie['peso']} kg × ${serie['repeticoes']} reps${serie['duracao'] != null ? ' • ${serie['duracao']}' : ''}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: GridColors.error),
                                      onPressed: () {
                                        setState(() {
                                          _seriesRegistradas.removeAt(idx);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}
