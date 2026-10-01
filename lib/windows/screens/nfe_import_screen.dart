import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';

/// H11: Tela de importação de NF-e via 2 arquivos CSV (cabeçalho + itens)
class NfeImportScreen extends StatefulWidget {
  const NfeImportScreen({super.key});

  @override
  State<NfeImportScreen> createState() => _NfeImportScreenState();
}

class _NfeImportScreenState extends State<NfeImportScreen> {
  PlatformFile? _arquivoCabecalho;
  PlatformFile? _arquivoItens;
  bool _importando = false;

  // Resultado da importação
  bool? _sucesso;
  String? _mensagem;
  List<dynamic> _erros = [];
  Map<String, dynamic>? _resultado;

  Future<void> _selecionarCabecalho() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        _arquivoCabecalho = result.files.first;
        _sucesso = null;
        _mensagem = null;
        _erros = [];
        _resultado = null;
      });
    }
  }

  Future<void> _selecionarItens() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        _arquivoItens = result.files.first;
        _sucesso = null;
        _mensagem = null;
        _erros = [];
        _resultado = null;
      });
    }
  }

  Future<void> _importar() async {
    if (_arquivoCabecalho == null) {
      _mostrarSnack('Selecione o arquivo de cabeçalho CSV');
      return;
    }
    if (_arquivoItens == null) {
      _mostrarSnack('Selecione o arquivo de itens CSV');
      return;
    }

    setState(() {
      _importando = true;
      _sucesso = null;
      _mensagem = null;
      _erros = [];
      _resultado = null;
    });

    try {
      final url = TenantContext.applyToUrl(ApiLinks.importarNfeCsv);
      final token = AuthUtility.userInfo?.token;

      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      request.files.add(http.MultipartFile.fromBytes(
        'cabecalho',
        _arquivoCabecalho!.bytes!,
        filename: _arquivoCabecalho!.name,
      ));
      request.files.add(http.MultipartFile.fromBytes(
        'itens',
        _arquivoItens!.bytes!,
        filename: _arquivoItens!.name,
      ));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
        setState(() {
          _sucesso = true;
          _resultado = body is Map<String, dynamic> ? body : {'resposta': body};
          _mensagem = _resultado?['mensagem']?.toString() ??
              _resultado?['message']?.toString() ??
              'Importação realizada com sucesso!';
          _erros = _resultado?['erros'] as List<dynamic>? ?? [];
        });
      } else {
        String msg = 'Erro na importação (${resp.statusCode})';
        List<dynamic> erros = [];
        try {
          final body = jsonDecode(resp.body);
          msg = body['mensagem']?.toString() ??
              body['message']?.toString() ??
              body['error']?.toString() ??
              msg;
          erros = body['erros'] as List<dynamic>? ?? [];
        } catch (_) {}
        setState(() {
          _sucesso = false;
          _mensagem = msg;
          _erros = erros;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sucesso = false;
          _mensagem = 'Erro ao conectar: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  void _mostrarSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _limpar() {
    setState(() {
      _arquivoCabecalho = null;
      _arquivoItens = null;
      _sucesso = null;
      _mensagem = null;
      _erros = [];
      _resultado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Importação de NF-e via CSV'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstrucoes(),
            const SizedBox(height: 24),
            _buildFormulario(),
            const SizedBox(height: 24),
            if (_sucesso != null) _buildResultado(),
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
              'Esta tela permite importar NF-e a partir de dois arquivos CSV:\n'
              '  1. Arquivo de Cabeçalho: contém os dados gerais de cada nota (chave, emitente, destinatário, valores)\n'
              '  2. Arquivo de Itens: contém os produtos/serviços de cada nota\n\n'
              'Ambos os arquivos devem usar separador ponto-e-vírgula (;) e codificação UTF-8.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecionar Arquivos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 20),
            // Arquivo de cabeçalho
            _buildSeletorArquivo(
              titulo: 'Arquivo de Cabeçalho (CSV) *',
              arquivo: _arquivoCabecalho,
              onSelecionar: _selecionarCabecalho,
              icone: Icons.description,
            ),
            const SizedBox(height: 16),
            // Arquivo de itens
            _buildSeletorArquivo(
              titulo: 'Arquivo de Itens (CSV) *',
              arquivo: _arquivoItens,
              onSelecionar: _selecionarItens,
              icone: Icons.list_alt,
            ),
            const SizedBox(height: 24),
            // Botões
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                  onPressed: _importando ? null : _importar,
                  icon: _importando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(_importando ? 'Importando...' : 'Importar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _importando ? null : _limpar,
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

  Widget _buildSeletorArquivo({
    required String titulo,
    required PlatformFile? arquivo,
    required VoidCallback onSelecionar,
    required IconData icone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onSelecionar,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: arquivo != null
                    ? GridColors.secondary
                    : Colors.grey.shade300,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
              color: arquivo != null
                  ? GridColors.secondary.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  arquivo != null ? Icons.check_circle : icone,
                  color: arquivo != null ? GridColors.secondary : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    arquivo != null
                        ? '${arquivo.name} (${(arquivo.size / 1024).toStringAsFixed(1)} KB)'
                        : 'Clique para selecionar arquivo CSV',
                    style: TextStyle(
                      fontSize: 13,
                      color: arquivo != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (arquivo != null)
                  TextButton(
                    onPressed: onSelecionar,
                    child: const Text('Trocar', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultado() {
    return Card(
      elevation: 2,
      color: _sucesso == true ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _sucesso == true ? Icons.check_circle : Icons.error,
                  color: _sucesso == true ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
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
              ],
            ),
            if (_mensagem != null) ...[
              const SizedBox(height: 12),
              Text(
                _mensagem!,
                style: TextStyle(
                  fontSize: 14,
                  color: _sucesso == true
                      ? Colors.green.shade900
                      : Colors.red.shade900,
                ),
              ),
            ],
            if (_resultado != null) ...[
              const SizedBox(height: 12),
              _buildResumoResultado(),
            ],
            if (_erros.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Erros encontrados:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ..._erros.take(10).map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (_erros.length > 10)
                Text(
                  '... e mais ${_erros.length - 10} erros',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResumoResultado() {
    final campos = <String, dynamic>{};
    final keys = [
      'importadas',
      'totalImportadas',
      'notas',
      'total',
      'ignoradas',
      'erros',
      'duplicadas',
    ];
    for (final key in keys) {
      if (_resultado!.containsKey(key)) campos[key] = _resultado![key];
    }
    if (campos.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: campos.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            '${e.key}: ${e.value}',
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
  }
}
