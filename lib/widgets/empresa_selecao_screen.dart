import 'package:flutter/material.dart';

import '../models/empresa_acesso_model.dart';
import '../services/login_empresa_acesso_service.dart';
import '../utils/grid_colors.dart';

class EmpresaSelecaoScreen extends StatefulWidget {
  final bool obrigatorio;
  final VoidCallback? onSelected;
  final Future<List<EmpresaAcesso>> Function()? loadAcessos;
  final Future<bool> Function(int empresaId)? trocarEmpresa;

  const EmpresaSelecaoScreen({
    super.key,
    this.obrigatorio = false,
    this.onSelected,
    this.loadAcessos,
    this.trocarEmpresa,
  });

  @override
  State<EmpresaSelecaoScreen> createState() => _EmpresaSelecaoScreenState();
}

class _EmpresaSelecaoScreenState extends State<EmpresaSelecaoScreen> {
  late Future<List<EmpresaAcesso>> _future;
  int? _processandoEmpresaId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<EmpresaAcesso>> _load() {
    return widget.loadAcessos?.call() ??
        LoginEmpresaAcessoService().listarMeusAcessos();
  }

  Future<void> _selecionar(EmpresaAcesso acesso) async {
    if (!acesso.aprovado || acesso.ativa) {
      widget.onSelected?.call();
      if (Navigator.canPop(context)) Navigator.pop(context, acesso.ativa);
      return;
    }
    setState(() => _processandoEmpresaId = acesso.empresaId);
    final ok = await (widget.trocarEmpresa?.call(acesso.empresaId) ??
        LoginEmpresaAcessoService().trocarEmpresaAtiva(acesso.empresaId));
    if (!mounted) return;
    setState(() => _processandoEmpresaId = null);
    if (ok) {
      widget.onSelected?.call();
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GridColors.error,
          content: Text('Não foi possível trocar a empresa ativa.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        title: const Text('Selecionar Empresa'),
        automaticallyImplyLeading: !widget.obrigatorio,
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<EmpresaAcesso>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final acessos = (snapshot.data ?? [])
              .where((a) => a.aprovado)
              .toList(growable: false);
          if (acessos.isEmpty) return _estadoVazio();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: acessos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _empresaTile(acessos[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _estadoVazio() {
    return const Center(
      child: Text(
        'Nenhuma empresa aprovada encontrada.',
        style: TextStyle(color: GridColors.textMuted),
      ),
    );
  }

  Widget _empresaTile(EmpresaAcesso acesso) {
    final processando = _processandoEmpresaId == acesso.empresaId;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              acesso.ativa ? GridColors.secondary : GridColors.secondarySoft,
          child: Icon(
            acesso.ativa ? Icons.check : Icons.business,
            color: acesso.ativa ? Colors.white : GridColors.secondary,
          ),
        ),
        title: Text(
          acesso.empresaNome,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(acesso.ativa ? 'Empresa ativa' : 'Acesso aprovado'),
        trailing: processando
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FilledButton.icon(
                onPressed: () => _selecionar(acesso),
                icon: Icon(acesso.ativa ? Icons.check_circle : Icons.swap_horiz),
                label: Text(acesso.ativa ? 'Atual' : 'Usar'),
              ),
        onTap: processando ? null : () => _selecionar(acesso),
      ),
    );
  }
}
