import 'dart:convert';

import 'package:flutter/material.dart';

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/tenant_context.dart';

/// Linha do tempo de UMA NFS-e: criacao, faturamento, autorizacao, consultas,
/// cancelamento e desfazimento financeiro, com quem fez e de onde veio.
class NfseAuditoriaTimelineDialog extends StatefulWidget {
  final String nfseId;
  final String? numero;

  /// Fonte dos eventos. Padrao: GET do historico no backend. Injetavel para testes.
  final Future<List<Map<String, dynamic>>> Function(String nfseId)? carregador;

  const NfseAuditoriaTimelineDialog({super.key, required this.nfseId, this.numero, this.carregador});

  @override
  State<NfseAuditoriaTimelineDialog> createState() => _NfseAuditoriaTimelineDialogState();
}

class _NfseAuditoriaTimelineDialogState extends State<NfseAuditoriaTimelineDialog> {
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _eventos = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final eventos = widget.carregador != null
          ? await widget.carregador!(widget.nfseId)
          : await _buscarNoBackend(widget.nfseId);
      if (!mounted) return;
      setState(() {
        _eventos = eventos;
        _carregando = false;
      });
    } catch (e, stack) {
      AppLogger.i.error('[NFSE-AUDITORIA] falha ao carregar historico da NFS-e ${widget.nfseId}: $e', stack);
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  static Future<List<Map<String, dynamic>>> _buscarNoBackend(String nfseId) async {
    final response = await TenantContext.get(ApiLinks.historicoNfse(nfseId));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final lista = jsonDecode(response.body) as List<dynamic>;
    return lista.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titulo = widget.numero != null && widget.numero!.isNotEmpty
        ? 'NFS-e nº ${widget.numero}'
        : 'NFS-e sem número';
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.history, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auditoria da NFS-e', style: Theme.of(context).textTheme.titleLarge),
                        Text(titulo, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(child: _corpo(context)),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fechar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _carregando ? null : _carregar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Atualizar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corpo(BuildContext context) {
    if (_carregando) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Carregando auditoria…'),
            ],
          ),
        ),
      );
    }
    if (_erro != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 40),
            const SizedBox(height: 12),
            const Text('Não foi possível carregar a auditoria.', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('Verifique a conexão e tente novamente.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: _carregar, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_eventos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, size: 40),
            SizedBox(height: 12),
            Text('Nenhum evento de auditoria registrado para esta nota.', textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: _eventos.length,
      itemBuilder: (context, i) => _Evento(
        evento: _eventos[i],
        ultimo: i == _eventos.length - 1,
      ),
    );
  }
}

/// Descricao visual de um tipo de evento (icone, rotulo e cores do tema).
class _Estilo {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final Color fundo;
  final Color texto;

  const _Estilo(this.icone, this.titulo, this.subtitulo, this.fundo, this.texto);
}

_Estilo _estiloDe(String acao, ColorScheme cs) {
  switch (acao) {
    case 'CRIADA':
      return _Estilo(Icons.note_add_outlined, 'Nota criada',
          'Gerada pelo faturamento da mensalidade', cs.secondaryContainer, cs.onSecondaryContainer);
    case 'FATURADA':
      return _Estilo(Icons.receipt_long_outlined, 'Nota faturada',
          'Mensalidade, títulos e PDF no GED gerados', cs.secondaryContainer, cs.onSecondaryContainer);
    case 'AUTORIZADA':
      return _Estilo(Icons.verified_outlined, 'Nota autorizada', 'NFS-e autorizada pela prefeitura ou Portal Nacional',
          cs.primaryContainer, cs.onPrimaryContainer);
    case 'CONSULTA_STATUS':
      return _Estilo(Icons.travel_explore, 'Consulta no Portal Nacional', 'Resultado descrito no detalhe',
          cs.tertiaryContainer, cs.onTertiaryContainer);
    case 'CANCELADA':
      return _Estilo(Icons.cancel_outlined, 'Cancelamento', 'Cancelamento da NFS-e', cs.errorContainer,
          cs.onErrorContainer);
    case 'FINANCEIRO_DESFEITO':
      return _Estilo(Icons.undo, 'Financeiro desfeito',
          'Títulos cancelados, PDF removido do GED e saldo recalculado', cs.surfaceContainerHighest,
          cs.onSurfaceVariant);
    default:
      return _Estilo(Icons.circle_outlined, acao, '', cs.surfaceContainerHighest, cs.onSurfaceVariant);
  }
}

String _origemRotulo(String? origem) {
  switch (origem) {
    case 'SISTEMA':
      return 'Sistema';
    case 'PORTAL_NACIONAL':
      return 'Portal Nacional';
    case 'WEBISS':
      return 'WebISS';
    default:
      return origem ?? '-';
  }
}

String _dataHora(String? iso) {
  final d = iso == null ? null : DateTime.tryParse(iso);
  if (d == null) return iso ?? '-';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} às ${two(d.hour)}:${two(d.minute)}';
}

class _Evento extends StatelessWidget {
  final Map<String, dynamic> evento;
  final bool ultimo;

  const _Evento({required this.evento, required this.ultimo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final acao = evento['acao']?.toString() ?? '';
    final estilo = _estiloDe(acao, cs);
    final data = _dataHora(evento['dataEvento']?.toString());
    final usuarioId = evento['usuarioId'];
    final nomeUsuario = evento['usuarioNome']?.toString();
    final usuario = usuarioId == null
        ? 'Automático'
        : (nomeUsuario != null && nomeUsuario.isNotEmpty ? nomeUsuario : 'Usuário nº $usuarioId');
    final origem = _origemRotulo(evento['origem']?.toString());
    final detalhe = evento['detalhe']?.toString() ?? '';

    return Semantics(
      label: '${estilo.titulo}, $data, $usuario, origem $origem. $detalhe',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: estilo.fundo,
                  child: Icon(estilo.icone, size: 18, color: estilo.texto),
                ),
                if (!ultimo)
                  Expanded(child: Container(width: 2, color: cs.outlineVariant)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: ultimo ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(estilo.titulo,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(data, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                    if (estilo.subtitulo.isNotEmpty)
                      Text(estilo.subtitulo, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.person_outline, size: 16),
                          label: Text(usuario),
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.hub_outlined, size: 16),
                          label: Text('Origem: $origem'),
                        ),
                      ],
                    ),
                    if (detalhe.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(detalhe, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
