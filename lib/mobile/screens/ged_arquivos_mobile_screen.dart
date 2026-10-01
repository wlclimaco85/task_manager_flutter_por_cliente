import 'package:flutter/material.dart';

import '../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../utils/app_logger.dart';
import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';
import '../widgets/ged_file_card_mobile.dart';

/// Tela GED mobile — lista arquivos em GridView com cards responsivos
/// Suporta: download, rename, delete, classify IA
/// Layout responsivo: portrait (2 colunas), landscape (3 colunas)
class GedArquivosMobileScreen extends StatefulWidget {
  final String? moduloOrigem;
  final int? idOrigem;
  final String? nomeOrigem;
  final int? empresaId;

  const GedArquivosMobileScreen({
    super.key,
    this.moduloOrigem,
    this.idOrigem,
    this.nomeOrigem,
    this.empresaId,
  });

  @override
  State<GedArquivosMobileScreen> createState() =>
      _GedArquivosMobileScreenState();
}

class _GedArquivosMobileScreenState extends State<GedArquivosMobileScreen> {
  List<Map<String, dynamic>> _arquivos = [];
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscarArquivos();
  }

  /// Carrega arquivos do backend
  Future<void> _buscarArquivos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      // Chamar endpoint /ged/listar (ou similar conforme seu backend)
      final url = ApiLinks.baseUrl + '/ged/listar';
      final resp = await NetworkCaller().getRequest(url);

      if (!mounted) return;

      if (resp.statusCode == 200 && resp.body != null) {
        final body = resp.body as Map<String, dynamic>;
        final list = body['data'] ?? body['dados'] ?? [];
        setState(() {
          _arquivos = (list as List)
              .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      } else {
        setState(() {
          _erro = 'Erro ao carregar arquivos (${resp.statusCode})';
        });
      }
    } catch (e) {
      L.e('[GedMobile] erro ao buscar: $e');
      if (mounted) {
        setState(() {
          _erro = 'Erro: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  /// Download arquivo
  Future<void> _baixarArquivo(Map<String, dynamic> arq) async {
    final id = arq['id'];
    L.i('[GedMobile] baixando arquivo $id');
    // TODO: Implementar download_helper.downloadFile(id)
  }

  /// Renomear arquivo
  Future<bool> _renomearArquivo(Map<String, dynamic> arq, String novoNome) async {
    final id = arq['id'];
    L.i('[GedMobile] renomeando arquivo $id para $novoNome');

    try {
      final url = ApiLinks.baseUrl + '/ged/$id/rename';
      final body = {'fileName': novoNome};
      final resp = await NetworkCaller()
          .postRequest(url, body);

      if (resp.statusCode == 200) {
        // Atualizar estado local
        final idx = _arquivos.indexWhere((a) => a['id'] == id);
        if (idx >= 0) {
          setState(() {
            _arquivos[idx]['fileName'] = novoNome;
          });
        }
        return true;
      }
      return false;
    } catch (e) {
      L.e('[GedMobile] erro rename: $e');
      return false;
    }
  }

  /// Excluir arquivo
  Future<void> _excluirArquivo(Map<String, dynamic> arq) async {
    final id = arq['id'];
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Excluir "${arq['fileName']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacao != true) return;

    L.i('[GedMobile] excluindo arquivo $id');

    try {
      final url = ApiLinks.baseUrl + '/ged/$id';
      final resp = await NetworkCaller().deleteRequest(url);

      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _arquivos.removeWhere((a) => a['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo excluído')),
        );
      }
    } catch (e) {
      L.e('[GedMobile] erro delete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final crossAxisCount = isPortrait ? 2 : 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nomeOrigem ?? 'Documentos'),
        centerTitle: true,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _buscarArquivos,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : _arquivos.isEmpty
                  ? const Center(
                      child: Text('Nenhum arquivo encontrado'),
                    )
                  : GridView.builder(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                      ),
                      itemCount: _arquivos.length,
                      itemBuilder: (ctx, idx) {
                        final arq = _arquivos[idx];
                        return GedFileCardMobile(
                          arq: arq,
                          podeExcluir: true, // TODO: Validar permissão
                          onDownload: () => _baixarArquivo(arq),
                          onDelete: () => _excluirArquivo(arq),
                          onRename: (novoNome) =>
                              _renomearArquivo(arq, novoNome),
                        );
                      },
                    ),
    );
  }
}
