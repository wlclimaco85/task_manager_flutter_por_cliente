import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../services/lancamento_contabil_service.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;

const _primary = Color(0xFF93070A); // GridColors.primary
const _bg = Color(0xFFF5F5F5);
const _green = Color(0xFF005826);
const _red = Color(0xFF93070A);
const _border = Color(0xFFDDDDDD);

class WebLancamentoContabilGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  const WebLancamentoContabilGridScreen({super.key, required this.hasPermission});
  @override
  State<WebLancamentoContabilGridScreen> createState() => _WebLancamentoContabilGridScreenState();
}

class _WebLancamentoContabilGridScreenState extends State<WebLancamentoContabilGridScreen> {
  final _service = LancamentoContabilService();
  List<Map<String, dynamic>> _lancamentos = [];
  bool _loading = false;
  bool _autoGerando = false;
  String _periodo = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  int? _empresaId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final login = AuthUtility.userInfo?.login;
    final id = int.tryParse(login?.empresa?.id?.toString() ?? '');
    if (id == null) return;
    _empresaId = id;
    setState(() => _loading = true);
    final lista = await _service.listar(id, _periodo);
    if (mounted) setState(() { _lancamentos = lista; _loading = false; });
  }

  Future<void> _autoGerar() async {
    if (_empresaId == null) return;
    setState(() => _autoGerando = true);
    final result = await _service.autoGerar(_empresaId!, _periodo);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result != null ? '${result.length} lançamentos gerados' : 'Nada a gerar'),
        backgroundColor: result != null ? _green : Colors.orange,
      ));
      _carregar();
      setState(() => _autoGerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Lançamentos Contábeis'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Período (yyyy-MM)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true, fillColor: Colors.white12,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                controller: TextEditingController(text: _periodo),
                onSubmitted: (v) { _periodo = v; _carregar(); },
              ),
            ),
          ),
          IconButton(
            icon: _autoGerando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_fix_high),
            onPressed: _autoGerando ? null : _autoGerar,
            tooltip: 'Auto-gerar',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: _lancamentos.isEmpty
                  ? const Center(child: Text('Nenhum lançamento no período'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _lancamentos.length,
                      itemBuilder: (_, i) {
                        final l = _lancamentos[i];
                        final isDebito = l['natureza'] == 'DEBITO';
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDebito ? _red : _green,
                              radius: 14,
                              child: Text(isDebito ? 'D' : 'C', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(l['historico']?.toString() ?? 'Sem histórico', style: const TextStyle(fontSize: 13)),
                            subtitle: Text('Conta: ${l['contaContabilId']} | ${l['dataLancamento']} | ${l['origem']}', style: const TextStyle(fontSize: 11)),
                            trailing: Text(
                              'R\$ ${_fmt(l['valor'])}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDebito ? _red : _green),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '0,00';
    if (v is double || v is int) return v.toStringAsFixed(2).replaceAll('.', ',');
    return v.toString();
  }
}
