import 'package:flutter/material.dart';
import '../../../services/escrituracao_fiscal_service.dart';
import '../../../models/escrituracao_fiscal_model.dart';
import '../../../utils/tenant_context.dart';
import 'escrituracao_detalhe_screen.dart';
import '../../../utils/grid_texts.dart';

class EscrituracaoListScreen extends StatefulWidget {
  const EscrituracaoListScreen({super.key});

  @override
  State<EscrituracaoListScreen> createState() => _EscrituracaoListScreenState();
}

class _EscrituracaoListScreenState extends State<EscrituracaoListScreen> {
  final _service = EscrituracaoFiscalService();
  List<EscrituracaoFiscal> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final empresaId = TenantContext.empresaId;
      if (empresaId == null) {
        setState(() {
          _error = 'Nenhuma empresa selecionada.';
          _loading = false;
        });
        return;
      }
      final items = await _service.listar(empresaId: empresaId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _gerarEscrituracao() async {
    final periodoCtrl = TextEditingController();
    final tipoCtrl = TextEditingController(text: 'MENSAL');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerar Escrituração'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: periodoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Período (MM/AAAA)',
                  hintText: 'Ex: 01/2026',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o período' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tipoCtrl.text,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'MENSAL', child: Text('Mensal')),
                  DropdownMenuItem(value: 'TRIMESTRAL', child: Text('Trimestral')),
                  DropdownMenuItem(value: 'ANUAL', child: Text('Anual')),
                ],
                onChanged: (v) => tipoCtrl.text = v ?? 'MENSAL',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Gerar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final empresaId = TenantContext.empresaId;
    if (empresaId == null) return;

    try {
      await _service.gerar(
        empresaId: empresaId,
        periodo: periodoCtrl.text.trim(),
        tipo: tipoCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escrituração gerada com sucesso!')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar: $e')),
      );
    }
  }

  Future<void> _abrirDetalhe(EscrituracaoFiscal esc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EscrituracaoDetalheScreen(escrituracao: esc),
      ),
    );
    _load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'RASCUNHO':
        return Colors.orange;
      case 'CONFERIDA':
        return Colors.blue;
      case 'FECHADA':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escrituração Fiscal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'gerar-escrituracao',
        onPressed: _gerarEscrituracao,
        icon: const Icon(Icons.add),
        label: const Text('Gerar'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhuma escrituração encontrada',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Clique em "Gerar" para criar uma nova.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final esc = _items[i];
          return ListTile(
            onTap: () => _abrirDetalhe(esc),
            leading: CircleAvatar(
              backgroundColor: _statusColor(esc.status).withValues(alpha: 0.15),
              child: Text(
                esc.periodo.isNotEmpty && esc.periodo.length >= 2
                    ? esc.periodo.substring(0, 2)
                    : '..',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _statusColor(esc.status),
                ),
              ),
            ),
            title: Text(
              '${esc.periodo} — ${esc.tipo}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Docs: ${esc.totalDocumentos ?? 0}  |  Total: R\$ ${esc.valorTotal?.toStringAsFixed(2) ?? '0,00'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(esc.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _statusColor(esc.status).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    esc.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(esc.status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          );
        },
      ),
    );
  }
}
