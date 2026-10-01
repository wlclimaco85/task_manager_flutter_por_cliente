import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/responsive/responsive_helper.dart';
import '../../utils/grid_colors.dart';

/// Card com QR code de consulta pública SEFAZ + botão de copiar chave de
/// acesso, usado na tela de detalhes de NF-e (web/windows/mobile).
///
/// Tamanho do QR responsivo por breakpoint: 120px mobile / 140px tablet /
/// 160px desktop. Quando a chave não tem 44 dígitos (NF-e pendente/rejeitada
/// sem chave), mostra um placeholder informativo em vez de tentar gerar QR
/// com dado inválido.
class NfeChaveQrCard extends StatelessWidget {
  final String chave;
  const NfeChaveQrCard({super.key, required this.chave});

  static const _urlBaseConsultaSefaz =
      'https://www.nfe.fazenda.gov.br/portal/consultaRecaptcha.aspx'
      '?tipoConsulta=resumo&tipoConteudo=7PhJ+gAVw2g=&chNFe=';

  bool get _chaveValida => RegExp(r'^\d{44}$').hasMatch(chave);

  double _tamanhoQr(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Usa as constantes estáticas diretamente (evita depender de
    // ResponsiveHelper.getBreakpoint, cuja assinatura static/instância
    // diverge entre task_manager_flutter e task_manager_flutter_merged_final).
    if (width < ResponsiveHelper.breakpointMobile) {
      return 120;
    } else if (width < ResponsiveHelper.breakpointTablet) {
      return 140;
    } else {
      return 160;
    }
  }

  String get _chaveFormatada {
    final buffer = StringBuffer();
    for (var i = 0; i < chave.length; i++) {
      buffer.write(chave[i]);
      if (i % 4 == 3 && i != chave.length - 1) buffer.write(' ');
    }
    return buffer.toString();
  }

  Future<void> _copiarChave(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: chave));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Chave copiada'),
      backgroundColor: GridColors.secondary,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tamanho = _tamanhoQr(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GridColors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GridColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consulta pública SEFAZ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GridColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: _chaveValida
                ? QrImageView(
                    data: '$_urlBaseConsultaSefaz$chave',
                    version: QrVersions.auto,
                    size: tamanho,
                    backgroundColor: Colors.white,
                  )
                : _placeholder(tamanho),
          ),
          if (_chaveValida) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _chaveFormatada,
                    style: const TextStyle(
                        fontSize: 10, color: GridColors.textSecondary),
                  ),
                ),
                Tooltip(
                  message: 'Copiar chave de acesso',
                  child: IconButton(
                    icon: const Icon(Icons.copy_outlined,
                        size: 18, color: GridColors.primary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _copiarChave(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeholder(double tamanho) => Container(
        width: tamanho,
        height: tamanho,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: GridColors.textSecondary.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2_outlined,
                  size: tamanho * 0.4, color: GridColors.textSecondary),
              const SizedBox(height: 6),
              const Text(
                'QR disponível após emissão',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: GridColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}
