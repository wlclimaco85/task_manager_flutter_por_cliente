import 'package:flutter/material.dart';

import '../models/empresa_acesso_model.dart';
import '../services/login_empresa_acesso_service.dart';
import '../utils/grid_colors.dart';

class LoginEmpresaAcessoAprovacaoScreen extends StatefulWidget {
  const LoginEmpresaAcessoAprovacaoScreen({super.key});

  @override
  State<LoginEmpresaAcessoAprovacaoScreen> createState() =>
      _LoginEmpresaAcessoAprovacaoScreenState();
}

class _LoginEmpresaAcessoAprovacaoScreenState
    extends State<LoginEmpresaAcessoAprovacaoScreen> {
  final _service = LoginEmpresaAcessoService();
  bool _carregando = true;
  List<EmpresaAcesso> _itens = [];
  final Set<int> _processando = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final itens = await _service.listarPendentes();
    if (!mounted) return;
    setState(() {
      _itens = itens;
      _carregando = false;
    });
  }

  Future<void> _processar(EmpresaAcesso item, {required bool aprovar}) async {
    final id = item.id;
    if (id == null) return;
    setState(() => _processando.add(id));
    final resp = aprovar
        ? await _service.aprovarResponse(id)
        : await _service.negarResponse(id);
    final ok = resp.isSuccess;
    if (!mounted) return;
    setState(() {
      _processando.remove(id);
      if (ok) _itens.removeWhere((e) => e.id == id);
    });
    final erroMsg = resp.body != null
        ? (resp.body!['message'] ?? resp.body!['erro'] ?? resp.body!['error'])?.toString()
        : null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok
            ? (aprovar ? GridColors.success : GridColors.neutral)
            : GridColors.error,
        content: Text(ok
            ? (aprovar ? 'Acesso aprovado com sucesso.' : 'Acesso negado com sucesso.')
            : (erroMsg ?? 'Não foi possível processar a solicitação.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business_center, color: GridColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Permissões Multi-Empresa${_itens.isNotEmpty ? ' (${_itens.length})' : ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _carregando ? null : _carregar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _itens.isEmpty
                      ? const Center(child: Text('Nenhuma solicitação pendente'))
                      : _tabela(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabela() {
    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GridColors.gridHeader),
        columns: const [
          DataColumn(label: Text('Login')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Empresa')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Ações')),
        ],
        rows: _itens.map((item) {
          final processando = item.id != null && _processando.contains(item.id);
          return DataRow(cells: [
            DataCell(Text(item.loginNome ?? '-')),
            DataCell(Text(item.loginEmail ?? '-')),
            DataCell(Text(item.empresaNome)),
            DataCell(Text(item.status)),
            DataCell(
              processando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Aprovar',
                          icon: const Icon(Icons.check_circle,
                              color: GridColors.success),
                          onPressed: () => _processar(item, aprovar: true),
                        ),
                        IconButton(
                          tooltip: 'Negar',
                          icon:
                              const Icon(Icons.cancel, color: GridColors.error),
                          onPressed: () => _processar(item, aprovar: false),
                        ),
                      ],
                    ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}
