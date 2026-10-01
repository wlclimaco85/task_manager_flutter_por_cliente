import 'package:flutter/material.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Dialog para visualizar detalhes completos de uma NFe.
/// Exibe: cabeçalho, QR code, valores, destinatário e ações.
class NfeDetailDialog extends StatefulWidget {
  final NfeModel nfe;

  const NfeDetailDialog({
    super.key,
    required this.nfe,
  });

  @override
  State<NfeDetailDialog> createState() => _NfeDetailDialogState();
}

class _NfeDetailDialogState extends State<NfeDetailDialog> {
  @override
  void initState() {
    super.initState();
    L.d('[NfeDetailDialog] Abrindo detalhes da NFe #${widget.nfe.numero}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 64),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: Container(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho com close button
                _buildHeader(isDark),

                // Conteúdo scrollável
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informações principais
                      _buildMainInfo(isDark),
                      const SizedBox(height: 24),

                      // QR Code (placeholder)
                      _buildQrCodeSection(isDark),
                      const SizedBox(height: 24),

                      // Valores
                      _buildValuesSection(isDark),
                      const SizedBox(height: 24),

                      // Destinatário
                      _buildTomadorSection(isDark),
                      const SizedBox(height: 32),

                      // Ações
                      _buildActionsSection(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cabeçalho com título e close button
  Widget _buildHeader(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NFe #${widget.nfe.numero}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Série ${widget.nfe.serie}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  /// Seção de informações principais
  Widget _buildMainInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.nfe.statusNfe.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Informações
        _buildInfoRow('Data Emissão', _formatDateTime(widget.nfe.dataHora)),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Ambiente',
          widget.nfe.ambiente,
          secondary: true,
        ),
        const SizedBox(height: 8),
        if (widget.nfe.protocolo != null)
          _buildInfoRow(
            'Protocolo',
            widget.nfe.protocolo!,
            secondary: true,
          ),
      ],
    );
  }

  /// Seção de QR Code (placeholder)
  Widget _buildQrCodeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_2,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'QR Code',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Seção de valores consolidados
  Widget _buildValuesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valores',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
          ),
          child: Column(
            children: [
              _buildValueRow(
                'Subtotal',
                'R\$ ${widget.nfe.valores.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
              const Divider(height: 12),
              _buildValueRow(
                'ICMS',
                'R\$ ${widget.nfe.valores.totalIcms.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
              const Divider(height: 12),
              _buildValueRow(
                'PIS',
                'R\$ ${widget.nfe.valores.totalPis.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
              const Divider(height: 12),
              _buildValueRow(
                'COFINS',
                'R\$ ${widget.nfe.valores.totalCofins.toStringAsFixed(2).replaceAll('.', ',')}',
              ),
              const Divider(height: 12),
              _buildValueRow(
                'Desconto',
                '-R\$ ${widget.nfe.valores.desconto.toStringAsFixed(2).replaceAll('.', ',')}',
                isHighlight: true,
              ),
              const Divider(height: 12),
              _buildValueRow(
                'Total',
                'R\$ ${widget.nfe.valores.total.toStringAsFixed(2).replaceAll('.', ',')}',
                isHighlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Seção de tomador (destinatário)
  Widget _buildTomadorSection(bool isDark) {
    final tomador = widget.nfe.tomador;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tomador',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tomador.razaoSocial,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'CNPJ/CPF',
                _formatCnpjCpf(tomador.cnpjCpf),
              ),
              const SizedBox(height: 8),
              if (tomador.endereco != null)
                _buildInfoRow(
                  'Endereço',
                  tomador.endereco!,
                  secondary: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Seção de ações
  Widget _buildActionsSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _downloadPdf(context),
            icon: const Icon(Icons.download),
            label: const Text('PDF'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showManifestDialog(context),
            icon: const Icon(Icons.comment),
            label: const Text('Manifestar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Fechar'),
          ),
        ),
      ],
    );
  }

  // Helper methods

  Color _getStatusColor() {
    switch (widget.nfe.statusNfe.code) {
      case 'AUTORIZADA':
        return GridColors.success;
      case 'CANCELADA':
        return GridColors.error;
      case 'REJEITADA':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFFF9A825);
    }
  }

  Widget _buildInfoRow(String label, String value, {bool secondary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondary ? Colors.grey[600] : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildValueRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            color: isHighlight ? GridColors.success : null,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCnpjCpf(String value) {
    if (value.isEmpty) return '';
    if (value.length == 14) {
      // CNPJ: XX.XXX.XXX/XXXX-XX
      return '${value.substring(0, 2)}.${value.substring(2, 5)}.${value.substring(5, 8)}/'
          '${value.substring(8, 12)}-${value.substring(12)}';
    } else if (value.length == 11) {
      // CPF: XXX.XXX.XXX-XX
      return '${value.substring(0, 3)}.${value.substring(3, 6)}.${value.substring(6, 9)}-'
          '${value.substring(9)}';
    }
    return value;
  }

  void _downloadPdf(BuildContext context) {
    L.d('[NfeDetailDialog] Download PDF iniciado para NFe #${widget.nfe.numero}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download PDF em desenvolvimento')),
    );
  }

  void _showManifestDialog(BuildContext context) {
    L.d('[NfeDetailDialog] Manifestação iniciada para NFe #${widget.nfe.numero}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manifestação em desenvolvimento')),
    );
  }
}
