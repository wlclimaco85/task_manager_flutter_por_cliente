// lib/screens/contabil/calendario_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/services/auth_service.dart';
import 'package:task_manager_flutter/helpers/download_helper.dart';
import 'package:task_manager_flutter/utils/api_links.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({Key? key}) : super(key: key);

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  String _filtroTipo = 'Todos';
  int _mesAtual = DateTime.now().month;
  int _anoAtual = DateTime.now().year;
  bool _carregando = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Calendário Tributário',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _filtroTipo,
              items: ['Todos', 'Federal', 'Estadual', 'Municipal']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _filtroTipo = newValue;
                  });
                }
              },
            ),
          ),
          // ─────────────────────────────────────────────────────────────────────
          // CARD #276: Filtros de Exportação (Mês e Ano)
          // ─────────────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Dropdown Mês
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mês'),
                      const SizedBox(height: 8),
                      DropdownButton<int>(
                        value: _mesAtual,
                        isExpanded: true,
                        items: List.generate(12, (i) => i + 1)
                            .map((int mes) {
                          return DropdownMenuItem<int>(
                            value: mes,
                            child: Text('$mes'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _mesAtual = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Dropdown Ano
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ano'),
                      const SizedBox(height: 8),
                      DropdownButton<int>(
                        value: _anoAtual,
                        isExpanded: true,
                        items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                            .map((int ano) {
                          return DropdownMenuItem<int>(
                            value: ano,
                            child: Text('$ano'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _anoAtual = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Botão Exportar CSV
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _carregando ? null : _exportarCalendario,
              child: _carregando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Exportar CSV'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCalendarTable(),
          ),
        ],
      ),
    );
  }

  /// Exportar calendário em CSV via API
  Future<void> _exportarCalendario() async {
    try {
      setState(() {
        _carregando = true;
      });

      // Montar URL com parâmetros
      final baseUrl = ApiLinks.baseUrl;
      final url = Uri.parse(
        '$baseUrl/api/calendario-guias/export/csv?mes=$_mesAtual&ano=$_anoAtual',
      );

      // Headers com autenticação
      final authService = AuthService();
      final headers = await authService.jsonHeaders();

      // Fazer request
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Download CSV
        final csvBytes = response.bodyBytes;
        final filename = 'calendario_guias_${_mesAtual}_${_anoAtual}.csv';
        await downloadCsvBytes(csvBytes, filename);

        // Feedback ao usuário
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arquivo "$filename" baixado com sucesso!'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Erro na API
        final errorMsg = 'Erro ao exportar: ${response.statusCode}';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Erro de conexão ou processamento
      final errorMsg = 'Erro ao exportar: $e';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Widget _buildCalendarTable() {
    final diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    final diasMes = List.generate(42, (index) => index + 1);

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        // Cabeçalho com dias da semana
        TableRow(
          children: diasSemana
              .map((dia) => Container(
                    color: Colors.blue.shade100,
                    padding: const EdgeInsets.all(8.0),
                    child: Text(dia,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ))
              .toList(),
        ),
        // Linhas do calendário (6 semanas)
        for (int i = 0; i < 6; i++)
          TableRow(
            children: List.generate(7, (dayIndex) {
              final diaNumero = i * 7 + dayIndex + 1;
              return Container(
                height: 60,
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  diaNumero <= 31 ? '$diaNumero' : '',
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ),
      ],
    );
  }
}
