import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/api_links.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';
import 'package:http/http.dart' as http;

/// Modelo de atividade diária
class AtividadeDiariaModel {
  final int? id;
  final int alunoId;
  final String data;
  final int passos;
  final double distanciaKm;
  final int caloriasAtivas;
  final int metaPassos;

  AtividadeDiariaModel({
    this.id,
    required this.alunoId,
    required this.data,
    this.passos = 0,
    this.distanciaKm = 0.0,
    this.caloriasAtivas = 0,
    this.metaPassos = 10000,
  });

  factory AtividadeDiariaModel.fromJson(Map<String, dynamic> json) {
    return AtividadeDiariaModel(
      id: json['id'],
      alunoId: json['alunoId'] ?? 0,
      data: json['data'] ?? '',
      passos: json['passos'] ?? 0,
      distanciaKm: (json['distanciaKm'] ?? 0).toDouble(),
      caloriasAtivas: json['caloriasAtivas'] ?? 0,
      metaPassos: json['metaPassos'] ?? 10000,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'alunoId': alunoId,
        'data': data,
        'passos': passos,
        'distanciaKm': distanciaKm,
        'caloriasAtivas': caloriasAtivas,
        'metaPassos': metaPassos,
      };
}

/// Card de atividade diária com anel de progresso e entrada manual.
///
/// TODO Fase 2: integrar sensors_plus/pedometer para leitura automática do
/// pedômetro nativo (requer permissão Android/iOS; não funciona em web).
class AtividadeDiariaCard extends StatefulWidget {
  final int alunoId;

  const AtividadeDiariaCard({super.key, required this.alunoId});

  @override
  State<AtividadeDiariaCard> createState() => _AtividadeDiariaCardState();
}

class _AtividadeDiariaCardState extends State<AtividadeDiariaCard> {
  AtividadeDiariaModel? _atividade;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAtividadeHoje();
  }

  Future<void> _carregarAtividadeHoje() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final uri = Uri.parse(
          '${ApiLinks.baseUrl}/api/atividade-diaria/${widget.alunoId}/hoje');
      final resp = await http.get(uri, headers: TenantContext.jsonHeaders);
      if (resp.statusCode == 200) {
        final dados = AtividadeDiariaModel.fromJson(jsonDecode(resp.body));
        setState(() => _atividade = dados);
      } else if (resp.statusCode == 404) {
        // Sem registro hoje — usa valores zerados
        setState(() => _atividade = AtividadeDiariaModel(
              alunoId: widget.alunoId,
              data: _dataHoje(),
              metaPassos: 10000,
            ));
      } else {
        setState(() => _erro = 'Erro ao carregar atividade (${resp.statusCode})');
      }
    } catch (e) {
      setState(() => _erro = 'Sem conexão com o servidor');
    } finally {
      setState(() => _carregando = false);
    }
  }

  String _dataHoje() {
    final agora = DateTime.now();
    return '${agora.year}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}';
  }

  double get _progressoPassos {
    if (_atividade == null || _atividade!.metaPassos == 0) return 0.0;
    return (_atividade!.passos / _atividade!.metaPassos).clamp(0.0, 1.0);
  }

  Future<void> _abrirDialogRegistro() async {
    final atual = _atividade;
    final ctrlPassos = TextEditingController(
        text: atual != null && atual.passos > 0 ? '${atual.passos}' : '');
    final ctrlDistancia = TextEditingController(
        text: atual != null && atual.distanciaKm > 0
            ? '${atual.distanciaKm}'
            : '');
    final ctrlCalorias = TextEditingController(
        text: atual != null && atual.caloriasAtivas > 0
            ? '${atual.caloriasAtivas}'
            : '');
    final ctrlMeta = TextEditingController(
        text: '${atual?.metaPassos ?? 10000}');

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar atividade do dia'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campoNumerico(ctrlPassos, 'Passos'),
              const SizedBox(height: 12),
              _campoNumerico(ctrlDistancia, 'Distância (km)', decimal: true),
              const SizedBox(height: 12),
              _campoNumerico(ctrlCalorias, 'Calorias ativas'),
              const SizedBox(height: 12),
              _campoNumerico(ctrlMeta, 'Meta de passos'),
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
    );

    if (confirmado != true) return;

    final novoRegistro = AtividadeDiariaModel(
      id: atual?.id,
      alunoId: widget.alunoId,
      data: _dataHoje(),
      passos: int.tryParse(ctrlPassos.text) ?? 0,
      distanciaKm: double.tryParse(ctrlDistancia.text) ?? 0.0,
      caloriasAtivas: int.tryParse(ctrlCalorias.text) ?? 0,
      metaPassos: int.tryParse(ctrlMeta.text) ?? 10000,
    );

    await _salvarAtividade(novoRegistro);
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

  Future<void> _salvarAtividade(AtividadeDiariaModel registro) async {
    try {
      final uri =
          Uri.parse('${ApiLinks.baseUrl}/api/atividade-diaria');
      final resp = await http.post(
        uri,
        headers: TenantContext.jsonHeaders,
        body: jsonEncode(registro.toJson()),
      );
      if (resp.statusCode == 200) {
        final salvo =
            AtividadeDiariaModel.fromJson(jsonDecode(resp.body));
        setState(() => _atividade = salvo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Atividade registrada com sucesso!'),
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

    final atividade = _atividade!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                const Icon(Icons.directions_walk,
                    color: GridColors.secondary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Atividade de Hoje',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: GridColors.secondary,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _carregarAtividadeHoje,
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Atualizar',
                  color: GridColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Anel de progresso + métricas
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Anel de progresso de passos
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(88, 88),
                        painter: _AnelProgressoPainter(_progressoPassos),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_progressoPassos * 100).toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: GridColors.secondary,
                            ),
                          ),
                          const Text(
                            'meta',
                            style: TextStyle(
                                fontSize: 10, color: GridColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Métricas
                Expanded(
                  child: Column(
                    children: [
                      _metricaRow(
                        Icons.directions_walk,
                        'Passos',
                        '${atividade.passos}',
                        'meta: ${atividade.metaPassos}',
                      ),
                      const SizedBox(height: 8),
                      _metricaRow(
                        Icons.social_distance,
                        'Distância',
                        '${atividade.distanciaKm.toStringAsFixed(2)} km',
                        null,
                      ),
                      const SizedBox(height: 8),
                      _metricaRow(
                        Icons.local_fire_department,
                        'Calorias',
                        '${atividade.caloriasAtivas} kcal',
                        null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botão registrar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _abrirDialogRegistro,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Registrar manualmente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GridColors.secondary,
                  side: const BorderSide(color: GridColors.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricaRow(
      IconData icone, String titulo, String valor, String? subtitulo) {
    return Row(
      children: [
        Icon(icone, size: 16, color: GridColors.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 11, color: GridColors.textMuted)),
              Text(valor,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              if (subtitulo != null)
                Text(subtitulo,
                    style: const TextStyle(
                        fontSize: 10, color: GridColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Desenha o anel circular de progresso.
class _AnelProgressoPainter extends CustomPainter {
  final double progresso;
  _AnelProgressoPainter(this.progresso);

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = (size.width / 2) - 6;
    const espessura = 8.0;

    final pinturaFundo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..color = GridColors.secondarySoft;

    final pinturaProgresso = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..strokeCap = StrokeCap.round
      ..color = GridColors.secondary;

    // Fundo completo
    canvas.drawCircle(centro, raio, pinturaFundo);

    // Arco de progresso
    final angulo = 2 * math.pi * progresso;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raio),
      -math.pi / 2,
      angulo,
      false,
      pinturaProgresso,
    );
  }

  @override
  bool shouldRepaint(_AnelProgressoPainter old) =>
      old.progresso != progresso;
}
