import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/grid_colors.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;

/// Tela de detalhe de exercício com preview de mídia externa.
/// Exibe os campos de cadastro via [GenericDetailFormScreen] e adiciona
/// uma aba "Mídia" com botões para abrir links de vídeo/documento e
/// exibição de thumbnail de foto quando disponíveis.
class ExercicioDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const ExercicioDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return GenericDetailFormScreen(
      item: item,
      telaNome: 'exercicios',
      hasPermission: hasPermission,
      relatedTabs: [
        RelatedGridTab(
          title: 'Mídia',
          icon: Icons.perm_media,
          customWidget: _MidiaTab(item: item),
        ),
      ],
    );
  }
}

class _MidiaTab extends StatelessWidget {
  final Map<String, dynamic> item;

  const _MidiaTab({required this.item});

  String? _campo(String chave) {
    final valor = item[chave];
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  Future<void> _abrirLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.scheme.startsWith('http'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL inválida')),
      );
      return;
    }
    final podeAbrir = await canLaunchUrl(uri);
    if (podeAbrir) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkVideo = _campo('linkVideo');
    final foto = _campo('foto');
    final linkDoc = _campo('linkDoc');
    final nivel = _campo('nivel');
    final temMidia = linkVideo != null || foto != null || linkDoc != null;

    if (!temMidia && nivel == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nenhuma mídia cadastrada para este exercício.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (nivel != null) ...[
          _SecaoTitulo(titulo: 'Nível de Dificuldade'),
          const SizedBox(height: 8),
          _NivelChip(nivel: nivel),
          const SizedBox(height: 24),
        ],
        if (foto != null) ...[
          _SecaoTitulo(titulo: 'Foto / Thumbnail'),
          const SizedBox(height: 8),
          _FotoPreview(url: foto, onAbrirLink: () => _abrirLink(context, foto)),
          const SizedBox(height: 24),
        ],
        if (linkVideo != null) ...[
          _SecaoTitulo(titulo: 'Vídeo'),
          const SizedBox(height: 8),
          _LinkCard(
            url: linkVideo,
            icone: Icons.play_circle_outline,
            rotulo: 'Abrir vídeo',
            cor: GridColors.primary,
            onAbrirLink: () => _abrirLink(context, linkVideo),
          ),
          const SizedBox(height: 24),
        ],
        if (linkDoc != null) ...[
          _SecaoTitulo(titulo: 'Documento'),
          const SizedBox(height: 8),
          _LinkCard(
            url: linkDoc,
            icone: Icons.description_outlined,
            rotulo: 'Abrir documento',
            cor: Colors.blueGrey,
            onAbrirLink: () => _abrirLink(context, linkDoc),
          ),
        ],
      ],
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  final String titulo;
  const _SecaoTitulo({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }
}

class _NivelChip extends StatelessWidget {
  final String nivel;
  const _NivelChip({required this.nivel});

  Color _cor() {
    final n = int.tryParse(nivel) ?? 0;
    if (n <= 1) return Colors.green;
    if (n == 2) return Colors.orange;
    return Colors.red;
  }

  String _rotulo() {
    final n = int.tryParse(nivel) ?? 0;
    if (n <= 1) return 'Iniciante';
    if (n == 2) return 'Intermediário';
    return 'Avançado';
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(Icons.bar_chart, color: _cor(), size: 18),
      label: Text('$_rotulo() (nível $nivel)'),
      side: BorderSide(color: _cor()),
      backgroundColor: _cor().withValues(alpha: 0.1),
    );
  }
}

class _FotoPreview extends StatelessWidget {
  final String url;
  final VoidCallback onAbrirLink;

  const _FotoPreview({required this.url, required this.onAbrirLink});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onAbrirLink,
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Abrir imagem em nova aba'),
        ),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  final String url;
  final IconData icone;
  final String rotulo;
  final Color cor;
  final VoidCallback onAbrirLink;

  const _LinkCard({
    required this.url,
    required this.icone,
    required this.rotulo,
    required this.cor,
    required this.onAbrirLink,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icone, color: cor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                url,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onAbrirLink,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(rotulo),
              style: ElevatedButton.styleFrom(backgroundColor: cor),
            ),
          ],
        ),
      ),
    );
  }
}
