import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:intl/intl.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../utils/grid_texts.dart';

const _primary = GridColors.primary;
const _green = GridColors.secondary;
const _bg = Color(0xFFF5F5F5);
const _white = Colors.white;

class WebPontoSolicitacaoScreen extends StatefulWidget {
  const WebPontoSolicitacaoScreen({super.key});
  @override
  State<WebPontoSolicitacaoScreen> createState() =>
      _WebPontoSolicitacaoScreenState();
}

class _WebPontoSolicitacaoScreenState extends State<WebPontoSolicitacaoScreen> {
  List<dynamic> _solicitacoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final id = AuthUtility.userInfo?.login?.id;
      final empresaId = TenantContext.empresaId;
      final roles = AuthUtility.userInfo?.login?.roles?.map((r) => r.role?.toUpperCase()).toList() ?? [];
      final isMaster = roles.contains('MASTER') || roles.contains('GESTOR');

      String url = '${ApiLinks.baseUrl}/api/ponto-ajuste/solicitacoes';
      if (isMaster && empresaId != null) {
        url += '?empresaId=$empresaId';
      } else {
        url += '?funcionarioId=$id';
      }

      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        setState(() => _solicitacoes = jsonDecode(resp.body) as List);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _avaliarSolicitacao(Map<String, dynamic> solicitacao) async {
    final roles = AuthUtility.userInfo?.login?.roles?.map((r) => r.role?.toUpperCase()).toList() ?? [];
    final isMaster = roles.contains('MASTER') || roles.contains('GESTOR');
    if (!isMaster || solicitacao['status'] != 'PENDENTE') return;

    final obsCtrl = TextEditingController();

    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Avaliar Solicitação',
                  style: TextStyle(color: _primary)),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Funcionário ID: ${solicitacao['funcionario']?['id']}'),
                    Text('Data: ${solicitacao['dataPonto']}'),
                    Text('Motivo: ${solicitacao['motivo']}'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: obsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Observação do Gestor',
                          border: OutlineInputBorder(),
                          isDense: true),
                    ),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(GridTexts.cancel)),
                ElevatedButton(
                  onPressed: () async {
                    await _enviarAvaliacao(
                        ctx, solicitacao['id'], 'REJEITADO', obsCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary, foregroundColor: _white),
                  child: const Text('Rejeitar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _enviarAvaliacao(
                        ctx, solicitacao['id'], 'APROVADO', obsCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _green, foregroundColor: _white),
                  child: const Text('Aprovar'),
                ),
              ],
            ));
  }

  Future<void> _enviarAvaliacao(
      BuildContext ctx, int id, String status, String obs) async {
    final body = {'status': status, 'observacao': obs};
    final resp = await TenantContext.put(
        '${ApiLinks.baseUrl}/api/ponto-ajuste/solicitacoes/$id/status', body);
    if (!ctx.mounted) return;
    Navigator.pop(ctx);
    if (resp.statusCode == 200) {
      _snack('Solicitação avaliada com sucesso!');
      _carregar();
    } else {
      _snack('Erro ao avaliar solicitação.');
    }
  }

  Future<void> _novaSolicitacao() async {
    DateTime? dataSelecionada;
    final motivoCtrl = TextEditingController();

    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (ctx, setS) => AlertDialog(
                title: const Text('Solicitar Ajuste de Ponto',
                    style: TextStyle(color: _primary)),
                content: SizedBox(
                    width: 400,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(
                        leading:
                            const Icon(Icons.calendar_today, color: _primary),
                        title: Text(dataSelecionada == null
                            ? 'Selecionar data'
                            : DateFormat('dd/MM/yyyy')
                                .format(dataSelecionada!)),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 90)),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setS(() => dataSelecionada = d);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: motivoCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Motivo',
                            border: OutlineInputBorder(),
                            isDense: true),
                      ),
                    ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(GridTexts.cancel)),
                  ElevatedButton(
                    onPressed: () async {
                      if (dataSelecionada == null || motivoCtrl.text.isEmpty)
                        return;
                      final loginId = AuthUtility.userInfo?.login?.id;
                      final empresaId = TenantContext.empresaId;
                      final body = {
                        'funcionario': {'id': loginId},
                        if (empresaId != null) 'empresa': {'id': empresaId},
                        'dataPonto':
                            DateFormat('yyyy-MM-dd').format(dataSelecionada!),
                        'motivo': motivoCtrl.text,
                      };
                      final resp = await TenantContext.post(
                          '${ApiLinks.baseUrl}/api/ponto-ajuste/solicitacoes',
                          body);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (resp.statusCode == 200) {
                        _snack('Solicitação enviada!');
                        _carregar();
                      } else {
                        _snack('Erro ao enviar solicitação');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary, foregroundColor: _white),
                    child: const Text('Enviar'),
                  ),
                ],
              ),
            ));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'APROVADO':
        return _green;
      case 'REJEITADO':
        return _primary;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: _white,
        elevation: 2,
        title: const Row(children: [
          Icon(Icons.edit_calendar, size: 20),
          SizedBox(width: 8),
          Text('Solicitação de Ajuste de Ponto',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaSolicitacao,
        backgroundColor: _primary,
        foregroundColor: _white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Solicitação'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _solicitacoes.isEmpty
              ? const Center(
                  child: Text('Nenhuma solicitação encontrada.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _solicitacoes.length,
                  itemBuilder: (_, i) {
                    final s = _solicitacoes[i];
                    final status = s['status']?.toString() ?? 'PENDENTE';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        onTap: () => _avaliarSolicitacao(s),
                        leading: CircleAvatar(
                          backgroundColor:
                              _statusColor(status).withValues(alpha: 0.15),
                          child: Icon(Icons.calendar_today,
                              color: _statusColor(status), size: 18),
                        ),
                        title: Text(s['dataPonto']?.toString() ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(s['motivo']?.toString() ?? ''),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _statusColor(status)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
