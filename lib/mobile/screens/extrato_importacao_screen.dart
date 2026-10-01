import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/conta_bancaria_caller.dart';
import '../../../services/extrato_import_caller.dart';
import '../../../utils/grid_colors.dart';
import '../../widgets/user_banners.dart';

class MobileExtratoImportacaoScreen extends StatefulWidget {
  const MobileExtratoImportacaoScreen({super.key});

  @override
  State<MobileExtratoImportacaoScreen> createState() =>
      _MobileExtratoImportacaoScreenState();
}

class _MobileExtratoImportacaoScreenState
    extends State<MobileExtratoImportacaoScreen> {
  final ContaBancariaCaller _contaCaller = ContaBancariaCaller();

  List<Map<String, dynamic>> _contas = [];
  Map<String, dynamic>? _contaSelecionada;
  PlatformFile? _arquivo;
  bool _importando = false;
  ExtratoImportResult? _resultado;

  List<dynamic> _importacoes = [];
  bool _carregandoLista = false;

  @override
  void initState() {
    super.initState();
    _carregarContas();
    _carregarLista();
  }

  Future<void> _carregarContas() async {
    final contas = await _contaCaller.fetchContas(context);
    if (!mounted) return;
    setState(() => _contas = contas.map((c) => c.toJson()).toList());
  }

  Future<void> _carregarLista() async {
    setState(() => _carregandoLista = true);
    final lista = await ExtratoImportCaller.listarImportacoes();
    if (!mounted) return;
    setState(() {
      _importacoes = lista;
      _carregandoLista = false;
    });
  }

  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ofx', 'csv', 'xlsx', 'xls', 'pdf'],
      withData: true,
    );
    if (result == null || !mounted) return;
    setState(() {
      _arquivo = result.files.first;
      _resultado = null;
    });
  }

  Future<void> _importar() async {
    if (_contaSelecionada == null || _arquivo == null) return;
    setState(() => _importando = true);

    final result = await ExtratoImportCaller.confirmar(
      contaBancariaId: _contaSelecionada!['id'] as int,
      arquivo: _arquivo!,
    );

    if (!mounted) return;
    setState(() {
      _importando = false;
      _resultado = result;
    });

    if (result.success) {
      _snack('Importação concluída com sucesso!');
      await _carregarLista();
    } else {
      _snack(result.message ?? 'Erro na importação', erro: true);
    }
  }

  Future<void> _excluir(dynamic importacao) async {
    final id = importacao['id'] as int?;
    if (id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir importação'),
        content: const Text(
            'Remove apenas o registro. As transações conciliadas não são afetadas.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;
    final ok = await ExtratoImportCaller.excluirImportacao(id);
    if (!mounted) return;
    if (ok) {
      _snack('Registro excluído.');
      await _carregarLista();
    } else {
      _snack('Erro ao excluir.', erro: true);
    }
  }

  void _snack(String msg, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: erro ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  void _reset() => setState(() {
        _arquivo = null;
        _resultado = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      // Padrao mobile: header (banner do usuario) + subheader com nome e refresh.
      // Tela sem grid -> sem botao de filtro nem de personalizar colunas.
      appBar: UserBannerAppBar(
        screenTitle: 'Importar Extrato',
        showBackButton: Navigator.canPop(context),
        onRefresh: _carregarLista,
        isLoading: _carregandoLista,
      ),
      body: RefreshIndicator(
        onRefresh: _carregarLista,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulario(),
              if (_resultado != null) ...[
                const SizedBox(height: 16),
                _buildResultado(),
              ],
              const SizedBox(height: 24),
              _buildLista(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nova Importação',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _contaSelecionada,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Conta Bancária',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: _contas.map((c) {
                final label =
                    '${c['banco'] ?? ''} - ${c['numero'] ?? ''}'
                    '${c['agencia'] != null ? ' (${c['agencia']})' : ''}';
                return DropdownMenuItem(
                  value: c,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) => setState(() => _contaSelecionada = v),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selecionarArquivo,
              icon: Icon(
                Icons.attach_file,
                color:
                    _arquivo != null ? GridColors.primary : GridColors.secondary,
              ),
              label: Text(
                _arquivo != null
                    ? '${_arquivo!.name} (${(_arquivo!.size / 1024).toStringAsFixed(1)} KB)'
                    : 'Selecionar Arquivo (OFX, CSV, XLSX, XLS, PDF)',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _arquivo != null
                      ? GridColors.primary
                      : GridColors.textSecondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _arquivo != null
                      ? GridColors.primary
                      : GridColors.divider,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (_arquivo != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Remover'),
                  style: TextButton.styleFrom(
                      foregroundColor: GridColors.error,
                      padding: EdgeInsets.zero),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (_contaSelecionada != null &&
                      _arquivo != null &&
                      !_importando)
                  ? _importar
                  : null,
              icon: _importando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_alt, size: 18),
              label: Text(_importando ? 'Importando...' : 'Salvar / Importar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultado() {
    final success = _resultado!.success;
    final msg = _resultado!.message;
    final importados = _resultado!.data?['importados'] ??
        _resultado!.data?['totalImportados'] ??
        _resultado!.data?['linhasImportadas'] ??
        '?';

    return Card(
      elevation: 2,
      color: success ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    success ? 'Importação Concluída' : 'Erro na Importação',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: success
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            if (msg != null) ...[
              const SizedBox(height: 8),
              Text(msg,
                  style: TextStyle(
                      color: success
                          ? Colors.green.shade900
                          : Colors.red.shade900)),
            ],
            if (success) ...[
              const SizedBox(height: 8),
              Text('Linhas importadas: $importados',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nova Importação'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Extratos Importados',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        if (_carregandoLista)
          const Center(child: CircularProgressIndicator())
        else if (_importacoes.isEmpty)
          const Text(
            'Nenhum extrato importado ainda.',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...(_importacoes.map((imp) => _buildItemLista(imp)).toList()),
      ],
    );
  }

  Widget _buildItemLista(dynamic imp) {
    final nomeArq = imp['arquivoNome'] ?? '—';
    final formato = imp['formato'] ?? '';
    final status = imp['status'] ?? '';
    final totalLinhas = imp['totalLinhas'] ?? 0;
    final importadas = imp['importadas'] ?? 0;
    final criadoAt = imp['createdAt']?.toString() ?? '';
    final dataStr = criadoAt.length >= 10 ? criadoAt.substring(0, 10) : '—';

    final corStatus = status == 'CONCLUIDO'
        ? GridColors.success
        : status == 'ERRO'
            ? GridColors.error
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: const Icon(Icons.file_present, color: GridColors.primary),
        title: Text(
          nomeArq,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$dataStr · $formato · $importadas/$totalLinhas linhas',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: corStatus.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                    fontSize: 10,
                    color: corStatus,
                    fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: GridColors.error),
              onPressed: () => _excluir(imp),
              tooltip: 'Excluir',
            ),
          ],
        ),
      ),
    );
  }
}
