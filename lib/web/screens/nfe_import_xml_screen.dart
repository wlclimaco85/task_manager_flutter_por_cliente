import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/nfe_xml_import_caller.dart';
import '../../../utils/grid_colors.dart';
import '../../../widgets/nfe_importacoes_grid.dart';
import '../../../widgets/nfe_xml_preview_widget.dart';

class WebNfeImportXmlScreen extends StatefulWidget {
  const WebNfeImportXmlScreen({super.key});

  @override
  State<WebNfeImportXmlScreen> createState() => _WebNfeImportXmlScreenState();
}

class _WebNfeImportXmlScreenState extends State<WebNfeImportXmlScreen> {
  PlatformFile? _arquivoXml;
  bool _carregando = false;
  bool _confirmando = false;

  Map<String, dynamic>? _previewData;
  bool? _sucesso;
  String? _mensagem;

  // Pedido explicito do usuario: a tela precisa de uma grid padrao mostrando
  // o que ja foi importado -- atualizada automaticamente apos cada
  // confirmação de importação bem-sucedida.
  final GlobalKey<NfeImportacoesGridState> _gridKey =
      GlobalKey<NfeImportacoesGridState>();

  void _reset() {
    setState(() {
      _previewData = null;
      _sucesso = null;
      _mensagem = null;
    });
  }

  Future<void> _selecionarXml() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
      withData: true,
    );
    if (result != null) {
      final file = result.files.first;
      setState(() {
        _arquivoXml = file;
        _reset();
      });
    }
  }

  Future<void> _carregarPreview() async {
    if (_arquivoXml?.bytes == null) {
      _mostrarSnack('Selecione um arquivo XML primeiro');
      return;
    }

    setState(() {
      _carregando = true;
      _reset();
    });

    final result = await NfeXmlImportCaller.preview(
        _arquivoXml!.bytes!, _arquivoXml!.name);

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _carregando = false;
        _previewData = result.data;
      });
    } else {
      setState(() {
        _carregando = false;
        _sucesso = false;
        _mensagem = result.message;
      });
    }
  }

  Future<void> _confirmarImportacao(
      List<Map<String, dynamic>> conciliacoes) async {
    setState(() => _confirmando = true);

    final result = await NfeXmlImportCaller.confirmar(
        _arquivoXml!.bytes!, _arquivoXml!.name,
        conciliacoes: conciliacoes);

    if (!mounted) return;

    setState(() {
      _confirmando = false;
      _sucesso = result.success;
      _mensagem =
          result.success ? 'XML NF-e importado com sucesso!' : result.message;
    });

    if (result.success) {
      await _gridKey.currentState?.recarregar();
    }
  }

  void _limpar() {
    setState(() {
      _arquivoXml = null;
      _previewData = null;
      _sucesso = null;
      _mensagem = null;
    });
  }

  void _mostrarSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Importar XML NF-e'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstrucoes(),
            const SizedBox(height: 24),
            _buildSelecaoArquivo(),
            const SizedBox(height: 24),
            if (_previewData != null) ...[
              NfeXmlPreviewWidget(
                data: _previewData!,
                confirming: _confirmando,
                onConfirm: _confirmarImportacao,
                onCancel: _limpar,
              ),
            ],
            if (_sucesso != null) _buildResultado(),
            const SizedBox(height: 24),
            NfeImportacoesGrid(key: _gridKey),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrucoes() {
    return const Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: GridColors.secondary),
                SizedBox(width: 8),
                Text(
                  'Instruções de Importação',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Selecione um arquivo XML de NF-e (Modelo 55) para importar.\n'
              'Após selecionar, clique em "Carregar e Visualizar" para pré-visualizar\n'
              'os dados da nota antes de confirmar a importação.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecaoArquivo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecionar Arquivo XML',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 20),
            _buildSeletorArquivo(),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                  onPressed: (_arquivoXml != null && !_carregando)
                      ? _carregarPreview
                      : null,
                  icon: _carregando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.visibility),
                  label: Text(
                      _carregando ? 'Carregando...' : 'Carregar e Visualizar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _carregando ? null : _limpar,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeletorArquivo() {
    return InkWell(
      onTap: _selecionarXml,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _arquivoXml != null
                ? GridColors.secondary
                : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _arquivoXml != null
              ? GridColors.secondary.withValues(alpha: 0.05)
              : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              _arquivoXml != null ? Icons.check_circle : Icons.file_present,
              color: _arquivoXml != null ? GridColors.secondary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _arquivoXml != null
                    ? '${_arquivoXml!.name} (${(_arquivoXml!.size / 1024).toStringAsFixed(1)} KB)'
                    : 'Clique para selecionar arquivo XML',
                style: TextStyle(
                  fontSize: 13,
                  color: _arquivoXml != null
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_arquivoXml != null)
              TextButton(
                onPressed: _selecionarXml,
                child: const Text('Trocar', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultado() {
    return Card(
      elevation: 2,
      color: _sucesso == true ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              _sucesso == true ? Icons.check_circle : Icons.error,
              color: _sucesso == true ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sucesso == true
                        ? 'Importação Concluída'
                        : 'Erro na Importação',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _sucesso == true
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                  if (_mensagem != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _mensagem!,
                      style: TextStyle(
                        fontSize: 13,
                        color: _sucesso == true
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_sucesso == true)
              OutlinedButton(
                onPressed: _limpar,
                child: const Text('Importar outro'),
              ),
          ],
        ),
      ),
    );
  }
}
