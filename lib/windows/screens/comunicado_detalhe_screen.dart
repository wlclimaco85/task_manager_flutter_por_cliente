import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/grid_colors.dart';

/// Tela de detalhe de um comunicado (versao Windows).
/// Exibe todas as informacoes do comunicado em formato de leitura.
class WindowsComunicadoDetalheScreen extends StatelessWidget {
  final Map<String, dynamic> comunicado;

  const WindowsComunicadoDetalheScreen({super.key, required this.comunicado});

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  String _text(String key) => comunicado[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final titulo = _text('titulo').isNotEmpty ? _text('titulo') : 'Comunicado';
    final conteudo = _text('conteudo');
    // Fix card #452: 'categoria' nunca existiu no backend (Comunicado.java
    // tem 'setor', nao 'categoria') -- chip ficava sempre vazio e o Setor
    // real (dado relevante) nunca era exibido.
    final setor = (comunicado['setor'] is Map)
        ? (comunicado['setor']['descricao']?.toString() ?? '')
        : '';
    final autor = _text('autor');
    final dataStr = comunicado['dhCreatedAt'] ?? comunicado['createdAt'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Detalhe do Comunicado'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: GridColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                if (setor.isNotEmpty)
                  _Chip(label: setor, icon: Icons.groups_outlined),
                if (autor.isNotEmpty)
                  _Chip(label: 'Por: $autor', icon: Icons.person),
                if (dataStr != null)
                  _Chip(
                    label: _formatDate(dataStr),
                    icon: Icons.calendar_today,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            if (conteudo.isNotEmpty)
              Text(
                conteudo,
                style: const TextStyle(fontSize: 16, height: 1.6),
              )
            else
              const Text(
                'Sem conteudo disponivel.',
                style: TextStyle(
                  fontSize: 16,
                  color: GridColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: GridColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GridColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GridColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: GridColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
