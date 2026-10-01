import 'package:flutter/material.dart';

/// Badge que indica modo offline
///
/// Exibe chip com ícone e texto quando offline
class OfflineBadge extends StatelessWidget {
  final bool isOnline;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const OfflineBadge({
    Key? key,
    required this.isOnline,
    this.textStyle,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Chip(
      avatar: const Icon(Icons.cloud_off, size: 14),
      label: Text(
        'Offline',
        style: textStyle ??
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
      ),
      backgroundColor: backgroundColor ?? Colors.orange[200],
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Indicador de sincronização em circular
///
/// Mostra loading enquanto sincroniza
class SyncIndicator extends StatelessWidget {
  final bool isSyncing;
  final DateTime? lastSync;
  final VoidCallback? onRefreshPressed;

  const SyncIndicator({
    Key? key,
    required this.isSyncing,
    this.lastSync,
    this.onRefreshPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (lastSync != null) {
      final diff = DateTime.now().difference(lastSync!);
      final minutos = diff.inMinutes;
      final label = minutos < 1 ? 'agora' : '${minutos}min atrás';

      return Tooltip(
        message: 'Último sync: $label',
        child: IconButton(
          icon: const Icon(Icons.sync, size: 20),
          onPressed: onRefreshPressed,
          tooltip: 'Sincronizar agora',
          splashRadius: 20,
        ),
      );
    }

    return const SizedBox(width: 20);
  }
}

/// Status de transmissão (Enviando... → ✅ Transmitida → ❌ Falha)
class TransmitStatus extends StatelessWidget {
  final String status; // 'enviando', 'transmitida', 'falha'
  final String? protocolo; // Protocolo SEFAZ se disponível

  const TransmitStatus({
    Key? key,
    required this.status,
    this.protocolo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'enviando':
        icon = Icons.hourglass_empty;
        color = Colors.blue;
        label = 'Enviando...';
        break;
      case 'transmitida':
      case 'autorizada':
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Transmitida';
        if (protocolo != null && protocolo!.isNotEmpty) {
          label += ' (${protocolo!.substring(0, 8)}...)';
        }
        break;
      case 'falha':
      case 'rejeitada':
        icon = Icons.error;
        color = Colors.red;
        label = 'Falha na transmissão';
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
        label = 'Status desconhecido';
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      visualDensity: VisualDensity.compact,
    );
  }
}
