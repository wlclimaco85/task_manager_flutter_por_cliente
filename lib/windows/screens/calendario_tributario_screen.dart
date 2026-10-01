import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

/// Calendário Tributário com obrigações fiscais por dia
class CalendarioTributarioScreen extends StatefulWidget {
  const CalendarioTributarioScreen({super.key});

  @override
  State<CalendarioTributarioScreen> createState() =>
      _CalendarioTributarioScreenState();
}

class _CalendarioTributarioScreenState extends State<CalendarioTributarioScreen> {
  late DateTime _dataSelecionada;
  bool _carregando = false;
  List<Map<String, dynamic>> _obrigacoesDia = [];
  String? _erro;
  Map<int, List<Map<String, dynamic>>> _obrigacoesPorDia = {};

  @override
  void initState() {
    super.initState();
    _dataSelecionada = DateTime.now();
    _carregarObrigacoes();
  }

  Future<void> _carregarObrigacoes() async {
    setState(() => _carregando = true);
    try {
      final token = AuthUtility.userInfo?.token;
      final headers = {if (token != null) 'Authorization': 'Bearer $token'};
      final mes = _dataSelecionada.month;
      final ano = _dataSelecionada.year;
      final url = TenantContext.applyToUrl(
        '${ApiLinks.baseUrl}/api/obrigacoes-fiscais?mes=$mes&ano=$ano',
      );
      final response = await http.get(Uri.parse(url), headers: headers);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? [];

        // Organizar obrigações por dia
        final mapa = <int, List<Map<String, dynamic>>>{};
        if (data is List) {
          for (final item in data) {
            final dia = item['dia'] ?? 0;
            if (dia > 0) {
              mapa.putIfAbsent(dia, () => []).add(Map<String, dynamic>.from(item as Map));
            }
          }
        }

        setState(() {
          _obrigacoesPorDia = mapa;
          _erro = null;
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = 'Erro ao carregar obrigações: ${response.statusCode}';
          _carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro de conexão: $e';
        _carregando = false;
      });
    }
  }

  void _carregarObrigacoesDia(int dia) {
    setState(() {
      _obrigacoesDia = _obrigacoesPorDia[dia] ?? [];
    });
  }

  void _mesAnterior() {
    setState(() {
      _dataSelecionada =
          DateTime(_dataSelecionada.year, _dataSelecionada.month - 1);
      _obrigacoesDia = [];
      _carregarObrigacoes();
    });
  }

  void _mesProximo() {
    setState(() {
      _dataSelecionada =
          DateTime(_dataSelecionada.year, _dataSelecionada.month + 1);
      _obrigacoesDia = [];
      _carregarObrigacoes();
    });
  }

  String _nomeMes(int mes) {
    const nomes = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];
    return nomes[mes - 1];
  }

  List<int> _diasDoMes() {
    final ultimoDia =
        DateTime(_dataSelecionada.year, _dataSelecionada.month + 1, 0).day;
    return List.generate(ultimoDia, (i) => i + 1);
  }

  @override
  Widget build(BuildContext context) {
    final diasDoMes = _diasDoMes();
    const diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário Tributário'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navegação de mês
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _mesAnterior,
                        tooltip: 'Mês anterior',
                      ),
                      Text(
                        '${_nomeMes(_dataSelecionada.month)} ${_dataSelecionada.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _mesProximo,
                        tooltip: 'Próximo mês',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Cabeçalho da semana
                  GridView.count(
                    crossAxisCount: 7,
                    childAspectRatio: 1.2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: diasSemana
                        .map((dia) => Center(
                              child: Text(
                                dia,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  // Grid de dias
                  _carregando
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        )
                      : GridView.count(
                          crossAxisCount: 7,
                          childAspectRatio: 1.2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: diasDoMes
                              .map((dia) => _buildDiaCell(dia))
                              .toList(),
                        ),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _erro!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Painel lateral com obrigações do dia selecionado
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Obrigações do Dia',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clique em um dia para ver as obrigações',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _obrigacoesDia.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhuma obrigação selecionada',
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _obrigacoesDia.length,
                          itemBuilder: (context, index) {
                            final obrigacao = _obrigacoesDia[index];
                            return _buildObrigacaoCard(obrigacao);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaCell(int dia) {
    final agora = DateTime.now();
    final hojePertenceAoMes = agora.year == _dataSelecionada.year &&
        agora.month == _dataSelecionada.month &&
        agora.day == dia;

    final temObrigacoes = _obrigacoesPorDia.containsKey(dia) &&
        _obrigacoesPorDia[dia]!.isNotEmpty;

    return GestureDetector(
      onTap: () => _carregarObrigacoesDia(dia),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: hojePertenceAoMes ? GridColors.primary : Colors.grey.shade300,
            width: hojePertenceAoMes ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          color: hojePertenceAoMes
              ? GridColors.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$dia',
                style: TextStyle(
                  fontWeight: hojePertenceAoMes ? FontWeight.bold : FontWeight.normal,
                  color: hojePertenceAoMes ? GridColors.primary : Colors.black,
                ),
              ),
            ),
            if (temObrigacoes)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildObrigacaoCard(Map<String, dynamic> obrigacao) {
    final descricao = obrigacao['descricao'] ?? 'Obrigação';
    final prazo = obrigacao['prazo'] ?? '';
    final status = obrigacao['status'] ?? 'pendente';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    descricao,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'realizada'
                        ? Colors.green.shade100
                        : status == 'vencida'
                            ? Colors.red.shade100
                            : Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: status == 'realizada'
                          ? Colors.green.shade900
                          : status == 'vencida'
                              ? Colors.red.shade900
                              : Colors.yellow.shade900,
                    ),
                  ),
                ),
              ],
            ),
            if (prazo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Prazo: $prazo',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
