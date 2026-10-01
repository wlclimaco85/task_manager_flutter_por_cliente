// lib/screens/contabil/portal_cliente_screen.dart
import 'package:flutter/material.dart';

class PortalClienteScreen extends StatelessWidget {
  const PortalClienteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Portal do Cliente',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: _buildKpiCard(
                    icon: Icons.wallet,
                    iconColor: Colors.blue,
                    bgColor: Colors.blue.shade50,
                    title: 'Saldo',
                    value: 'R\$ 0,00',
                  ),
                ),
                Flexible(
                  child: _buildKpiCard(
                    icon: Icons.insert_drive_file,
                    iconColor: Colors.orange,
                    bgColor: Colors.orange.shade50,
                    title: 'Documentos',
                    value: '0',
                  ),
                ),
                Flexible(
                  child: _buildKpiCard(
                    icon: Icons.notifications_active,
                    iconColor: Colors.red,
                    bgColor: Colors.red.shade50,
                    title: 'Alertas',
                    value: '0',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
