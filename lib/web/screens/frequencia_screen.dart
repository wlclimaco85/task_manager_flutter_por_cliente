import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FrequenciaScreen extends StatefulWidget {
  const FrequenciaScreen({Key? key}) : super(key: key);

  @override
  State<FrequenciaScreen> createState() => _FrequenciaScreenState();
}

class _FrequenciaScreenState extends State<FrequenciaScreen> {
  late Future<List<FrequenciaWeek>> _frequenciaFuture;

  @override
  void initState() {
    super.initState();
    _frequenciaFuture = _carregarFrequencia();
  }

  Future<List<FrequenciaWeek>> _carregarFrequencia() async {
    try {
      final login = await AuthUtility.obterLogin();
      final alunoId = login?.data?.id ?? login?.login?.parceiro?.id;
      if (alunoId == null) {
        throw Exception('Aluno não identificado');
      }
      final url = Uri.parse(
        '${ApiLinks.baseUrl}/api/sessoes-treino/aluno/$alunoId/frequencia',
      );

      final headers = await AuthUtility.obterHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return _agruparPorSemana(data);
      } else {
        throw Exception('Erro ao carregar frequência: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro: $e');
    }
  }

  List<FrequenciaWeek> _agruparPorSemana(List<dynamic> sessoes) {
    final Map<String, List<FrequenciaItem>> semanas = {};

    for (final sessao in sessoes) {
      try {
        final dataStr = sessao['data'] ?? sessao['dataSessao'];
        if (dataStr == null || dataStr.toString().isEmpty) {
          continue;
        }

        final data = DateTime.parse(dataStr.toString());
        final semanaInicio = _obterInicioSemana(data);
        final semanaFim = semanaInicio.add(const Duration(days: 6));
        final chave = _formatarChaveSemana(semanaInicio);

        semanas.putIfAbsent(chave, () => []).add(
          FrequenciaItem(
            data: data,
            duracao: sessao['duracao'] ?? 0,
            realizado: sessao['realizado'] == true,
          ),
        );
      } catch (e) {
        // Skip item com erro
        continue;
      }
    }

    // Converter para FrequenciaWeek ordenado
    final weeks = semanas.entries.map((entry) {
      final items = (entry.value..sort((a, b) => a.data.compareTo(b.data)));
      final realizados = items.where((x) => x.realizado).length;
      return FrequenciaWeek(
        inicio: items.first.data,
        fim: items.last.data,
        items: items,
        realizados: realizados,
      );
    }).toList();

    weeks.sort((a, b) => b.inicio.compareTo(a.inicio));
    return weeks;
  }

  DateTime _obterInicioSemana(DateTime data) {
    // segunda-feira = 1, domingo = 7
    final diasParaTras = data.weekday - 1;
    return data.subtract(Duration(days: diasParaTras));
  }

  String _formatarChaveSemana(DateTime inicio) {
    return '${inicio.year}-${inicio.month}-${inicio.day}';
  }

  String _formatarDataCurta(DateTime data) {
    return DateFormat('dd/MM', 'pt_BR').format(data);
  }

  String _formatarDiaSemana(DateTime data) {
    final dias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sab', 'dom'];
    return dias[data.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequência'),
        backgroundColor: GridColors.primary,
      ),
      body: FutureBuilder<List<FrequenciaWeek>>(
        future: _frequenciaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${snapshot.error}')),
              );
            });
            return Center(
              child: Text('Erro: ${snapshot.error}'),
            );
          }

          final weeks = snapshot.data ?? [];
          if (weeks.isEmpty) {
            return const Center(
              child: Text('Nenhuma sessão de treino encontrada'),
            );
          }

          return ListView.builder(
            itemCount: weeks.length,
            itemBuilder: (context, index) {
              final week = weeks[index];
              return _buildWeekSection(week);
            },
          );
        },
      ),
    );
  }

  Widget _buildWeekSection(FrequenciaWeek week) {
    final dataInicio = _formatarDataCurta(week.inicio);
    final dataFim = _formatarDataCurta(week.fim);
    final total = week.items.length;
    final realizados = week.realizados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: GridColors.primary.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semana de $dataInicio a $dataFim',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$realizados de $total treinos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ...week.items.map((item) => _buildSessionCard(item)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSessionCard(FrequenciaItem item) {
    final diaSemana = _formatarDiaSemana(item.data);
    final data = _formatarDataCurta(item.data);
    final duracao = item.duracao > 0 ? '${item.duracao} min' : 'pendente';
    final statusIcon = item.realizado
        ? Icon(Icons.check_circle, color: GridColors.success, size: 24)
        : Icon(Icons.radio_button_unchecked,
            color: GridColors.neutral, size: 24);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$data ($diaSemana)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duracao,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          statusIcon,
        ],
      ),
    );
  }
}

class FrequenciaWeek {
  final DateTime inicio;
  final DateTime fim;
  final List<FrequenciaItem> items;
  final int realizados;

  FrequenciaWeek({
    required this.inicio,
    required this.fim,
    required this.items,
    required this.realizados,
  });
}

class FrequenciaItem {
  final DateTime data;
  final int duracao;
  final bool realizado;

  FrequenciaItem({
    required this.data,
    required this.duracao,
    required this.realizado,
  });
}
