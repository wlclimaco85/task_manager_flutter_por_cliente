import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';

/// Barra de ações adaptativa para operações com NFe
///
/// Mobile: FloatingActionButton (FAB)
/// Tablet/Desktop: Row com inline buttons
///
/// Integra-se com state management via callbacks
class NfeActionBar extends StatelessWidget {
  final Breakpoint breakpoint;
  final VoidCallback onCreatePressed;
  final VoidCallback onImportPressed;
  final VoidCallback onFilterPressed;

  const NfeActionBar({
    super.key,
    required this.breakpoint,
    required this.onCreatePressed,
    required this.onImportPressed,
    required this.onFilterPressed,
  });

  /// Constrói botão primário padrão com tap target 48dp+
  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isCompact = false,
  }) {
    if (isCompact) {
      // Ícone pequeno (tablet)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: DesignTokens.primary, size: 20),
            ),
          ),
        ),
      );
    }

    // Botão com texto (desktop)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: DesignTokens.primary,
          foregroundColor: DesignTokens.textPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (breakpoint) {
      case Breakpoint.mobile:
        // Mobile: FloatingActionButton
        return FloatingActionButton.extended(
          onPressed: onCreatePressed,
          backgroundColor: DesignTokens.primary,
          foregroundColor: DesignTokens.textPrimary,
          icon: const Icon(Icons.add),
          label: const Text('Criar NFe'),
        );

      case Breakpoint.tablet:
        // Tablet: Row com ícones (compacto)
        return Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          child: Row(
            children: [
              _buildPrimaryButton(
                label: 'Criar',
                icon: Icons.add,
                onPressed: onCreatePressed,
                isCompact: true,
              ),
              _buildPrimaryButton(
                label: 'Importar',
                icon: Icons.upload_file,
                onPressed: onImportPressed,
                isCompact: true,
              ),
              _buildPrimaryButton(
                label: 'Filtrar',
                icon: Icons.filter_list,
                onPressed: onFilterPressed,
                isCompact: true,
              ),
            ],
          ),
        );

      case Breakpoint.desktop:
        // Desktop: Row com botões expandidos (texto + ícone)
        return Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingLg),
          child: Row(
            children: [
              _buildPrimaryButton(
                label: 'Criar NFe',
                icon: Icons.add,
                onPressed: onCreatePressed,
              ),
              _buildPrimaryButton(
                label: 'Importar',
                icon: Icons.upload_file,
                onPressed: onImportPressed,
              ),
              _buildPrimaryButton(
                label: 'Filtrar',
                icon: Icons.filter_list,
                onPressed: onFilterPressed,
              ),
              const Spacer(),
            ],
          ),
        );
    }
  }
}
