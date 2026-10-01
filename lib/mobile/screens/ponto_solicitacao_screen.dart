import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';
import '../../models/auth_utility.dart';
import '../../widgets/user_banners.dart';

class PontoSolicitacaoScreen extends StatefulWidget {
  const PontoSolicitacaoScreen({super.key});

  @override
  State<PontoSolicitacaoScreen> createState() => _PontoSolicitacaoScreenState();
}

class _PontoSolicitacaoScreenState extends State<PontoSolicitacaoScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _solicitacoes = [];

  final _green = const Color(0xFF2E7D32);
  final _primary = GridColors.primary;
  final _bg = GridColors.background;
  final _white = Colors.white;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final loginId = AuthUtility.userInfo?.login?.id;
      if (loginId == null) return;
      final url = '${ApiLinks.baseUrl}/api/ponto-ajuste/solicitacoes?funcionarioId=$loginId';
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200 && mounted) {
        final List<dynamic> data = resp.body is List ? resp.body : (resp.body as Map<String, dynamic>)['data'] ?? [];
        setState(() => _solicitacoes = data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('Erro ao carregar solicitacoes: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _avaliarSolicitacao(Map<String, dynamic> solicitacao) async {
    final roles = AuthUtility.userInfo?.login?.roles?.map((r) => r.key).toList() ?? [];
    final isMaster = roles.contains('MASTER') || roles.contains('GESTOR');
    if (!isMaster || solicitacao['status'] != 'PENDENTE') return;

    final obsCtrl = TextEditingController();

    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Avaliar Solicitação', style: TextStyle(color: _primary)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Funcionário ID: ${solicitacao['funcionario']?['id']}'),
          Text('Data: ${solicitacao['dataPonto']}'),
          Text('Motivo: ${solicitacao['motivo']}'),
          const SizedBox(height: 16),
          TextField(
            controller: obsCtrl, maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Observação do Gestor', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(GridTexts.cancel)),
        ElevatedButton(
          onPressed: () async {
            await _enviarAvaliacao(ctx, solicitacao['id'], 'REJEITADO', obsCtrl.text);
          },
          style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: _white),
          child: const Text('Rejeitar'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _enviarAvaliacao(ctx, solicitacao['id'], 'APROVADO', obsCtrl.text);
          },
          style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: _white),
          child: const Text('Aprovar'),
        ),
      ],
    ));
  }

  Future<void> _enviarAvaliacao(BuildContext ctx, int id, String status, String obs) async {
    final body = {'status': status, 'observacao': obs};
    final resp = await TenantContext.put('${ApiLinks.baseUrl}/api/ponto-ajuste/solicitacoes/$id/status', body);
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

    await showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text('Solicitar Ajuste', style: TextStyle(color: _primary)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today, color: _primary),
              title: Text(dataSelecionada == null
                  ? 'Selecionar data'
                  : DateFormat('dd/MM/yyyy').format(dataSelecionada!)),
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx, initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now(),
                );
                if (d != null) setS(() => dataSelecionada = d);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl, maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Motivo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(GridTexts.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (dataSelecionada == null || motivoCtrl.text.isEmpty) {
                 _snack('Preencha a data e o motivo.');
                 return;
              }
              final loginId = AuthUtility.userInfo?.login?.id;
              final empresaId = TenantContext.empresaId;
              final body = {
                'funcionario': {'id': loginId},
                if (empresaId != null) 'empresa': {'id': empresaId},
                'dataPonto': DateFormat('yyyy-MM-dd').format(dataSelecionada!),
                'motivo': motivoCtrl.text,
              };
              final resp = await TenantContext.post('${ApiLinks.baseUrl}/api/ponto-ajuste/solicitacoes', body);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (resp.statusCode == 200 || resp.statusCode == 201) {
                _snack('Solicitação enviada!');
                _carregar();
              } else {
                _snack('Erro ao enviar solicitação');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: _white),
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
      case 'APROVADO': return _green;
      case 'REJEITADO': return _primary;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: UserBannerAppBar(
        screenTitle: 'Ajustes de Ponto',
        showBackButton: true,
        onRefresh: _carregar,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaSolicitacao,
        backgroundColor: _primary, foregroundColor: _white,
        icon: const Icon(Icons.add), label: const Text('Nova Solicitação'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _solicitacoes.isEmpty
              ? const Center(child: Text('Nenhuma solicitação encontrada.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                  itemCount: _solicitacoes.length,
                  itemBuilder: (_, i) {
                    final s = _solicitacoes[i];
                    final status = s['status']?.toString() ?? 'PENDENTE';
                    return Card(
                      color: GridColors.card,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        onTap: () => _avaliarSolicitacao(s),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(status).withValues(alpha: 0.15),
                          child: Icon(Icons.calendar_today, color: _statusColor(status), size: 20),
                        ),
                        title: Text(s['dataPonto']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: GridColors.textPrimary)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(s['motivo']?.toString() ?? '', style: const TextStyle(color: GridColors.textSecondary)),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _statusColor(status).withValues(alpha: 0.4)),
                          ),
                          child: Text(status, style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
