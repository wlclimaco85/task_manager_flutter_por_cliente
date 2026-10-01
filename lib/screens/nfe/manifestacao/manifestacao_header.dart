import 'package:flutter/material.dart';
import '../../../models/manifestacao/manifestacao_model.dart';
import '../design_tokens.dart';

/// Header da tela de manifestação com dados da NFe (read-only)
class ManifestacaoHeader extends StatelessWidget {
  final ManifestacaoModel manifestacao;

  const ManifestacaoHeader({
    Key? key,
    required this.manifestacao,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <
        ManifestacaoDesignTokens.breakpointTablet;

    return Container(
      color: ManifestacaoDesignTokens.colorNeutral50,
      child: Column(
        children: [
          // AppBar
          Container(
            color: ManifestacaoDesignTokens.colorPrimary,
            padding: EdgeInsets.all(ManifestacaoDesignTokens.spacing16),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: ManifestacaoDesignTokens.tapTargetMinimum / 1.5,
                    ),
                  ),
                  SizedBox(width: ManifestacaoDesignTokens.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manifestação',
                          style: ManifestacaoDesignTokens.textHeadline2
                              .copyWith(color: Colors.white),
                        ),
                        SizedBox(height: ManifestacaoDesignTokens.spacing4),
                        Text(
                          'NFe ${manifestacao.numero}',
                          style: ManifestacaoDesignTokens.textBodySmall
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dados da NFe
          Padding(
            padding: EdgeInsets.all(ManifestacaoDesignTokens.spacing16),
            child: Column(
              children: [
                // Card com dados
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ManifestacaoDesignTokens.radiusMedium,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(ManifestacaoDesignTokens.spacing16),
                    child: Column(
                      children: [
                        _buildDataRow(
                          'Fornecedor',
                          manifestacao.fornecedor,
                        ),
                        SizedBox(height: ManifestacaoDesignTokens.spacing12),
                        Divider(
                          color: ManifestacaoDesignTokens.colorNeutral200,
                          height: 1,
                        ),
                        SizedBox(height: ManifestacaoDesignTokens.spacing12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDataRow(
                                'Valor',
                                manifestacao.valor,
                              ),
                            ),
                            SizedBox(width: ManifestacaoDesignTokens.spacing12),
                            Expanded(
                              child: _buildDataRow(
                                'Data',
                                _formatDate(manifestacao.dataEmissao),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói linha de dados (rótulo + valor)
  Widget _buildDataRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ManifestacaoDesignTokens.textBodySmall.copyWith(
            color: ManifestacaoDesignTokens.colorNeutral500,
          ),
        ),
        SizedBox(height: ManifestacaoDesignTokens.spacing4),
        Text(
          value,
          style: ManifestacaoDesignTokens.textBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Formata data para exibição
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
