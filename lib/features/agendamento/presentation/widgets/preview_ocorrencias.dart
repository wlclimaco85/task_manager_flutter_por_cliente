import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Preview das próximas ocorrências baseado em RRULE
class PreviewOcorrencias extends StatelessWidget {
  final String rrule;

  const PreviewOcorrencias({
    Key? key,
    required this.rrule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ocorrencias = _calcularOcorrencias();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próximas 5 Ocorrências',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (ocorrencias.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'Nenhuma ocorrência',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              Column(
                children: List.generate(
                  ocorrencias.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildOcorrenciaItem(context, ocorrencias[index], index),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOcorrenciaItem(BuildContext context, DateTime date, int index) {
    final formatted = DateFormat('dd/MM/yyyy HH:mm').format(date);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatted,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      _getDayName(date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              Icons.check_circle,
              color: Colors.green[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _calcularOcorrencias() {
    final List<DateTime> ocorrencias = [];
    DateTime current = DateTime.now();

    // Parseamento básico de RRULE (simplificado)
    // Versão produção usaria pacote rrule
    if (rrule.isEmpty) return [];

    for (int i = 0; i < 5; i++) {
      try {
        if (rrule.contains('DAILY')) {
          ocorrencias.add(current.add(Duration(days: i + 1)));
        } else if (rrule.contains('WEEKLY')) {
          ocorrencias.add(current.add(Duration(days: (i + 1) * 7)));
        } else if (rrule.contains('MONTHLY')) {
          int month = current.month + i + 1;
          int year = current.year;

          // Handle year overflow
          if (month > 12) {
            year += (month - 1) ~/ 12;
            month = ((month - 1) % 12) + 1;
          }

          // Handle day overflow (e.g., Feb 30)
          int day = current.day;
          final daysInMonth = _getDaysInMonth(year, month);
          if (day > daysInMonth) {
            day = daysInMonth;
          }

          ocorrencias.add(DateTime(year, month, day));
        } else if (rrule.contains('YEARLY')) {
          ocorrencias.add(
            DateTime(
              current.year + i + 1,
              current.month,
              current.day,
            ),
          );
        }
      } catch (e) {
        // Ignore errors in date calculation
      }
    }

    return ocorrencias;
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      return DateTime(year, 3, 0).day; // February
    }
    const daysPerMonth = [31, 31, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysPerMonth[month - 1];
  }

  String _getDayName(DateTime date) {
    const days = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo'
    ];
    return days[date.weekday - 1];
  }
}
