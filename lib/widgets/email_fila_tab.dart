import 'package:flutter/material.dart';

import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import 'smtp_config_tab.dart' show SmtpConfigScope;

/// Aba "Fila de e-mails" da Empresa/Parceiro: situacao dos e-mails enviados pelo sistema (pendente, enviando, enviado,
/// erro, cancelado) com motivo do erro e as acoes reenviar, cancelar, excluir e ver o HTML enviado.
class EmailFilaTab extends StatefulWidget {
  final SmtpConfigScope scope;
  final int id;
  final String? nome;

  const EmailFilaTab({super.key, required this.scope, required this.id, this.nome});

  @override
  State<EmailFilaTab> createState() => _EmailFilaTabState();
}

class _EmailFilaTabState extends State<EmailFilaTab> {
  static const _tamanho = 20;
  static const _situacoes = {
    '': 'Todas',
    'PENDENTE': 'Pendentes',
    'ENVIANDO': 'Enviando',
    'ENVIADO': 'Enviados',
    'ERRO': 'Com erro',
    'CANCELADO': 'Cancelados',
  };

  List<Map<String, dynamic>> _itens = [];
  Map<String, dynamic> _resumo = {};
  int _pagina = 0;
  int _total = 0;
  String _status = '';
  bool _loading = true;
  String? _erro;

  String get _escopoQuery => widget.scope == SmtpConfigScope.empresa
      ? 'empresaId=${widget.id}'
      : 'parceiroId=${widget.id}';

  @override
  void initState() {
    super.initState();
    if (widget.id <= 0) {
      _loading = false;
    } else {
      _carregar();
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final filtro = _status.isEmpty ? '' : '&status=$_status';
      final lista = await NetworkCaller()
          .getRequest('${ApiLinks.emailFila}?$_escopoQuery$filtro&pagina=$_pagina&tamanho=$_tamanho');
      final resumo = await NetworkCaller().getRequest('${ApiLinks.emailFilaResumo}?$_escopoQuery');
      if (!mounted) return;
      if (lista.isSuccess && lista.body?['itens'] is List) {
        _itens = (lista.body!['itens'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        _total = int.tryParse('${lista.body!['total']}') ?? _itens.length;
      } else {
        _erro = 'Nao foi possivel carregar a fila (HTTP ${lista.statusCode}).';
      }
      if (resumo.isSuccess && resumo.body != null) _resumo = resumo.body!;
    } catch (e, st) {
      AppLogger.i.error('EmailFilaTab: erro ao carregar a fila: $e', st);
      _erro = 'Nao foi possivel carregar a fila: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _acao(String rotulo, Future<dynamic> Function() chamada) async {
    try {
      final r = await chamada();
      if (r.isSuccess) {
        _aviso('$rotulo: ok.');
        await _carregar();
      } else {
        _aviso('$rotulo: falhou (HTTP ${r.statusCode})');
      }
    } catch (e, st) {
      AppLogger.i.error('EmailFilaTab: erro em "$rotulo": $e', st);
      _aviso('$rotulo: $e');
    }
  }

  Future<void> _verHtml(Map<String, dynamic> item) async {
    try {
      final r = await NetworkCaller().getRequest(ApiLinks.emailFilaPorId(item['id']));
      if (!mounted) return;
      if (!r.isSuccess) {
        _aviso('Nao foi possivel abrir o e-mail (HTTP ${r.statusCode}).');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${item['assunto'] ?? 'E-mail'}'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(child: SelectableText('${r.body?['html'] ?? ''}')),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
        ),
      );
    } catch (e, st) {
      AppLogger.i.error('EmailFilaTab: erro ao abrir e-mail: $e', st);
      _aviso('Nao foi possivel abrir o e-mail: $e');
    }
  }

  Color _corDe(String status, ColorScheme c) {
    switch (status) {
      case 'ENVIADO':
        return c.primary;
      case 'ERRO':
        return c.error;
      case 'CANCELADO':
        return c.outline;
      default:
        return c.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id <= 0) {
      return const Center(child: Text('Salve o cadastro antes de ver a fila de e-mails.'));
    }
    final tema = Theme.of(context);
    final paginas = (_total / _tamanho).ceil();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Fila de e-mails', style: tema.textTheme.titleLarge),
              DropdownButton<String>(
                key: const Key('email_fila_filtro'),
                value: _status,
                items: [
                  for (final e in _situacoes.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) {
                  _status = v ?? '';
                  _pagina = 0;
                  _carregar();
                },
              ),
              OutlinedButton.icon(
                key: const Key('email_fila_teste'),
                onPressed: _loading
                    ? null
                    : () => _acao(
                          'E-mail de teste',
                          () => NetworkCaller().postRequest(ApiLinks.emailFilaEnviarTeste,
                              {widget.scope == SmtpConfigScope.empresa ? 'empresaId' : 'parceiroId': widget.id}),
                        ),
                icon: const Icon(Icons.send),
                label: const Text('Enviar teste'),
              ),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: _loading ? null : _carregar,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final e in const {
                'pendentes': 'Pendentes',
                'enviando': 'Enviando',
                'enviados': 'Enviados',
                'erros': 'Com erro',
                'cancelados': 'Cancelados',
              }.entries)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${e.value}: ${_resumo[e.key] ?? 0}'),
                ),
            ],
          ),
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_erro!, style: TextStyle(color: tema.colorScheme.error)),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _itens.isEmpty
                    ? const Center(child: Text('Nenhum e-mail na fila.'))
                    : ListView.separated(
                        itemCount: _itens.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _linha(_itens[i], tema),
                      ),
          ),
          if (paginas > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Anterior',
                  onPressed: _pagina > 0 && !_loading ? () { _pagina--; _carregar(); } : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${_pagina + 1} / $paginas'),
                IconButton(
                  tooltip: 'Proxima',
                  onPressed: _pagina + 1 < paginas && !_loading ? () { _pagina++; _carregar(); } : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _linha(Map<String, dynamic> item, ThemeData tema) {
    final status = '${item['status']}';
    final erro = item['erro'];
    return ListTile(
      key: Key('email_fila_item_${item['id']}'),
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      title: Text('${item['assunto'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(status, style: TextStyle(color: _corDe(status, tema.colorScheme), fontWeight: FontWeight.bold)),
            Text('Para: ${item['destinatario'] ?? '(sem e-mail)'}'),
            Text('Tentativas: ${item['tentativas'] ?? 0}'),
            if (erro != null && '$erro'.isNotEmpty)
              Text('Motivo: $erro', style: TextStyle(color: tema.colorScheme.error)),
          ],
        ),
      ),
      trailing: Wrap(
        children: [
          IconButton(
            tooltip: 'Ver e-mail',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () => _verHtml(item),
            icon: const Icon(Icons.visibility),
          ),
          if (status == 'ERRO' || status == 'CANCELADO')
            IconButton(
              tooltip: 'Reenviar',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: () => _acao('Reenviar', () => NetworkCaller().postRequest(ApiLinks.emailFilaAcao(item['id'], 'reenviar'), {})),
              icon: const Icon(Icons.replay),
            ),
          if (status == 'PENDENTE')
            IconButton(
              tooltip: 'Cancelar',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: () => _acao('Cancelar', () => NetworkCaller().postRequest(ApiLinks.emailFilaAcao(item['id'], 'cancelar'), {})),
              icon: const Icon(Icons.cancel_outlined),
            ),
          if (status != 'ENVIANDO' && status != 'PENDENTE')
            IconButton(
              tooltip: 'Excluir do historico',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: () => _acao('Excluir', () => NetworkCaller().deleteRequest(ApiLinks.emailFilaPorId(item['id']))),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }
}
