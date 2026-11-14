import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../helpers/download_helper.dart';
import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import 'smtp_config_tab.dart' show SmtpConfigScope;

/// Aba "Modelos de e-mail" da Empresa/Parceiro: lista os modelos do escopo (padrao do sistema, da empresa ou do
/// parceiro) e permite baixar o HTML, alterar, excluir (volta a herdar o padrao) e inserir. Usa as cores do tema do app.
class EmailModelosTab extends StatefulWidget {
  final SmtpConfigScope scope;
  final int id;
  final String? nome;

  const EmailModelosTab({super.key, required this.scope, required this.id, this.nome});

  @override
  State<EmailModelosTab> createState() => _EmailModelosTabState();
}

class _EmailModelosTabState extends State<EmailModelosTab> {
  List<Map<String, dynamic>> _modelos = [];
  bool _loading = true;
  String? _erro;

  String get _escopoQuery => widget.scope == SmtpConfigScope.empresa
      ? 'empresaId=${widget.id}'
      : 'parceiroId=${widget.id}';

  Map<String, dynamic> get _escopoBody => widget.scope == SmtpConfigScope.empresa
      ? {'empresaId': widget.id}
      : {'parceiroId': widget.id};

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
      final r = await NetworkCaller().getRequest('${ApiLinks.emailModelos}?$_escopoQuery');
      if (!mounted) return;
      final data = r.body?['data'];
      if (r.isSuccess && data is List) {
        _modelos = data.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      } else {
        _erro = 'Nao foi possivel carregar os modelos (HTTP ${r.statusCode}).';
      }
    } catch (e, st) {
      AppLogger.i.error('EmailModelosTab: erro ao carregar modelos: $e', st);
      _erro = 'Nao foi possivel carregar os modelos: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _baixar(Map<String, dynamic> m) async {
    final nomeArquivo = '${m['tipo'] ?? 'modelo'}.html'.toLowerCase();
    try {
      final bytes = utf8.encode('${m['html'] ?? ''}');
      if (kIsWeb) {
        await downloadBytes(bytes, nomeArquivo, mimeType: 'text/html');
        _aviso('Download de $nomeArquivo iniciado.');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$nomeArquivo');
        await file.writeAsBytes(bytes, flush: true);
        _aviso('HTML salvo em ${file.path}');
      }
    } catch (e, st) {
      AppLogger.i.error('EmailModelosTab: erro ao baixar HTML: $e', st);
      _aviso('Nao foi possivel baixar o HTML: $e');
    }
  }

  Future<void> _editar(Map<String, dynamic>? modelo) async {
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _EditorModeloDialog(modelo: modelo, escopoBody: _escopoBody),
    );
    if (salvo == true) {
      _aviso('Modelo salvo.');
      _carregar();
    }
  }

  Future<void> _excluir(Map<String, dynamic> m) async {
    final herdado = m['herdado'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir modelo'),
        content: Text(herdado
            ? 'Este modelo vem de um nivel acima e nao pode ser excluido aqui.'
            : 'Excluir o modelo personalizado? O e-mail volta a usar o modelo padrao.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          if (!herdado)
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final r = await NetworkCaller().deleteRequest(ApiLinks.emailModeloPorId(m['id']));
      if (r.isSuccess) {
        _aviso('Modelo excluido.');
        _carregar();
      } else {
        _aviso('Nao foi possivel excluir (HTTP ${r.statusCode}).');
      }
    } catch (e, st) {
      AppLogger.i.error('EmailModelosTab: erro ao excluir modelo: $e', st);
      _aviso('Nao foi possivel excluir: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id <= 0) {
      return const Center(child: Text('Salve o cadastro antes de configurar os modelos de e-mail.'));
    }
    final tema = Theme.of(context);
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
              Text('Modelos de e-mail', style: tema.textTheme.titleLarge),
              FilledButton.icon(
                key: const Key('email_modelo_inserir'),
                onPressed: () => _editar(null),
                icon: const Icon(Icons.add),
                label: const Text('Inserir'),
              ),
              IconButton(
                tooltip: 'Atualizar',
                onPressed: _loading ? null : _carregar,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_erro!, style: TextStyle(color: tema.colorScheme.error)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _modelos.isEmpty
                    ? const Center(child: Text('Nenhum modelo encontrado.'))
                    : ListView.separated(
                        itemCount: _modelos.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _linha(_modelos[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _linha(Map<String, dynamic> m) {
    final tema = Theme.of(context);
    final origem = '${m['origem'] ?? 'PADRAO'}';
    final rotuloOrigem = origem == 'PARCEIRO' ? 'Parceiro' : origem == 'EMPRESA' ? 'Empresa' : 'Padrão do sistema';
    return ListTile(
      key: Key('email_modelo_${m['tipo']}'),
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      title: Text('${m['nome'] ?? m['tipo']}'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              label: Text(rotuloOrigem),
              visualDensity: VisualDensity.compact,
              backgroundColor: tema.colorScheme.secondaryContainer,
            ),
            Text('Assunto: ${m['assunto'] ?? ''}', overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      trailing: Wrap(
        spacing: 0,
        children: [
          IconButton(
            tooltip: 'Baixar HTML',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () => _baixar(m),
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: m['herdado'] == true ? 'Personalizar' : 'Alterar',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () => _editar(m),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Excluir',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: m['herdado'] == true || m['somenteLeitura'] == true ? null : () => _excluir(m),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

/// Editor de um modelo: assunto + HTML, com previa. Modelo herdado/novo vira um modelo proprio do escopo (POST);
/// modelo proprio e alterado no lugar (PUT).
class _EditorModeloDialog extends StatefulWidget {
  final Map<String, dynamic>? modelo;
  final Map<String, dynamic> escopoBody;

  const _EditorModeloDialog({required this.modelo, required this.escopoBody});

  @override
  State<_EditorModeloDialog> createState() => _EditorModeloDialogState();
}

class _EditorModeloDialogState extends State<_EditorModeloDialog> {
  late final TextEditingController _nome =
      TextEditingController(text: '${widget.modelo?['nome'] ?? ''}');
  late final TextEditingController _assunto =
      TextEditingController(text: '${widget.modelo?['assunto'] ?? ''}');
  late final TextEditingController _html =
      TextEditingController(text: '${widget.modelo?['html'] ?? ''}');
  bool _salvando = false;
  String? _erro;

  String get _tipo => '${widget.modelo?['tipo'] ?? 'CUSTOM'}';

  bool get _proprio =>
      widget.modelo != null && widget.modelo!['herdado'] != true && widget.modelo!['somenteLeitura'] != true;

  @override
  void dispose() {
    _nome.dispose();
    _assunto.dispose();
    _html.dispose();
    super.dispose();
  }

  Map<String, dynamic> _corpo() => {
        ...widget.escopoBody,
        'tipo': _tipo,
        'nome': _nome.text.trim(),
        'assunto': _assunto.text.trim(),
        'html': _html.text,
        'ativo': true,
      };

  // O NetworkCaller descarta o corpo de respostas de erro; por isso a regra do backend (campos permitidos, sem script)
  // e conferida aqui antes de enviar. O backend continua sendo a palavra final.
  static const _camposPermitidos = {
    'nome', 'email', 'codigo', 'validade', 'marca', 'chamada', 'cor_primaria', 'logo_url',
    'logo_html', 'url_acesso', 'play_store_url', 'recursos_html', 'acessos_html', 'empresa',
    'parceiro', 'arquivo', 'link', 'aviso_anexo', 'link_parar',
  };

  String? _validarLocal() {
    final texto = '${_assunto.text} ${_html.text}';
    final usados = RegExp(r'{{s*([A-Za-z_]+)s*}}').allMatches(texto).map((m) => m.group(1)!).toSet();
    final ruins = usados.where((c) => !_camposPermitidos.contains(c)).toList();
    if (ruins.isNotEmpty) return 'Campos desconhecidos: ${ruins.map((c) => '{{$c}}').join(', ')}';
    if (RegExp(r'<s*script', caseSensitive: false).hasMatch(_html.text)) return 'O HTML nao pode ter <script>.';
    final obrigatorio = {'REDEFINIR_SENHA': 'codigo', 'BOAS_VINDAS': 'nome', 'GED_NOVO_ARQUIVO': 'arquivo'}[_tipo];
    if (obrigatorio != null && !usados.contains(obrigatorio)) return 'Este modelo precisa do campo {{$obrigatorio}}.';
    return null;
  }

  String _mensagemErro(dynamic body, int status) => 'Nao foi possivel concluir (HTTP $status). Confira o HTML e os campos.';

  Future<void> _salvar() async {
    if (_assunto.text.trim().isEmpty || _html.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o assunto e o HTML do e-mail.');
      return;
    }
    final invalido = _validarLocal();
    if (invalido != null) {
      setState(() => _erro = invalido);
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final r = _proprio
          ? await NetworkCaller().putRequest(ApiLinks.emailModeloPorId(widget.modelo!['id']), _corpo())
          : await NetworkCaller().postRequest(ApiLinks.emailModelos, _corpo());
      if (!mounted) return;
      if (r.isSuccess) {
        Navigator.pop(context, true);
        return;
      }
      _erro = _mensagemErro(r.body, r.statusCode);
    } catch (e, st) {
      AppLogger.i.error('EmailModelosTab: erro ao salvar modelo: $e', st);
      _erro = 'Nao foi possivel salvar: $e';
    }
    if (mounted) setState(() => _salvando = false);
  }

  Future<void> _previa() async {
    try {
      final r = await NetworkCaller().postRequest(ApiLinks.emailModelosPrevia, {
        ...widget.escopoBody,
        'tipo': _tipo,
        'assunto': _assunto.text.trim(),
        'html': _html.text,
      });
      if (!mounted) return;
      if (!r.isSuccess) {
        setState(() => _erro = _mensagemErro(r.body, r.statusCode));
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Previa: ${r.body?['assunto'] ?? ''}'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(child: SelectableText('${r.body?['html'] ?? ''}')),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))],
        ),
      );
    } catch (e, st) {
      AppLogger.i.error('EmailModelosTab: erro na previa: $e', st);
      if (mounted) setState(() => _erro = 'Nao foi possivel gerar a previa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final novo = widget.modelo == null;
    return AlertDialog(
      title: Text(novo ? 'Novo modelo' : (_proprio ? 'Alterar modelo' : 'Personalizar modelo')),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (novo)
                TextField(
                  key: const Key('email_modelo_nome'),
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Nome do modelo'),
                ),
              TextField(
                key: const Key('email_modelo_assunto'),
                controller: _assunto,
                decoration: const InputDecoration(labelText: 'Assunto'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('email_modelo_html'),
                controller: _html,
                minLines: 10,
                maxLines: 18,
                decoration: const InputDecoration(
                  labelText: 'HTML do e-mail',
                  helperText: 'Campos: {{nome}} {{email}} {{codigo}} {{marca}} {{empresa}} {{parceiro}} {{arquivo}} {{link}}',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _salvando ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: _salvando ? null : _previa, child: const Text('Previa')),
        FilledButton(
          key: const Key('email_modelo_salvar'),
          onPressed: _salvando ? null : _salvar,
          child: Text(_salvando ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
