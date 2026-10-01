import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class DashboardObrigacoesScreen extends StatefulWidget {
  const DashboardObrigacoesScreen({super.key});

  @override
  State<DashboardObrigacoesScreen> createState() =>
      _DashboardObrigacoesScreenState();
}

class _DashboardObrigacoesScreenState extends State<DashboardObrigacoesScreen> {
  bool _carregando = true;
  Map<String, dynamic>? _dados;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/dashboard/obrigacoes');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _dados = Map<String, dynamic>.from(body['data'] ?? body);
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = 'Erro HTTP ${resp.statusCode}';
          _carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro: $e';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Obrigações'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _carregando = true;
                _erro = null;
              });
              _carregar();
            },
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)))
              : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    final vencidas = _dados?['vencidas'] ?? 0;
    final vencendoHoje = _dados?['vencendoHoje'] ?? 0;
    final proximos7dias = _dados?['proximos7dias'] ?? 0;
    final proximos30dias = _dados?['proximos30dias'] ?? 0;
    final totalEmAberto = _dados?['totalEmAberto'] ?? 0;
    final valorTotal = (_dados?['valorTotal'] as num?)?.toStringAsFixed(2) ?? '0,00';
    final itens = List<Map<String, dynamic>>.from(_dados?['proximasObrigacoes'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _cardMetrica('Vencidas', vencidas.toString(), Colors.red, Icons.warning),
              _cardMetrica('Vencem hoje', vencendoHoje.toString(), Colors.orange, Icons.today),
              _cardMetrica('Próx. 7 dias', proximos7dias.toString(), Colors.amber, Icons.date_range),
              _cardMetrica('Próx. 30 dias', proximos30dias.toString(), GridColors.primary, Icons.calendar_month),
            ],
          ),
          const SizedBox(height: 16),
          _cardMetricaLarge('Total em aberto', totalEmAberto.toString(), 'R\$ $valorTotal'),
          const SizedBox(height: 20),
          Text('Próximas obrigações',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: GridColors.primary)),
          const SizedBox(height: 8),
          if (itens.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Nenhuma obrigação pendente', style: TextStyle(color: Colors.grey))))
          else
            ...itens.map((item) => _buildItemObrigacao(item)),
        ],
      ),
    );
  }

  Widget _cardMetrica(String titulo, String valor, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icone, color: cor, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cor)),
              Text(titulo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardMetricaLarge(String titulo, String qtd, String valor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Text(qtd, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: GridColors.primary)),
          ]),
          Text(valor,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GridColors.primary)),
        ],
      ),
    );
  }

  Widget _buildItemObrigacao(Map<String, dynamic> item) {
    final venc = item['dataVencimento']?.toString() ?? '';
    final desc = item['descricao']?.toString() ?? '';
    final valor = item['valor']?.toString() ?? '';
    final status = item['status'] as int? ?? 0;
    final cor = status == 0 ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.15),
          child: Icon(Icons.receipt_long, color: cor, size: 20),
        ),
        title: Text(desc, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Venc: $venc', style: const TextStyle(fontSize: 12)),
        trailing: Text('R\$ $valor',
            style: TextStyle(fontWeight: FontWeight.bold, color: cor)),
      ),
    );
  }
}
