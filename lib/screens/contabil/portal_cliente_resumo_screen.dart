// lib/screens/contabil/portal_cliente_resumo_screen.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/models/portal_cliente_resumo_model.dart';
import 'package:task_manager_flutter/services/portal_cliente_caller.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';

class PortalClienteResumoScreen extends StatefulWidget {
  final int empresaId;

  const PortalClienteResumoScreen({
    Key? key,
    required this.empresaId,
  }) : super(key: key);

  @override
  State<PortalClienteResumoScreen> createState() =>
      _PortalClienteResumoScreenState();
}

class _PortalClienteResumoScreenState extends State<PortalClienteResumoScreen> {
  late Future<PortalClienteResumo> futureResumo;

  @override
  void initState() {
    super.initState();
    futureResumo =
        PortalClienteCaller().fetchResumo(context, widget.empresaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Cliente - Resumo'),
        backgroundColor: GridColors.primary,
      ),
      body: FutureBuilder<PortalClienteResumo>(
        future: futureResumo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro: ${snapshot.error}'),
            );
          }

          final resumo = snapshot.data ??
              PortalClienteResumo(saldo: 0, docsPendentes: 0, alertas: 0);

          return _buildContent(resumo);
        },
      ),
    );
  }

  Widget _buildContent(PortalClienteResumo resumo) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KPI Card 1: Saldo
            _buildKpiCard(
              title: 'Saldo',
              value: resumo.saldoFormatado,
              icon: Icons.trending_up,
              color: GridColors.secondary,
            ),
            const SizedBox(height: 16),

            // KPI Card 2: Documentos Pendentes
            _buildKpiCard(
              title: 'Documentos Pendentes',
              value: '${resumo.docsPendentes}',
              icon: Icons.description,
              color: GridColors.warning,
            ),
            const SizedBox(height: 16),

            // KPI Card 3: Alertas
            _buildKpiCard(
              title: 'Alertas',
              value: '${resumo.alertas}',
              icon: Icons.notifications,
              color: GridColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
