import 'package:flutter/material.dart';
import '../../../providers/manifestacao_notifier.dart';
import '../design_tokens.dart';

/// Footer com botões de ação (Aceitar, Recusar, Parcial)
class ManifestacaoFooter extends StatelessWidget {
  final ManifestacaoNotifier notifier;
  final VoidCallback onAceitarTap;
  final VoidCallback onRecusarTap;
  final VoidCallback onParcialTap;

  const ManifestacaoFooter({
    Key? key,
    required this.notifier,
    required this.onAceitarTap,
    required this.onRecusarTap,
    required this.onParcialTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <
        ManifestacaoDesignTokens.breakpointTablet;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [ManifestacaoDesignTokens.shadowMedium],
      ),
      padding: EdgeInsets.all(ManifestacaoDesignTokens.spacing16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Erro (se houver)
            if (notifier.errorMessage != null) ...[
              Container(
                padding: EdgeInsets.all(ManifestacaoDesignTokens.spacing12),
                decoration: BoxDecoration(
                  color: ManifestacaoDesignTokens.colorError.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    ManifestacaoDesignTokens.radiusMedium,
                  ),
                  border: Border.all(
                    color: ManifestacaoDesignTokens.colorError.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: ManifestacaoDesignTokens.colorError,
                    ),
                    SizedBox(width: ManifestacaoDesignTokens.spacing8),
                    Expanded(
                      child: Text(
                        notifier.errorMessage!,
                        style: ManifestacaoDesignTokens.textBodySmall.copyWith(
                          color: ManifestacaoDesignTokens.colorError,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ManifestacaoDesignTokens.spacing12),
            ],

            // Botões
            isMobile
                ? _buildMobileLayout()
                : _buildDesktopLayout(context),
          ],
        ),
      ),
    );
  }

  /// Layout mobile: botões empilhados
  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: ManifestacaoDesignTokens.buttonHeightLarge,
          child: ElevatedButton.icon(
            onPressed: notifier.isSubmitting ? null : onAceitarTap,
            icon: Icon(Icons.check_circle),
            label: Text('Aceitar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ManifestacaoDesignTokens.colorSuccess,
              disabledBackgroundColor:
                  ManifestacaoDesignTokens.colorNeutral300,
            ),
          ),
        ),
        SizedBox(height: ManifestacaoDesignTokens.spacing12),
        SizedBox(
          width: double.infinity,
          height: ManifestacaoDesignTokens.buttonHeightLarge,
          child: ElevatedButton.icon(
            onPressed: notifier.isSubmitting ? null : onRecusarTap,
            icon: Icon(Icons.cancel),
            label: Text('Recusar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ManifestacaoDesignTokens.colorError,
              disabledBackgroundColor:
                  ManifestacaoDesignTokens.colorNeutral300,
            ),
          ),
        ),
        SizedBox(height: ManifestacaoDesignTokens.spacing12),
        SizedBox(
          width: double.infinity,
          height: ManifestacaoDesignTokens.buttonHeightLarge,
          child: OutlinedButton.icon(
            onPressed: notifier.isSubmitting ? null : onParcialTap,
            icon: Icon(Icons.assignment_late),
            label: Text('Parcial'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: ManifestacaoDesignTokens.colorWarning,
                width: 2,
              ),
              foregroundColor: ManifestacaoDesignTokens.colorWarning,
              disabledForegroundColor:
                  ManifestacaoDesignTokens.colorNeutral300,
            ),
          ),
        ),
      ],
    );
  }

  /// Layout desktop: botões lado a lado
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: ManifestacaoDesignTokens.buttonHeightLarge,
            child: ElevatedButton.icon(
              onPressed: notifier.isSubmitting ? null : onAceitarTap,
              icon: Icon(Icons.check_circle),
              label: Text('Aceitar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ManifestacaoDesignTokens.colorSuccess,
                disabledBackgroundColor:
                    ManifestacaoDesignTokens.colorNeutral300,
              ),
            ),
          ),
        ),
        SizedBox(width: ManifestacaoDesignTokens.spacing12),
        Expanded(
          child: SizedBox(
            height: ManifestacaoDesignTokens.buttonHeightLarge,
            child: ElevatedButton.icon(
              onPressed: notifier.isSubmitting ? null : onRecusarTap,
              icon: Icon(Icons.cancel),
              label: Text('Recusar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ManifestacaoDesignTokens.colorError,
                disabledBackgroundColor:
                    ManifestacaoDesignTokens.colorNeutral300,
              ),
            ),
          ),
        ),
        SizedBox(width: ManifestacaoDesignTokens.spacing12),
        Expanded(
          child: SizedBox(
            height: ManifestacaoDesignTokens.buttonHeightLarge,
            child: OutlinedButton.icon(
              onPressed: notifier.isSubmitting ? null : onParcialTap,
              icon: Icon(Icons.assignment_late),
              label: Text('Parcial'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: ManifestacaoDesignTokens.colorWarning,
                  width: 2,
                ),
                foregroundColor: ManifestacaoDesignTokens.colorWarning,
                disabledForegroundColor:
                    ManifestacaoDesignTokens.colorNeutral300,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
