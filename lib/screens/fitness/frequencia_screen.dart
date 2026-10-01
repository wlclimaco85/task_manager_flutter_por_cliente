// lib/screens/fitness/frequencia_screen.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';

class FrequenciaScreen extends StatefulWidget {
  const FrequenciaScreen({super.key});

  @override
  State<FrequenciaScreen> createState() => _FrequenciaScreenState();
}

class _FrequenciaScreenState extends State<FrequenciaScreen> {
  final List<Map<String, dynamic>> dias = [
    {'dia': 'Seg', 'valor': 45},
    {'dia': 'Ter', 'valor': 60},
    {'dia': 'Qua', 'valor': 50},
    {'dia': 'Qui', 'valor': 55},
    {'dia': 'Sex', 'valor': 65},
    {'dia': 'Sab', 'valor': 40},
    {'dia': 'Dom', 'valor': 30},
  ];

  @override
  Widget build(BuildContext context) {
    final alturaMax = dias.map((d) => d['valor'] as int).reduce((a, b) => a > b ? a : b).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequência'),
        backgroundColor: GridColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minutos por dia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: dias.map((dia) {
                  final altura = ((dia['valor'] as int).toDouble() / alturaMax) * 150;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 30,
                        height: altura,
                        color: GridColors.secondary,
                      ),
                      const SizedBox(height: 8),
                      Text(dia['dia'] as String),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: GridColors.primary.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total da Semana: ${dias.fold<int>(0, (sum, d) => sum + (d['valor'] as int))} minutos',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Média: ${(dias.fold<int>(0, (sum, d) => sum + (d['valor'] as int)) / dias.length).toStringAsFixed(1)} min/dia',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
