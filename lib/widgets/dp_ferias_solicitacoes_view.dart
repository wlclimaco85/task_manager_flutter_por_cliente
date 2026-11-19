import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/api_links.dart';
import '../utils/file_saver_compat.dart';
import '../utils/app_logger.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';

/// Funcionario para escolher nos pedidos do DP.
class DpFuncionarioOpcao {
  final int id;
  final String nome;
  const DpFuncionarioOpcao(this.id, this.nome);
}

/// Lista os funcionarios da empresa da sessao (o TenantContext acrescenta o escopo da empresa na URL).
Future<List<DpFuncionarioOpcao>> carregarFuncionariosDp() async {
  try {
    final resp = await TenantContext.get('${ApiLinks.baseUrl}/api/funcionario?pagina=0&tamanho=200');
    if (resp.statusCode != 200) {
      AppLogger.i.warn('[DP] lista de funcionarios respondeu ${resp.statusCode}');
      return const [];
    }
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    final dados = body is Map ? (body['data'] is Map ? body['data']['dados'] : body['dados']) : body;
    if (dados is! List) return const [];
    return dados
        .whereType<Map>()
        .where((f) => f['id'] is int)
        .map((f) => DpFuncionarioOpcao(f['id'] as int, (f['nome'] ?? 'Funcionário ${f['id']}').toString()))
        .toList();
  } catch (e) {
    AppLogger.i.warn('[DP] falha ao listar funcionarios: $e');
    return const [];
  }
}

/// Quem pode decidir pedidos (a decisao final e' validada no backend pela permissao da tela).
bool dpPodeDecidir(Iterable<String?> roles) {
  return roles.any((r) {
    final k = (r ?? '').toUpperCase();
    return k.contains('MASTER') || k.contains('GESTOR') || k.contains('ADMIN') || k.contains('CONTA_PROPRIA');
  });
}

/// Aba de ferias da tela de solicitacoes: pedir ferias e (quem tem permissao) aprovar ou rejeitar.
class DpFeriasSolicitacoesView extends StatefulWidget {
  final bool podeDecidir;
  const DpFeriasSolicitacoesView({super.key, required this.podeDecidir});

  @override
  State<DpFeriasSolicitacoesView> createState() => DpFeriasSolicitacoesViewState();
}

class DpFeriasSolicitacoesViewState extends State<DpFeriasSolicitacoesView> {
  static const _url = '/api/dp/ferias-solicitacoes';
  final _fmt = DateFormat('dd/MM/yyyy');
  List<Map<String, dynamic>> _itens = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    recarregar();
  }

  Future<void> recarregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final resp = await TenantContext.get('${ApiLinks.baseUrl}$_url');
      if (resp.statusCode == 200) {
        final dados = jsonDecode(utf8.decode(resp.bodyBytes));
        _itens = dados is List ? dados.whereType<Map<String, dynamic>>().toList() : [];
      } else {
        _erro = _mensagem(resp.bodyBytes, 'Não foi possível carregar as férias (${resp.statusCode}).');
      }
    } catch (e, st) {
      AppLogger.i.error('[DP] erro ao carregar solicitacoes de ferias: $e', st);
      _erro = 'Sem conexão com o servidor.';
    }
    if (mounted) setState(() => _loading = false);
  }

  String _mensagem(List<int> bytes, String padrao) {
    try {
      final b = jsonDecode(utf8.decode(bytes));
      if (b is Map && b['message'] is String) return b['message'] as String;
    } catch (_) {}
    return padrao;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _cor(String? s) => switch (s) {
        'APROVADA' || 'GOZANDO' => GridColors.success,
        'REJEITADA' || 'CANCELADA' => GridColors.error,
        _ => Colors.orange,
      };

  Future<void> solicitar() async {
    final funcionarios = await carregarFuncionariosDp();
    if (!mounted) return;
    if (funcionarios.isEmpty) {
      _snack('Nenhum funcionário encontrado para a sua empresa.');
      return;
    }
    int? funcionarioId = funcionarios.first.id;
    DateTime? inicio;
    DateTime? fim;
    String tipo = 'FERIAS'; // FERIAS | MATERNIDADE
    int diasMaternidade = 120; // licenca maternidade: 120 ou 180 dias corridos
    String saldoTexto = 'Consultando saldo...';
    final obs = TextEditingController();
    Future<void> atualizarSaldo(StateSetter setS, int id) async {
      final t = await _saldoDe(id);
      if (ctx0Mounted) setS(() => saldoTexto = t);
    }
    var abriu = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          if (!abriu && funcionarioId != null) {
            abriu = true;
            atualizarSaldo(setS, funcionarioId!);
          }
          return AlertDialog(
          title: const Text('Solicitar férias', style: TextStyle(color: GridColors.primary)),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                key: const Key('ferias_funcionario'),
                initialValue: funcionarioId,
                decoration: const InputDecoration(labelText: 'Funcionário', border: OutlineInputBorder(), isDense: true),
                items: [for (final f in funcionarios) DropdownMenuItem(value: f.id, child: Text(f.nome))],
                onChanged: (v) {
                  setS(() {
                    funcionarioId = v;
                    saldoTexto = 'Consultando saldo...';
                  });
                  if (v != null) atualizarSaldo(setS, v);
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(saldoTexto,
                      key: const Key('ferias_saldo'),
                      style: const TextStyle(fontSize: 12, color: GridColors.textSecondary)),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('ferias_tipo'),
                initialValue: tipo,
                decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'FERIAS', child: Text('Férias')),
                  DropdownMenuItem(value: 'MATERNIDADE', child: Text('Licença maternidade')),
                ],
                onChanged: (v) => setS(() {
                  tipo = v ?? 'FERIAS';
                  fim = null;
                }),
              ),
              if (tipo == 'MATERNIDADE')
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: DropdownButtonFormField<int>(
                    key: const Key('ferias_dias_maternidade'),
                    initialValue: diasMaternidade,
                    decoration: const InputDecoration(labelText: 'Duração', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 120, child: Text('120 dias')),
                      DropdownMenuItem(value: 180, child: Text('180 dias (Empresa Cidadã)')),
                    ],
                    onChanged: (v) => setS(() => diasMaternidade = v ?? 120),
                  ),
                ),
              const SizedBox(height: 8),
              ListTile(
                key: const Key('ferias_inicio'),
                leading: const Icon(Icons.flight_takeoff, color: GridColors.primary),
                title: Text(inicio == null ? 'Início das férias' : _fmt.format(inicio!)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: inicio ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (d != null) setS(() => inicio = d);
                },
              ),
              if (tipo == 'FERIAS') ListTile(
                key: const Key('ferias_fim'),
                leading: const Icon(Icons.flight_land, color: GridColors.primary),
                title: Text(fim == null ? 'Fim das férias' : _fmt.format(fim!)),
                onTap: () async {
                  final base = inicio ?? DateTime.now();
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: fim ?? base.add(const Duration(days: 14)),
                    firstDate: base,
                    lastDate: base.add(const Duration(days: 60)),
                  );
                  if (d != null) setS(() => fim = d);
                },
              ),
              if (tipo == 'FERIAS' && inicio != null && fim != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${fim!.difference(inicio!).inDays + 1} dias corridos',
                        style: const TextStyle(color: GridColors.textSecondary)),
                  ),
                ),
              TextField(
                controller: obs,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Observação', border: OutlineInputBorder(), isDense: true),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              key: const Key('ferias_enviar'),
              onPressed: () async {
                final maternidade = tipo == 'MATERNIDADE';
                if (funcionarioId == null || inicio == null || (!maternidade && fim == null)) {
                  _snack('Informe funcionário, início e fim.');
                  return;
                }
                final fimEfetivo = maternidade
                    ? inicio!.add(Duration(days: diasMaternidade - 1))
                    : fim!;
                final resp = await TenantContext.post('${ApiLinks.baseUrl}$_url', {
                  'funcionarioId': funcionarioId,
                  'tipo': tipo,
                  'dataInicio': DateFormat('yyyy-MM-dd').format(inicio!),
                  'dataFim': DateFormat('yyyy-MM-dd').format(fimEfetivo),
                  'observacao': obs.text.trim(),
                });
                if (!ctx.mounted) return;
                if (resp.statusCode == 200) {
                  Navigator.pop(ctx);
                  _snack('Férias solicitadas!');
                  recarregar();
                } else {
                  _snack(_mensagem(resp.bodyBytes, 'Erro ao solicitar férias (${resp.statusCode}).'));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: GridColors.primary, foregroundColor: Colors.white),
              child: const Text('Enviar'),
            ),
          ],
        );
        },
      ),
    );
    obs.dispose();
  }

  bool get ctx0Mounted => mounted;

  /// Texto do saldo de ferias do funcionario (primeiro periodo aquisitivo completo com saldo).
  Future<String> _saldoDe(int funcionarioId) async {
    try {
      final resp = await TenantContext.get('${ApiLinks.baseUrl}$_url/saldo?funcionarioId=$funcionarioId');
      if (resp.statusCode != 200) return 'Saldo indisponível (${resp.statusCode}).';
      final lista = jsonDecode(utf8.decode(resp.bodyBytes));
      if (lista is! List) return 'Saldo indisponível.';
      final p = lista.whereType<Map>().firstWhere(
            (m) => m['situacao'] != 'EM_AQUISICAO' && (m['saldoDias'] ?? 0) > 0,
            orElse: () => {},
          );
      if (p.isEmpty) return 'Sem período aquisitivo completo com saldo de férias.';
      final venc = _data(p['concessivoFim']);
      final aviso = p['situacao'] == 'VENCIDA'
          ? ' — VENCIDO (pagamento em dobro)'
          : p['situacao'] == 'VENCENDO'
              ? ' — vence em $venc'
              : '';
      return 'Saldo: ${p['saldoDias']} dia(s) · aquisitivo ${_data(p['aquisitivoInicio'])} a ${_data(p['aquisitivoFim'])}$aviso';
    } catch (e) {
      AppLogger.i.warn('[DP] falha ao consultar saldo de ferias: $e');
      return 'Saldo indisponível.';
    }
  }

  Future<void> _baixarAviso(int id) async {
    try {
      final resp = await TenantContext.get('${ApiLinks.baseUrl}$_url/$id/aviso');
      if (resp.statusCode != 200) {
        _snack(_mensagem(resp.bodyBytes, 'Não foi possível gerar o aviso (${resp.statusCode}).'));
        return;
      }
      await FileSaver.instance.saveFile(
          name: 'aviso_ferias_$id', bytes: resp.bodyBytes, fileExtension: 'pdf', mimeType: MimeType.pdf);
      _snack('Aviso de férias gerado.');
    } catch (e, st) {
      AppLogger.i.error('[DP] erro ao baixar aviso de ferias: $e', st);
      _snack('Erro ao gerar o aviso de férias.');
    }
  }

  Future<void> _decidir(Map<String, dynamic> f) async {
    if (f['status'] == 'APROVADA' || f['status'] == 'GOZANDO') {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Férias aprovadas', style: TextStyle(color: GridColors.primary)),
          content: Text("${f['funcionarioNome'] ?? f['funcionarioId']}\n"
              "${_data(f['dataInicio'])} a ${_data(f['dataFim'])} (${f['dias']} dias)"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
            ElevatedButton.icon(
              key: const Key('ferias_aviso'),
              onPressed: () {
                Navigator.pop(ctx);
                _baixarAviso(f['id'] as int);
              },
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('Aviso de férias (PDF)'),
              style: ElevatedButton.styleFrom(backgroundColor: GridColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
      return;
    }
    if (!widget.podeDecidir || f['status'] != 'SOLICITADA') return;
    final obs = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Avaliar férias', style: TextStyle(color: GridColors.primary)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Funcionário: ${f['funcionarioNome'] ?? f['funcionarioId']}'),
          Text('Período: ${_data(f['dataInicio'])} a ${_data(f['dataFim'])} (${f['dias']} dias)'),
          if ((f['observacao'] ?? '').toString().isNotEmpty) Text('Observação: ${f['observacao']}'),
          const SizedBox(height: 12),
          TextField(
            controller: obs,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Observação do gestor', border: OutlineInputBorder(), isDense: true),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            key: const Key('ferias_rejeitar'),
            onPressed: () => _enviarDecisao(ctx, f['id'] as int, 'REJEITADA', obs.text),
            style: ElevatedButton.styleFrom(backgroundColor: GridColors.error, foregroundColor: Colors.white),
            child: const Text('Rejeitar'),
          ),
          ElevatedButton(
            key: const Key('ferias_aprovar'),
            onPressed: () => _enviarDecisao(ctx, f['id'] as int, 'APROVADA', obs.text),
            style: ElevatedButton.styleFrom(backgroundColor: GridColors.success, foregroundColor: Colors.white),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );
    obs.dispose();
  }

  Future<void> _enviarDecisao(BuildContext ctx, int id, String status, String obs) async {
    final resp = await TenantContext.put('${ApiLinks.baseUrl}$_url/$id/status', {
      'status': status,
      if (obs.trim().isNotEmpty) 'observacao': obs.trim(),
    });
    if (!ctx.mounted) return;
    if (resp.statusCode == 200) {
      Navigator.pop(ctx);
      _snack(status == 'APROVADA' ? 'Férias aprovadas.' : 'Férias rejeitadas.');
      recarregar();
    } else {
      _snack(_mensagem(resp.bodyBytes, 'Erro ao avaliar férias (${resp.statusCode}).'));
    }
  }

  String _data(dynamic iso) {
    try {
      return _fmt.format(DateTime.parse(iso.toString()));
    } catch (_) {
      return iso?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: GridColors.primary));
    }
    if (_erro != null) {
      return Center(child: Text(_erro!, style: const TextStyle(color: GridColors.error)));
    }
    if (_itens.isEmpty) {
      return const Center(child: Text('Nenhum pedido de férias.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _itens.length,
      itemBuilder: (_, i) {
        final f = _itens[i];
        final status = f['status']?.toString() ?? 'SOLICITADA';
        final cor = _cor(status);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            key: Key('ferias_item_${f['id']}'),
            onTap: () => _decidir(f),
            leading: CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.15),
              child: Icon(Icons.beach_access, color: cor, size: 18),
            ),
            title: Text('${f['funcionarioNome'] ?? 'Funcionário ${f['funcionarioId']}'}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${_data(f['dataInicio'])} a ${_data(f['dataFim'])} · ${f['dias']} dias'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cor.withValues(alpha: 0.4)),
              ),
              child: Text(status, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }
}
