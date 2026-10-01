// lib/screens/fitness/diario_nutricional_screen.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';

class DiarioNutricionalScreen extends StatefulWidget {
  const DiarioNutricionalScreen({super.key});

  @override
  State<DiarioNutricionalScreen> createState() =>
      _DiarioNutricionalScreenState();
}

class _DiarioNutricionalScreenState extends State<DiarioNutricionalScreen> {
  final List<Map<String, dynamic>> refeicoes = [
    {'nome': 'Café da Manhã', 'kcal': 300},
    {'nome': 'Almoço', 'kcal': 400},
    {'nome': 'Lanche', 'kcal': 350},
  ];

  @override
  Widget build(BuildContext context) {
    final total = refeicoes.fold<int>(0, (sum, r) => sum + (r['kcal'] as int));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diário Nutricional'),
        backgroundColor: GridColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...refeicoes.map((refeicao) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: Text(refeicao['nome'] as String),
                trailing: Text('${refeicao['kcal']} kcal'),
              ),
            );
          }),
          const SizedBox(height: 16),
          Card(
            color: GridColors.secondary,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Total: $total kcal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
