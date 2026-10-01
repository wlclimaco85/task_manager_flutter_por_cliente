import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'ambiente_badge.dart';

/// Barra superior de nota fiscal com título, badge de ambiente e ações.
///
/// Substitui o AppBar padrão nas telas NF-e e NFSe para manter
/// identidade visual consistente com tokens GridColors.
class NfStatusBar extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final String? ambiente;
  final IconData icone;
  final VoidCallback? onSalvarRascunho;
  final VoidCallback? onEmitir;
  final bool podEmitir;
  final bool loading;
  /// Ação alternativa (ex: "+ Nova NFSe") usada na tela de listagem.
  final Widget? acaoExtra;

  const NfStatusBar({
    super.key,
    required this.titulo,
    this.ambiente,
    this.icone = Icons.receipt_long,
    this.onSalvarRascunho,
    this.onEmitir,
    this.podEmitir = true,
    this.loading = false,
    this.acaoExtra,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: GridColors.shellBackground,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(icone, color: GridColors.textPrimary, size: 20),
          const SizedBox(width: 10),
          Text(
            titulo,
            style: const TextStyle(
              color: GridColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (ambiente != null) ...[
            const SizedBox(width: 12),
            AmbienteBadge(ambiente: ambiente!),
          ],
          const Spacer(),
          if (loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          if (acaoExtra != null) ...[
            const SizedBox(width: 8),
            acaoExtra!,
          ],
          if (onSalvarRascunho != null) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: loading ? null : onSalvarRascunho,
              icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
              label: const Text('Salvar', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
          if (onEmitir != null) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: (loading || !podEmitir) ? null : onEmitir,
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Emitir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
