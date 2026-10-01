import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/boleto_lote_caller.dart';
import '../utils/grid_colors.dart';

class BoletoImportacaoLoteScreen extends StatefulWidget {
  const BoletoImportacaoLoteScreen({super.key});

  @override
  State<BoletoImportacaoLoteScreen> createState() =>
      _BoletoImportacaoLoteScreenState();
}

class _BoletoImportacaoLoteScreenState
    extends State<BoletoImportacaoLoteScreen> {
  List<PlatformFile> _arquivos = [];
  List<BoletoLoteItem> _itens = [];
  String? _loteId;
  bool _enviando = false;
  bool _confirmando = false;
  Map<String, dynamic>? _resultado;

  Future<void> _selecionarArquivos() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _arquivos = result.files);
    }
  }

  Future<void> _enviar() async {
    if (_arquivos.isEmpty) return;
    setState(() {
      _enviando = true;
      _resultado = null;
    });

    final loteId = await BoletoLoteCaller.iniciarLote();
    if (loteId == null) {
      _snack('Erro ao criar lote', error: true);
      setState(() => _enviando = false);
      return;
    }
    _loteId = loteId;

    final batchSize = 10;
    final List<BoletoLoteItem> todosItens = [];
    for (var i = 0; i < _arquivos.length; i += batchSize) {
      final batch = _arquivos.sublist(
        i,
        i + batchSize > _arquivos.length ? _arquivos.length : i + batchSize,
      );
      final itens = await BoletoLoteCaller.enviarArquivos(loteId, batch);
      todosItens.addAll(itens);
    }

    if (!mounted) return;
    setState(() {
      _itens = todosItens;
      _enviando = false;
    });

    if (todosItens.isEmpty) {
      _snack('Nenhum boleto processado — os PDFs podem ser invalidos ou o OCR nao conseguiu ler', error: true);
    }
  }

  Future<void> _confirmar() async {
    if (_loteId == null || _itens.isEmpty) return;
    final validos =
        _itens.where((i) => i.parceiroIdConfirmado != null).toList();
    if (validos.isEmpty) {
      _snack('Nenhum item com parceiro vinculado', error: true);
      return;
    }

    setState(() => _confirmando = true);
    final result = await BoletoLoteCaller.confirmar(_loteId!, validos);
    if (!mounted) return;
    setState(() {
      _confirmando = false;
      _resultado = result;
    });

    if (result != null) {
      _snack(
          '${result['contasGeradas'] ?? 0} contas geradas, ${result['anexosGerados'] ?? 0} anexos');
    } else {
      _snack('Erro ao confirmar lote', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, color: GridColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Importação em lote de boletos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_itens.isEmpty)
                FilledButton.icon(
                  onPressed: _enviando ? null : _selecionarArquivos,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Selecionar PDFs'),
                  style: FilledButton.styleFrom(
                    backgroundColor: GridColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_arquivos.isNotEmpty && _itens.isEmpty) ...[
            Text('${_arquivos.length} arquivo(s) selecionado(s)'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload, size: 18),
              label: Text(_enviando ? 'Enviando...' : 'Enviar e processar'),
              style: FilledButton.styleFrom(
                backgroundColor: GridColors.primary,
              ),
            ),
          ],
          if (_itens.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildResumo(),
            const SizedBox(height: 12),
            Expanded(child: _buildTabela()),
            const SizedBox(height: 12),
            if (_resultado == null)
              FilledButton.icon(
                onPressed: _confirmando ? null : _confirmar,
                icon: _confirmando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 18),
                label: Text(_confirmando
                    ? 'Confirmando...'
                    : 'Confirmar ${_itens.where((i) => i.parceiroIdConfirmado != null).length} itens'),
                style: FilledButton.styleFrom(
                  backgroundColor: GridColors.success,
                ),
              ),
            if (_resultado != null)
              Card(
                color: GridColors.success.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Concluído: ${_resultado!['contasGeradas'] ?? 0} contas geradas, '
                    '${_resultado!['anexosGerados'] ?? 0} anexos, '
                    '${_resultado!['erros'] ?? 0} erros',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
          if (_itens.isEmpty && _arquivos.isEmpty && !_enviando)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Selecione os PDFs dos boletos para importar'),
                    SizedBox(height: 4),
                    Text(
                      'O sistema extrai valor, vencimento e CNPJ/CPF automaticamente\n'
                      'e sugere o parceiro correspondente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResumo() {
    final comMatch = _itens.where((i) => !i.semMatch && i.erro == null).length;
    final semMatch = _itens.where((i) => i.semMatch).length;
    final comErro = _itens.where((i) => i.erro != null).length;
    return Row(
      children: [
        _chip('$comMatch com match', GridColors.success),
        const SizedBox(width: 8),
        if (semMatch > 0) ...[
          _chip('$semMatch sem match', Colors.orange),
          const SizedBox(width: 8),
        ],
        if (comErro > 0) _chip('$comErro com erro', GridColors.error),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTabela() {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(
          GridColors.primary.withValues(alpha: 0.06),
        ),
        columns: const [
          DataColumn(label: Text('Arquivo')),
          DataColumn(label: Text('Documento')),
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Vencimento')),
          DataColumn(label: Text('Parceiro sugerido')),
          DataColumn(label: Text('Status')),
        ],
        rows: _itens.map((item) {
          final hasError = item.erro != null;
          final noMatch = item.semMatch;
          return DataRow(
            color: WidgetStateProperty.all(
              hasError
                  ? GridColors.error.withValues(alpha: 0.05)
                  : noMatch
                      ? Colors.orange.withValues(alpha: 0.05)
                      : Colors.transparent,
            ),
            cells: [
              DataCell(Text(item.nomeArquivo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13))),
              DataCell(Text(item.documentoExtraido ?? '-',
                  style: const TextStyle(fontSize: 13))),
              DataCell(Text(
                  item.valorExtraido != null
                      ? 'R\$ ${item.valorExtraido!.toStringAsFixed(2)}'
                      : '-',
                  style: const TextStyle(fontSize: 13))),
              DataCell(Text(item.vencimentoExtraido ?? '-',
                  style: const TextStyle(fontSize: 13))),
              DataCell(Text(
                  item.parceiroNomeSugerido ?? (noMatch ? 'Sem match' : '-'),
                  style: TextStyle(
                    fontSize: 13,
                    color: noMatch ? Colors.orange : null,
                    fontWeight: noMatch ? FontWeight.w600 : null,
                  ))),
              DataCell(
                hasError
                    ? Tooltip(
                        message: item.erro!,
                        child: const Icon(Icons.error,
                            color: GridColors.error, size: 18))
                    : noMatch
                        ? const Icon(Icons.warning,
                            color: Colors.orange, size: 18)
                        : const Icon(Icons.check_circle,
                            color: GridColors.success, size: 18),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
