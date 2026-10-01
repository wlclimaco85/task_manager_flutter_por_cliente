// lib/screens/contabil/obrigacoes_screen.dart
import 'package:flutter/material.dart';

class ObrigacoesScreen extends StatelessWidget {
  const ObrigacoesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Obrigações Fiscais',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildObrigacaoTile(
                nome: 'ECF',
                status: 'Ativo',
                statusColor: Colors.green,
              ),
              _buildObrigacaoTile(
                nome: 'NFe',
                status: 'Ativo',
                statusColor: Colors.green,
              ),
              _buildObrigacaoTile(
                nome: 'NFSe',
                status: 'Pendente',
                statusColor: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObrigacaoTile({
    required String nome,
    required String status,
    required Color statusColor,
  }) {
    return ListTile(
      leading: Icon(Icons.receipt, color: Colors.blue),
      title: Text(nome),
      subtitle: Text(status),
      trailing: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
