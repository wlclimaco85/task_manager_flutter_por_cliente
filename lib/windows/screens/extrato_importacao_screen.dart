import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/conta_bancaria_caller.dart';
import '../../../services/extrato_import_caller.dart';
import '../../../utils/grid_colors.dart';

class ExtratoImportacaoScreen extends StatefulWidget {
  const ExtratoImportacaoScreen({super.key});

  @override
  State<ExtratoImportacaoScreen> createState() =>
      _ExtratoImportacaoScreenState();
}

class _ExtratoImportacaoScreenState extends State<ExtratoImportacaoScreen> {
  final ContaBancariaCaller _contaCaller = ContaBancariaCaller();

  List<Map<String, dynamic>> _contas = [];
  Map<String, dynamic>? _contaSelecionada;
  PlatformFile? _arquivo;
  bool _carregandoPreview = false;
  bool _confirmando = false;
  bool _importandoDireto = false;
  ExtratoImportResult? _previewResult;
  ExtratoImportResult? _confirmResult;

  List<dynamic> _importacoes = [];
  bool _carregandoLista = false;

  @override
  void initState() {
    super.initState();
    _carregarContas();
    _carregarListagem();
  }

  Future<void> _carregarListagem() async {
    setState(() => _carregandoLista = true);
    final lista = await ExtratoImportCaller.listarImportacoes();
    if (!mounted) return;
    setState(() {
      _importacoes = lista;
      _carregandoLista = false;
    });
  }

  Future<void> _importarDireto() async {
    if (_contaSelecionada == null || _arquivo == null) return;
    setState(() => _importandoDireto = true);
    final result = await ExtratoImportCaller.confirmar(
      contaBancariaId: _contaSelecionada!['id'] as int,
      arquivo: _arquivo!,
    );
    if (!mounted) return;
    setState(() {
      _importandoDireto = false;
      _confirmResult = result;
    });
    if (result.success) {
      _snack('Importação concluída com sucesso!');
      await _carregarListagem();
    } else {
      _snack(result.message ?? 'Erro na importação', error: true);
    }
  }

  Future<void> _excluirImportacao(dynamic importacao) async {
    final id = importacao['id'] as int?;
    if (id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir importação'),
        content:
            const Text('Remove apenas o registro de importação. As transações conciliadas não são afetadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.error,
              foregroundColor: Colors.white,
            ),
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
      _snack('Registro de importação excluído.');
      await _carregarListagem();
    } else {
      _snack('Erro ao excluir importação.', error: true);
    }
  }

  Future<void> _carregarContas() async {
    final contas = await _contaCaller.fetchContas(context);
    if (!mounted) return;
    setState(() => _contas = contas.map((c) => c.toJson()).toList());
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
      _previewResult = null;
      _confirmResult = null;
    });
  }

  Future<void> _enviarPreview() async {
    if (_contaSelecionada == null || _arquivo == null) return;
    setState(() => _carregandoPreview = true);

    final result = await ExtratoImportCaller.preview(
      contaBancariaId: _contaSelecionada!['id'] as int,
      arquivo: _arquivo!,
    );

    if (!mounted) return;
    setState(() {
      _carregandoPreview = false;
      _previewResult = result;
    });

    if (!result.success) {
      _snack(result.message ?? 'Erro no preview', error: true);
    }
  }

  Future<void> _confirmarImportacao() async {
    if (_contaSelecionada == null || _arquivo == null) return;
    setState(() => _confirmando = true);

    final result = await ExtratoImportCaller.confirmar(
      contaBancariaId: _contaSelecionada!['id'] as int,
      arquivo: _arquivo!,
    );

    if (!mounted) return;
    setState(() {
      _confirmando = false;
      _confirmResult = result;
    });

    if (!result.success) {
      _snack(result.message ?? 'Erro na importação', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  void _reset() {
    setState(() {
      _arquivo = null;
      _previewResult = null;
      _confirmResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: GridColors.secondary,
        foregroundColor: Colors.white,
        title: const Text('Importação de Extrato Bancário'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelecaoCard(),
            const SizedBox(height: 24),
            if (_previewResult != null && _previewResult!.success)
              _buildPreviewCard(),
            if (_confirmResult != null) _buildResultadoCard(),
            const SizedBox(height: 24),
            _buildListagemCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecaoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecionar Conta e Arquivo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 20),
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
                    '${c['banco'] ?? ''} - ${c['numero'] ?? ''} ${c['agencia'] != null ? '(' + c['agencia'].toString() + ')' : ''}';
                return DropdownMenuItem(
                  value: c,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) => setState(() => _contaSelecionada = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _selecionarArquivo,
                  icon: const Icon(Icons.file_present, size: 18),
                  label: Text(
                    _arquivo != null
                        ? '${_arquivo!.name} (${(_arquivo!.size / 1024).toStringAsFixed(1)} KB)'
                        : 'Selecionar Arquivo (OFX, CSV, XLSX, XLS)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _arquivo != null
                        ? GridColors.secondaryLight
                        : Colors.grey.shade200,
                    foregroundColor:
                        _arquivo != null ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                if (_arquivo != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _reset,
                    tooltip: 'Remover arquivo',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: (_contaSelecionada != null && _arquivo != null &&
                          !_carregandoPreview && _confirmResult == null)
                      ? _enviarPreview
                      : null,
                  icon: _carregandoPreview
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.preview, size: 18),
                  label: Text(
                      _carregandoPreview ? 'Processando...' : 'Pré-visualizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: (_contaSelecionada != null &&
                          _arquivo != null &&
                          !_importandoDireto &&
                          _confirmResult == null)
                      ? _importarDireto
                      : null,
                  icon: _importandoDireto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_alt, size: 18),
                  label: Text(_importandoDireto ? 'Salvando...' : 'Salvar / Importar Direto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
                if (_previewResult != null && _previewResult!.success &&
                    _confirmResult == null)
                  ElevatedButton.icon(
                    onPressed: _confirmando ? null : _confirmarImportacao,
                    icon: _confirmando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle, size: 18),
                    label: Text(
                        _confirmando ? 'Confirmando...' : 'Confirmar Importação'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final data = _previewResult!.data!;
    final linhas = _extractLinhas(data);
    final totalLinhas = data['totalLinhas'] ?? data['total'] ?? linhas.length;
    final totalDebitos = data['totalDebitos'] ?? data['totalDebit'] ?? 0.0;
    final totalCreditos = data['totalCreditos'] ?? data['totalCredit'] ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart,
                    color: GridColors.secondary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Pré-visualização do Extrato',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResumo(totalLinhas, totalDebitos, totalCreditos),
            const SizedBox(height: 16),
            if (linhas.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: linhas.take(100).length,
                itemBuilder: (context, index) {
                  final linha = linhas[index];
                  final tipo = linha['tipo']?.toString() ??
                      linha['debitoCredito']?.toString() ??
                      '';
                  final valor = (linha['valor'] ?? 0.0).toDouble();
                  final ehCredito = tipo == 'CREDITO' ||
                      tipo == 'C' ||
                      (tipo.isEmpty && valor > 0);
                  final ehDebito = tipo == 'DEBITO' ||
                      tipo == 'D' ||
                      (tipo.isEmpty && valor < 0);
                  final corTipo = ehCredito
                      ? GridColors.success
                      : ehDebito
                          ? GridColors.error
                          : Colors.grey;
                  final iconeTipo = ehCredito
                      ? Icons.arrow_downward
                      : ehDebito
                          ? Icons.arrow_upward
                          : Icons.swap_horiz;
                  final tipoLabel = ehCredito
                      ? 'CRÉDITO'
                      : ehDebito
                          ? 'DÉBITO'
                          : tipo.toUpperCase();
                  final valorFormatado =
                      'R\$ ${valor.abs().toStringAsFixed(2).replaceAll('.', ',')}';
                  final descricao =
                      linha['descricao']?.toString() ?? '';
                  final data = linha['data']?.toString() ?? '';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(color: corTipo, width: 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: corTipo.withValues(alpha: 0.15),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabeçalho: ícone + tipo + badge valor
                        Row(
                          children: [
                            Icon(iconeTipo, size: 20, color: corTipo),
                            const SizedBox(width: 4),
                            Text(
                              tipoLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: corTipo,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: corTipo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                valorFormatado,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: corTipo,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Descrição
                        Text(
                          descricao,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Data
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 11, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              data,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (linhas.length > 100)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Mostrando 100 de $totalLinhas linha(s)',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumo(
      dynamic totalLinhas, dynamic totalDebitos, dynamic totalCreditos) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _resumoItem('Total de Linhas', totalLinhas.toString(), Icons.list),
          const SizedBox(width: 24),
          _resumoItem(
              'Total Débitos',
              _formatValor((totalDebitos is num ? totalDebitos.toDouble() : 0.0)),
              Icons.arrow_upward,
              color: GridColors.error),
          const SizedBox(width: 24),
          _resumoItem(
              'Total Créditos',
              _formatValor(
                  (totalCreditos is num ? totalCreditos.toDouble() : 0.0)),
              Icons.arrow_downward,
              color: GridColors.success),
        ],
      ),
    );
  }

  Widget _resumoItem(String label, String value, IconData icon,
      {Color? color}) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? GridColors.secondary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color ?? Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoCard() {
    final success = _confirmResult!.success;
    final data = _confirmResult!.data;
    final msg = _confirmResult!.message;
    final importados = data?['importados'] ??
        data?['totalImportados'] ??
        data?['linhasImportadas'] ??
        '?';

    return Card(
      elevation: 2,
      color: success ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  success ? 'Importação Concluída' : 'Erro na Importação',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: success
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              msg ?? (success ? 'Importação realizada com sucesso!' : ''),
              style: TextStyle(
                fontSize: 14,
                color: success
                    ? Colors.green.shade900
                    : Colors.red.shade900,
              ),
            ),
            if (success) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Linhas importadas: $importados',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Nova Importação'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListagemCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: GridColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Extratos Importados',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Atualizar lista',
                  onPressed: _carregandoLista ? null : _carregarListagem,
                ),
              ],
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
              ...(_importacoes.map((imp) {
                final id = imp['id'];
                final nomeArq = imp['arquivoNome'] ?? '—';
                final formato = imp['formato'] ?? '';
                final status = imp['status'] ?? '';
                final totalLinhas = imp['totalLinhas'] ?? 0;
                final importadas = imp['importadas'] ?? 0;
                final criadoAt = imp['createdAt']?.toString() ?? '';
                final dataStr = criadoAt.isNotEmpty
                    ? criadoAt.substring(0, 10)
                    : '—';

                final corStatus = status == 'CONCLUIDO'
                    ? GridColors.success
                    : status == 'ERRO'
                        ? GridColors.error
                        : Colors.orange;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: GridColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: const BorderSide(
                            color: GridColors.divider, width: 1)
                        .style ==
                        BorderStyle.solid
                        ? Border.all(color: GridColors.divider)
                        : null,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.file_present,
                          size: 18, color: GridColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nomeArq,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$dataStr · $formato · $importadas/$totalLinhas linhas',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: corStatus.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                              fontSize: 11,
                              color: corStatus,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: GridColors.error),
                        tooltip: 'Excluir registro de importação',
                        onPressed: () => _excluirImportacao(imp),
                      ),
                    ],
                  ),
                );
              }).toList()),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _extractLinhas(Map<String, dynamic> data) {
    final linhas = data['linhas'] ??
        data['itens'] ??
        data['transacoes'] ??
        data['registros'] ??
        data['data'];
    if (linhas is List) {
      return linhas.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  String _formatValor(double v) {
    return 'R\$${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
