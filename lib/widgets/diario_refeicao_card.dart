import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/api_links.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';
import 'package:http/http.dart' as http;

/// Modelo de uma refeição do diário nutricional
class DiarioRefeicaoModel {
  final int? id;
  final int alunoId;
  final String data;
  final String? horario;
  final String? nomeRefeicao;
  final String? alimentos;
  final double totalCalorias;
  final double totalProteinas;
  final double totalCarboidratos;
  final double totalGorduras;
  final String? fotoUrl;

  DiarioRefeicaoModel({
    this.id,
    required this.alunoId,
    required this.data,
    this.horario,
    this.nomeRefeicao,
    this.alimentos,
    this.totalCalorias = 0.0,
    this.totalProteinas = 0.0,
    this.totalCarboidratos = 0.0,
    this.totalGorduras = 0.0,
    this.fotoUrl,
  });

  factory DiarioRefeicaoModel.fromJson(Map<String, dynamic> json) {
    return DiarioRefeicaoModel(
      id: json['id'],
      alunoId: json['alunoId'] ?? 0,
      data: json['data'] ?? '',
      horario: json['horario'],
      nomeRefeicao: json['nomeRefeicao'],
      alimentos: json['alimentos'],
      totalCalorias: (json['totalCalorias'] ?? 0).toDouble(),
      totalProteinas: (json['totalProteinas'] ?? 0).toDouble(),
      totalCarboidratos: (json['totalCarboidratos'] ?? 0).toDouble(),
      totalGorduras: (json['totalGorduras'] ?? 0).toDouble(),
      fotoUrl: json['fotoUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'alunoId': alunoId,
        'data': data,
        if (horario != null) 'horario': horario,
        if (nomeRefeicao != null) 'nomeRefeicao': nomeRefeicao,
        if (alimentos != null) 'alimentos': alimentos,
        'totalCalorias': totalCalorias,
        'totalProteinas': totalProteinas,
        'totalCarboidratos': totalCarboidratos,
        'totalGorduras': totalGorduras,
        if (fotoUrl != null) 'fotoUrl': fotoUrl,
      };
}

/// Resumo diário de macronutrientes
class ResumoDiarioModel {
  final List<DiarioRefeicaoModel> refeicoes;
  final double totalCalorias;
  final double totalProteinas;
  final double totalCarboidratos;
  final double totalGorduras;

  const ResumoDiarioModel({
    required this.refeicoes,
    required this.totalCalorias,
    required this.totalProteinas,
    required this.totalCarboidratos,
    required this.totalGorduras,
  });

  factory ResumoDiarioModel.fromRefeicoes(List<DiarioRefeicaoModel> lista) {
    double calorias = 0, proteinas = 0, carbo = 0, gorduras = 0;
    for (final r in lista) {
      calorias += r.totalCalorias;
      proteinas += r.totalProteinas;
      carbo += r.totalCarboidratos;
      gorduras += r.totalGorduras;
    }
    return ResumoDiarioModel(
      refeicoes: lista,
      totalCalorias: calorias,
      totalProteinas: proteinas,
      totalCarboidratos: carbo,
      totalGorduras: gorduras,
    );
  }
}

/// Card de diário nutricional — exibe resumo de hoje e lista de refeições.
class DiarioRefeicaoCard extends StatefulWidget {
  final int alunoId;

  const DiarioRefeicaoCard({super.key, required this.alunoId});

  @override
  State<DiarioRefeicaoCard> createState() => _DiarioRefeicaoCardState();
}

class _DiarioRefeicaoCardState extends State<DiarioRefeicaoCard> {
  ResumoDiarioModel? _resumo;
  bool _carregando = true;
  String? _erro;

  // Metas diárias de referência
  static const double _metaCalorias = 2000;
  static const double _metaProteinas = 150;
  static const double _metaCarboidratos = 250;
  static const double _metaGorduras = 65;

  static const List<String> _opcoesRefeicao = [
    'Café da manhã',
    'Lanche da manhã',
    'Almoço',
    'Lanche da tarde',
    'Jantar',
    'Ceia',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _carregarRefeicoes();
  }

  Future<void> _carregarRefeicoes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final uri = Uri.parse(
          '${ApiLinks.baseUrl}/api/diario-refeicao/${widget.alunoId}/hoje');
      final resp = await http.get(uri, headers: TenantContext.jsonHeaders);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final lista = (body['refeicoes'] as List)
            .map((e) => DiarioRefeicaoModel.fromJson(e))
            .toList();
        setState(() => _resumo = ResumoDiarioModel.fromRefeicoes(lista));
      } else if (resp.statusCode == 404) {
        setState(() => _resumo = ResumoDiarioModel.fromRefeicoes([]));
      } else {
        setState(
            () => _erro = 'Erro ao carregar refeições (${resp.statusCode})');
      }
    } catch (e) {
      setState(() => _erro = 'Sem conexão com o servidor');
    } finally {
      setState(() => _carregando = false);
    }
  }

  Future<void> _excluirRefeicao(int id) async {
    try {
      final uri =
          Uri.parse('${ApiLinks.baseUrl}/api/diario-refeicao/$id');
      final resp =
          await http.delete(uri, headers: TenantContext.jsonHeaders);
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await _carregarRefeicoes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refeição removida.'),
              backgroundColor: GridColors.secondary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir (${resp.statusCode})'),
              backgroundColor: GridColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sem conexão com o servidor'),
            backgroundColor: GridColors.error,
          ),
        );
      }
    }
  }

  String _dataHoje() {
    final agora = DateTime.now();
    return '${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}';
  }

  Future<void> _abrirDialogNovaRefeicao() async {
    String nomeRefeicaoSelecionado = _opcoesRefeicao.first;
    final ctrlAlimentos = TextEditingController();
    final ctrlCalorias = TextEditingController();
    final ctrlProteinas = TextEditingController();
    final ctrlCarboidratos = TextEditingController();
    final ctrlGorduras = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Adicionar refeição'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: nomeRefeicaoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Refeição',
                    border: OutlineInputBorder(),
                  ),
                  items: _opcoesRefeicao
                      .map((op) =>
                          DropdownMenuItem(value: op, child: Text(op)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setStateDialog(() => nomeRefeicaoSelecionado = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrlAlimentos,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Alimentos',
                    hintText:
                        'Ex: 1 ovo cozido, 1 fatia de pão integral...',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: GridColors.secondary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _campoNumerico(ctrlCalorias, 'Calorias (kcal)',
                    decimal: true),
                const SizedBox(height: 12),
                _campoNumerico(ctrlProteinas, 'Proteínas (g)',
                    decimal: true),
                const SizedBox(height: 12),
                _campoNumerico(ctrlCarboidratos, 'Carboidratos (g)',
                    decimal: true),
                const SizedBox(height: 12),
                _campoNumerico(ctrlGorduras, 'Gorduras (g)',
                    decimal: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true) return;

    final novaRefeicao = DiarioRefeicaoModel(
      alunoId: widget.alunoId,
      data: _dataHoje(),
      nomeRefeicao: nomeRefeicaoSelecionado,
      alimentos: ctrlAlimentos.text.trim().isEmpty
          ? null
          : ctrlAlimentos.text.trim(),
      totalCalorias: double.tryParse(ctrlCalorias.text) ?? 0.0,
      totalProteinas: double.tryParse(ctrlProteinas.text) ?? 0.0,
      totalCarboidratos: double.tryParse(ctrlCarboidratos.text) ?? 0.0,
      totalGorduras: double.tryParse(ctrlGorduras.text) ?? 0.0,
    );

    await _salvarRefeicao(novaRefeicao);
  }

  Widget _campoNumerico(TextEditingController ctrl, String label,
      {bool decimal = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: decimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: GridColors.secondary),
        ),
      ),
    );
  }

  Future<void> _salvarRefeicao(DiarioRefeicaoModel refeicao) async {
    try {
      final uri =
          Uri.parse('${ApiLinks.baseUrl}/api/diario-refeicao');
      final resp = await http.post(
        uri,
        headers: TenantContext.jsonHeaders,
        body: jsonEncode(refeicao.toJson()),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _carregarRefeicoes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refeição registrada com sucesso!'),
              backgroundColor: GridColors.secondary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar (${resp.statusCode})'),
              backgroundColor: GridColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sem conexão com o servidor'),
            backgroundColor: GridColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_erro != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_erro!,
              style: const TextStyle(color: GridColors.error)),
        ),
      );
    }

    final resumo = _resumo!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card de resumo diário
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho resumo
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu,
                        color: GridColors.secondary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Resumo de hoje',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: GridColors.secondary,
                              ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _carregarRefeicoes,
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Atualizar',
                      color: GridColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Barras de macros
                _barraProgresso(
                  label: 'Calorias',
                  valor: resumo.totalCalorias,
                  meta: _metaCalorias,
                  unidade: 'kcal',
                  cor: GridColors.secondary,
                ),
                const SizedBox(height: 8),
                _barraProgresso(
                  label: 'Proteínas',
                  valor: resumo.totalProteinas,
                  meta: _metaProteinas,
                  unidade: 'g',
                  cor: const Color(0xFFFA903A),
                ),
                const SizedBox(height: 8),
                _barraProgresso(
                  label: 'Carboidratos',
                  valor: resumo.totalCarboidratos,
                  meta: _metaCarboidratos,
                  unidade: 'g',
                  cor: const Color(0xFF2196F3),
                ),
                const SizedBox(height: 8),
                _barraProgresso(
                  label: 'Gorduras',
                  valor: resumo.totalGorduras,
                  meta: _metaGorduras,
                  unidade: 'g',
                  cor: GridColors.error,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Lista de refeições do dia
        if (resumo.refeicoes.isEmpty)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.no_food,
                        size: 40, color: GridColors.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'Nenhuma refeição registrada hoje',
                      style: TextStyle(color: GridColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...resumo.refeicoes.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RefeicaoCard(
                refeicao: r,
                onExcluir: () => _excluirRefeicao(r.id!),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Botão adicionar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _abrirDialogNovaRefeicao,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Adicionar refeição',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.secondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _barraProgresso({
    required String label,
    required double valor,
    required double meta,
    required String unidade,
    required Color cor,
  }) {
    final progresso = (valor / meta).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: GridColors.textMuted)),
            Text(
              '${valor.toStringAsFixed(1)} / ${meta.toStringAsFixed(0)} $unidade',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progresso,
          backgroundColor: GridColors.secondarySoft,
          color: cor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

/// Card individual de uma refeição
class _RefeicaoCard extends StatelessWidget {
  final DiarioRefeicaoModel refeicao;
  final VoidCallback onExcluir;

  const _RefeicaoCard({
    required this.refeicao,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome da refeição + lixeira
            Row(
              children: [
                const Icon(Icons.restaurant,
                    size: 16, color: GridColors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    refeicao.nomeRefeicao ?? 'Refeição',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                IconButton(
                  onPressed: onExcluir,
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: GridColors.error),
                  tooltip: 'Excluir',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Calorias
            Row(
              children: [
                const Icon(Icons.local_fire_department,
                    size: 14, color: GridColors.secondary),
                const SizedBox(width: 4),
                Text(
                  '${refeicao.totalCalorias.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // Macros compactos
            Text(
              'P: ${refeicao.totalProteinas.toStringAsFixed(1)}g  |  '
              'C: ${refeicao.totalCarboidratos.toStringAsFixed(1)}g  |  '
              'G: ${refeicao.totalGorduras.toStringAsFixed(1)}g',
              style: const TextStyle(
                  fontSize: 12, color: GridColors.textMuted),
            ),

            // Alimentos (se houver)
            if (refeicao.alimentos != null &&
                refeicao.alimentos!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                refeicao.alimentos!,
                style: const TextStyle(
                    fontSize: 11, color: GridColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
