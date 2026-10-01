import 'package:flutter/material.dart';
import '../../models/manifestacao/manifestacao_model.dart';
import '../../screens/nfe/design_tokens.dart';
import '../../core/constants/manifestacao_constants.dart';

/// Card compacto com informações da NFe
/// Responsivo: vertical em mobile, horizontal em desktop
/// WCAG 2.1 AA: touch targets 48×48dp, contrast ≥ 4.5:1
class NfeInfoCard extends StatelessWidget {
  /// Dados da manifestação
  final ManifestacaoModel manifestacao;

  /// Se deve usar tema dark
  final bool isDarkMode;

  const NfeInfoCard({
    Key? key,
    required this.manifestacao,
    this.isDarkMode = false,
  }) : super(key: key);

  /// Retorna cor de background baseada no tema
  Color _getBackgroundColor() {
    return isDarkMode
        ? const Color(0xFF1F1F1F)
        : ManifestacaoDesignTokens.colorNeutral100;
  }

  /// Retorna cor de texto primário
  Color _getTextPrimaryColor() {
    return isDarkMode
        ? const Color(0xFFF0F0F0)
        : ManifestacaoDesignTokens.colorNeutral900;
  }

  /// Retorna cor de texto secundário
  Color _getTextSecondaryColor() {
    return isDarkMode
        ? const Color(0xFFB0B0B0)
        : ManifestacaoDesignTokens.colorNeutral600;
  }

  /// Retorna cor de borda
  Color _getBorderColor() {
    return isDarkMode
        ? const Color(0xFF404040)
        : ManifestacaoDesignTokens.colorNeutral300;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= ManifestacaoConstants.breakpointTablet;

    return Semantics(
      label: 'Informações da NFe ${manifestacao.nfeId}',
      enabled: true,
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(color: _getBorderColor()),
          borderRadius: BorderRadius.circular(ManifestacaoConstants.raioCard),
        ),
        padding: const EdgeInsets.all(ManifestacaoConstants.cardPadding),
        child: isTablet
            ? _buildHorizontalLayout()
            : _buildVerticalLayout(),
      ),
    );
  }

  /// Layout vertical para mobile
  Widget _buildVerticalLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNfeInfo(),
        const SizedBox(height: 12),
        _buildCompanyInfo(),
      ],
    );
  }

  /// Layout horizontal para tablet/desktop
  Widget _buildHorizontalLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 1,
          child: _buildNfeInfo(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildCompanyInfo(),
        ),
      ],
    );
  }

  /// Widget com dados da NFe (número e data)
  Widget _buildNfeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NFe',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _getTextSecondaryColor(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          manifestacao.nfeId,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _getTextPrimaryColor(),
            fontFamily: 'Roboto Mono',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Data',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _getTextSecondaryColor(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatarData(manifestacao.dataEmissao),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _getTextSecondaryColor(),
            fontFamily: 'Roboto Mono',
          ),
        ),
      ],
    );
  }

  /// Widget com dados da empresa
  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Empresa',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _getTextSecondaryColor(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          manifestacao.nomeEmpresa ?? 'N/A',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _getTextPrimaryColor(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'CNPJ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _getTextSecondaryColor(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatarCnpj(manifestacao.cnpjEmpresa ?? ''),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _getTextSecondaryColor(),
            fontFamily: 'Roboto Mono',
          ),
        ),
      ],
    );
  }

  /// Formata data em ISO 8601
  String _formatarData(DateTime? data) {
    if (data == null) return '-';
    return '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}';
  }

  /// Formata CNPJ: XX.XXX.XXX/XXXX-XX
  String _formatarCnpj(String cnpj) {
    if (cnpj.isEmpty) return '-';
    if (cnpj.length < 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/'
        '${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
  }
}
