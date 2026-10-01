import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../services/conta_contabil_service.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;

const _primary = Color(0xFF93070A); // GridColors.primary
const _bg = Color(0xFFF5F5F5);
const _green = Color(0xFF005826);
const _red = Color(0xFF93070A);

class WebContaContabilGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  const WebContaContabilGridScreen({super.key, required this.hasPermission});
  @override
  State<WebContaContabilGridScreen> createState() => _WebContaContabilGridScreenState();
}

class _WebContaContabilGridScreenState extends State<WebContaContabilGridScreen> {
  final _service = ContaContabilService();
  List<Map<String, dynamic>> _contas = [];
  bool _loading = false;
  int? _empresaId;
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  String _tipo = 'ATIVO';
  String _natureza = 'DEVEDORA';
  bool _showForm = false;
  Map<String, dynamic>? _editando;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final login = AuthUtility.userInfo?.login;
    final id = int.tryParse(login?.empresa?.id?.toString() ?? '');
    if (id == null) return;
    _empresaId = id;
    setState(() => _loading = true);
    final lista = await _service.listar(id);
    if (mounted) setState(() { _contas = lista; _loading = false; });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final login = AuthUtility.userInfo?.login;
    final empId = int.tryParse(login?.empresa?.id?.toString() ?? '');
    if (empId == null) return;
    final body = {'empresaId': empId, 'codigo': _codigoCtrl.text, 'descricao': _descricaoCtrl.text, 'tipo': _tipo, 'natureza': _natureza, 'ativo': true};
    if (_editando != null) {
      await _service.atualizar(_editando!['id'].toString(), body);
    } else {
      await _service.criar(body);
    }
    _codigoCtrl.clear(); _descricaoCtrl.clear();
    setState(() { _showForm = false; _editando = null; });
    _carregar();
  }

  void _editar(Map<String, dynamic> c) {
    _codigoCtrl.text = c['codigo']?.toString() ?? '';
    _descricaoCtrl.text = c['descricao']?.toString() ?? '';
    setState(() { _tipo = c['tipo'] ?? 'ATIVO'; _natureza = c['natureza'] ?? 'DEVEDORA'; _editando = c; _showForm = true; });
  }

  Color _corTipo(String t) {
    switch (t) {
      case 'ATIVO': return _primary;
      case 'PASSIVO': return _red;
      case 'RECEITA': return _green;
      case 'DESPESA': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Plano de Contas'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() { _editando = null; _codigoCtrl.clear(); _descricaoCtrl.clear(); _showForm = !_showForm; })),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: Column(children: [
        if (_showForm) _buildForm(),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildList()),
      ]),
    );
  }

  Widget _buildForm() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(controller: _codigoCtrl, decoration: const InputDecoration(labelText: 'Código'), validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null),
            TextFormField(controller: _descricaoCtrl, decoration: const InputDecoration(labelText: 'Descrição'), validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null),
            DropdownButtonFormField(value: _tipo, items: ['ATIVO', 'PASSIVO', 'RECEITA', 'CUSTO', 'DESPESA'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _tipo = v!), decoration: const InputDecoration(labelText: 'Tipo')),
            DropdownButtonFormField(value: _natureza, items: ['DEVEDORA', 'CREDORA'].map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(), onChanged: (v) => setState(() => _natureza = v!), decoration: const InputDecoration(labelText: 'Natureza')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _salvar, child: Text(_editando != null ? 'Atualizar' : 'Criar')),
          ]),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_contas.isEmpty) return const Center(child: Text('Nenhuma conta cadastrada'));
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _contas.length,
      itemBuilder: (_, i) {
        final c = _contas[i];
        final cor = _corTipo(c['tipo']?.toString() ?? '');
        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: cor, radius: 16, child: Text(c['codigo']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 10))),
            title: Text('${c['codigo']} - ${c['descricao']}', style: const TextStyle(fontSize: 13)),
            subtitle: Text('${c['tipo']} / ${c['natureza']}', style: TextStyle(fontSize: 11, color: cor)),
            trailing: PopupMenuButton(itemBuilder: (_) => [
              PopupMenuItem(onTap: () => _editar(c), child: const Text('Editar')),
              PopupMenuItem(onTap: () async { await _service.deletar(c['id'].toString()); _carregar(); }, child: const Text('Excluir', style: TextStyle(color: _red))),
            ]),
          ),
        );
      },
    );
  }
}
