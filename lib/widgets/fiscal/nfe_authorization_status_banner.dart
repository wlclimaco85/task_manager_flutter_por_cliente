import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

class NfeAuthorizationStatusBanner extends StatelessWidget {
  final String? status;
  final bool emitindo;
  final EdgeInsetsGeometry? margin;

  const NfeAuthorizationStatusBanner({
    super.key,
    this.status,
    this.emitindo = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final statusText =
        (status?.trim().isNotEmpty ?? false) ? status!.trim() : 'PENDENTE';

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: GridColors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: GridColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Status da autorização',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (emitindo) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 8),
            const Text(
              'Transmitindo para a SEFAZ...',
              style: TextStyle(color: GridColors.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
