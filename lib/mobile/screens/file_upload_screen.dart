import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../../constants/custom_colors.dart';
import '../../services/diretorio_caller.dart';
import '../../services/file_caller.dart';
import '../../services/parceiro_caller.dart';
import '../../services/upload_file_caller.dart';
import '../../../utils/api_links.dart';
import '../../../models/auth_utility.dart';
import '../../../widgets/user_banners.dart';

import 'package:task_manager_flutter/utils/app_logger.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  final FileCaller _caller = FileCaller();

  List<Map<String, dynamic>> _diretorios = [];
  bool _isLoading = false;

  /// controla quais diretórios estão abertos (accordion)
  final Set<int> _expandedTiles = {};

  /// busca
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDiretorios();
  }

  Future<void> _loadDiretorios() async {
    setState(() => _isLoading = true);
    _diretorios = await _caller.fetchDiretorios();
    setState(() => _isLoading = false);
  }

  // ========= Upload =========

  Future<File> _writeTempFile(Uint8List bytes,
      {String name = 'preview.pdf'}) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _showUploadDialog() async {
    final formKey = GlobalKey<FormState>();
    final diretorioCaller = DiretorioCaller();
    final parceiroCaller = ParceiroCaller();

    // Busca diretórios e parceiros de forma segura (sem throw)
    final List<Map<String, dynamic>> diretorios =
        await diretorioCaller.fetchDiretoriosDropdown().catchError((_) => <Map<String, dynamic>>[]);
    final List<Map<String, dynamic>> parceiroItems =
        await parceiroCaller.fetchParceiroDropdown().catchError((_) => <Map<String, dynamic>>[]);

    // Empresa logada (somente exibição)
    final empresaNome =
        AuthUtility.userInfo?.login?.empresa?.nome ?? 'Empresa atual';

    int? diretorioSelecionado;
    int? parceiroSelecionado;
    Uint8List? fileBytes;
    String? fileName;
    String? fileType;
    final TextEditingController nomeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: GridColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: GridColors.primary, width: 2),
          ),
          title: const Text(
            "Enviar Arquivo",
            style: TextStyle(
              color: GridColors.secondary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file,
                        color: GridColors.secondary),
                    label: const Text("Selecionar Arquivo",
                        style: TextStyle(color: GridColors.secondary)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: GridColors.primary)),
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(withData: true);
                      if (result != null) {
                        final f = result.files.first;
                        try {
                          fileBytes = f.bytes ??
                              (f.path != null
                                  ? await File(f.path!).readAsBytes()
                                  : null);
                        } catch (_) {
                          fileBytes = null;
                        }
                        fileName = f.name;
                        fileType = ".${f.name.split('.').last}".toLowerCase();
                        setStateDialog(() => nomeController.text = fileName!);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: "Nome do Arquivo",
                      labelStyle: TextStyle(color: GridColors.textSecondary),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: GridColors.primary)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: GridColors.primary, width: 2)),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Informe o nome" : null,
                  ),
                  const SizedBox(height: 12),
                  // Empresa logada — somente exibição
                  TextFormField(
                    initialValue: empresaNome,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Empresa",
                      labelStyle:
                          TextStyle(color: GridColors.textSecondary),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: GridColors.primary)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: GridColors.primary, width: 2)),
                      prefixIcon: Icon(Icons.business,
                          color: GridColors.secondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Diretório",
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: GridColors.primary)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: GridColors.primary, width: 2)),
                    ),
                    items: diretorios
                        .map((e) => DropdownMenuItem<int>(
                            value: e['value'], child: Text(e['label'])))
                        .toList(),
                    onChanged: (v) =>
                        setStateDialog(() => diretorioSelecionado = v),
                    validator: (v) =>
                        v == null ? "Selecione um diretório" : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Parceiro (opcional)",
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: GridColors.primary)),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: GridColors.primary, width: 2)),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                          value: null, child: Text('Sem parceiro')),
                      ...parceiroItems.map((p) => DropdownMenuItem<int>(
                          value: p['value'] as int?,
                          child: Text((p['label'] as String?) ?? 'Sem nome'))),
                    ],
                    onChanged: (v) =>
                        setStateDialog(() => parceiroSelecionado = v),
                  ),
                  const SizedBox(height: 12),
                  if (fileType != null)
                    Text("Tipo: $fileType",
                        style: const TextStyle(color: GridColors.primaryLight)),
                  if (fileBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: (fileType?.contains("pdf") ?? false)
                            ? SizedBox(
                                height: 200,
                                child: FutureBuilder<File>(
                                  future: _writeTempFile(
                                    fileBytes!,
                                    name:
                                        'preview_${DateTime.now().millisecondsSinceEpoch}.pdf',
                                  ),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                            color: GridColors.secondary),
                                      );
                                    }
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.picture_as_pdf,
                                            size: 48, color: GridColors.error),
                                        const SizedBox(height: 8),
                                        const Text('PDF selecionado',
                                            style: TextStyle(
                                                color:
                                                    GridColors.textSecondary)),
                                        TextButton.icon(
                                          icon: const Icon(Icons.open_in_new,
                                              color: GridColors.secondary),
                                          label: const Text('Abrir',
                                              style: TextStyle(
                                                  color: GridColors.secondary)),
                                          onPressed: () async {
                                            final uri =
                                                Uri.file(snapshot.data!.path);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : ((fileType?.contains("jpg") ?? false) ||
                                    (fileType?.contains("jpeg") ?? false) ||
                                    (fileType?.contains("png") ?? false))
                                ? Image.memory(fileBytes!, height: 150)
                                : const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar",
                  style: TextStyle(color: GridColors.error)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload, color: GridColors.textPrimary),
              label: const Text("Enviar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary,
                foregroundColor: GridColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (fileBytes == null) {
                    _showSnackBar("Selecione um arquivo antes de enviar.",
                        GridColors.warning, Icons.warning_amber);
                    return;
                  }
                  final ok = await _caller.insertFileAttachment(
                    fileBytes: fileBytes!,
                    fileName: nomeController.text,
                    fileType: fileType ?? "unknown",
                    diretorioId: diretorioSelecionado!,
                    parceiroId: parceiroSelecionado,
                  );
                  if (ok) {
                    if (mounted) Navigator.pop(context);
                    await _loadDiretorios();
                    _showSnackBar("Arquivo enviado com sucesso!",
                        GridColors.success, Icons.check_circle);
                  } else {
                    _showSnackBar("Erro ao enviar arquivo!", GridColors.error,
                        Icons.error);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========= Preview / Download =========

  Future<Uint8List?> _fetchFileBytes(int fileId) async {
    try {
      final String authToken = '${AuthUtility.userInfo?.token}';
      final uri = Uri.parse(ApiLinks.downloadFile(fileId.toString()));
      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $authToken'});
      if (res.statusCode == 200) return res.bodyBytes;
      return null;
    } catch (e) {
      // ignore: avoid_print
      L.d('Erro ao baixar bytes: $e');
      return null;
    }
  }

  void _openPreviewSheet(int fileId, String fileName, {required int dirId}) {
    final ext = fileName.split('.').last.toLowerCase();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: GridColors.primary,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  _fileTypeIcon(ext, size: 20, color: GridColors.textPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: GridColors.textPrimary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: GridColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),

            // Body (preview)
            Expanded(
              child: FutureBuilder<Uint8List?>(
                future: _fetchFileBytes(fileId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: GridColors.secondary));
                  }
                  final bytes = snap.data;
                  if (bytes == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Não foi possível gerar a pré-visualização.\nVocê pode fazer o download do arquivo.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (ext == 'pdf') {
                    return FutureBuilder<File>(
                      future: _writeTempFile(bytes,
                          name:
                              'preview_${DateTime.now().millisecondsSinceEpoch}.pdf'),
                      builder: (context, pdfSnap) {
                        if (!pdfSnap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: GridColors.secondary));
                        }
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                size: 64, color: GridColors.error),
                            const SizedBox(height: 12),
                            const Text('Visualização de PDF não disponível.',
                                style:
                                    TextStyle(color: GridColors.textSecondary)),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              icon: const Icon(Icons.open_in_new,
                                  color: GridColors.secondary),
                              label: const Text('Abrir externamente',
                                  style:
                                      TextStyle(color: GridColors.secondary)),
                              onPressed: () async {
                                final uri = Uri.file(pdfSnap.data!.path);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
                      .contains(ext)) {
                    return Center(child: Image.memory(bytes));
                  } else if (['txt', 'csv', 'log'].contains(ext)) {
                    try {
                      final txt = String.fromCharCodes(bytes);
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Text(txt),
                      );
                    } catch (_) {
                      return const Center(
                          child: Text(
                              'Prévia indisponível para este tipo de arquivo.'));
                    }
                  } else {
                    return const Center(
                        child: Text(
                            'Prévia indisponível para este tipo de arquivo.'));
                  }
                },
              ),
            ),

            // Footer (ações)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download,
                          color: GridColors.secondary),
                      label: const Text('Baixar',
                          style: TextStyle(color: GridColors.secondary)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: GridColors.primary)),
                      onPressed: () async {
                        await UploadFileCaller().downloadFile(fileId, fileName);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete, color: GridColors.error),
                      label: const Text('Excluir',
                          style: TextStyle(color: GridColors.error)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: GridColors.primary)),
                      onPressed: () => _confirmDelete(fileId, dirId),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========= Delete =========

  void _confirmDelete(int id, int dirId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GridColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: GridColors.primary, width: 2),
        ),
        title: const Text(
          "Excluir Documento",
          style:
              TextStyle(color: GridColors.primary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Deseja realmente excluir este documento?",
          style: TextStyle(color: GridColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar",
                style: TextStyle(color: GridColors.secondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _caller.deleteArquivo(id);
              await _loadDiretorios();
              _showSnackBar("Arquivo excluído com sucesso!", GridColors.success,
                  Icons.delete_forever);
            },
            child: const Text("Excluir",
                style: TextStyle(color: GridColors.error)),
          ),
        ],
      ),
    );
  }

  // ========= UI helpers =========

  void _showSnackBar(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: GridColors.textPrimary),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(color: GridColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Icon _fileTypeIcon(String ext, {double size = 18, Color? color}) {
    final c = color ?? GridColors.secondary;
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icon(Icons.picture_as_pdf, color: GridColors.error, size: size);
      case 'xls':
      case 'xlsx':
        return Icon(Icons.grid_on, color: c, size: size);
      case 'csv':
      case 'txt':
        return Icon(Icons.description, color: c, size: size);
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return Icon(Icons.image, color: c, size: size);
      default:
        return Icon(Icons.insert_drive_file, color: c, size: size);
    }
  }

  List<Map<String, dynamic>> _filteredDiretorios() {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List<Map<String, dynamic>>.from(_diretorios);

    final result = _diretorios
        .map<Map<String, dynamic>>((dir) {
          final nome = (dir['nome'] ?? '').toString().toLowerCase();
          final arquivos =
              (dir['arquivos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final arquivosFiltrados = arquivos.where((a) {
            final n = (a['nome'] ?? '').toString().toLowerCase();
            return n.contains(q);
          }).toList();

          final pastaBate = nome.contains(q);
          if (pastaBate) {
            // mantém todos os arquivos se a pasta bate
            return Map<String, dynamic>.from(dir);
          } else if (arquivosFiltrados.isNotEmpty) {
            // mantém a pasta, porém só com os arquivos filtrados
            final copy = Map<String, dynamic>.from(dir);
            copy['arquivos'] = arquivosFiltrados;
            copy['totalArquivos'] = arquivosFiltrados.length;
            copy['naoLidos'] =
                arquivosFiltrados.where((a) => a['lido'] != true).length;
            return copy;
          } else {
            // pasta não entra
            return <String, dynamic>{};
          }
        })
        .where((e) => e.isNotEmpty)
        .toList();

    return List<Map<String, dynamic>>.from(result);
  }

  Widget _buildDiretorioBox(Map<String, dynamic> dir) {
    final id = dir['id'];
    final nome = dir['nome'] ?? 'Sem nome';
    final rawArquivos = (dir['arquivos'] ?? dir['files']) as List?;
    final total = rawArquivos?.length ?? 0;
    final naoLidos = dir['naoLidos'] ?? 0;
    final arquivos = List<Map<String, dynamic>>.from(rawArquivos ?? []);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: GridColors.shadow, blurRadius: 6, offset: Offset(0, 2))
        ],
        border: Border.all(color: GridColors.primary, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<int>(id),
          initiallyExpanded: _expandedTiles.contains(id),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          trailing: AnimatedRotation(
            turns: _expandedTiles.contains(id) ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down,
                color: GridColors.textSecondary),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedTiles.clear(); // accordion
                _expandedTiles.add(id);
              } else {
                _expandedTiles.remove(id);
              }
            });
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.folder,
                      color: _expandedTiles.contains(id)
                          ? GridColors.secondaryLight
                          : GridColors.secondary),
                  const SizedBox(width: 8),
                  Text(nome,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: GridColors.textSecondary)),
                ],
              ),
              Row(
                children: [
                  if (naoLidos > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: GridColors.error,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text("$naoLidos não lidos",
                          style: const TextStyle(
                              color: GridColors.textPrimary, fontSize: 12)),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: GridColors.warning,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text("$total docs",
                        style: const TextStyle(
                            color: GridColors.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: arquivos.isEmpty
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: const Padding(
                padding: EdgeInsets.all(12),
                child: Text("Nenhum arquivo disponível",
                    style: TextStyle(color: GridColors.textSecondary)),
              ),
              secondChild: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  children: arquivos.map((arq) {
                    final lido = arq['lido'] == true;
                    final fileName = (arq['fileName'] ?? 'Sem nome') as String;
                    final dataUpload = arq['dataUpload'] ?? '--';
                    final ext = fileName.split('.').last.toLowerCase();
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: GridColors.card,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: GridColors.shadow, blurRadius: 4)
                        ],
                      ),
                      child: ListTile(
                        onTap: () =>
                            _openPreviewSheet(arq['id'], fileName, dirId: id),
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _fileTypeIcon(ext,
                                color: lido
                                    ? GridColors.success
                                    : GridColors.primary),
                            if (!lido)
                              const Positioned(
                                right: -2,
                                top: -2,
                                child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: GridColors.error),
                              ),
                          ],
                        ),
                        title: Text(fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          "Upload: $dataUpload • ${lido ? 'Lido' : 'Não lido'}",
                          style: TextStyle(
                              color:
                                  lido ? GridColors.success : GridColors.error,
                              fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Baixar',
                              icon: const Icon(Icons.download,
                                  color: GridColors.secondary),
                              onPressed: () async => UploadFileCaller()
                                  .downloadFile(arq['id'], fileName),
                            ),
                            IconButton(
                              tooltip: 'Excluir',
                              icon: const Icon(Icons.delete,
                                  color: GridColors.error),
                              onPressed: () => _confirmDelete(arq['id'], id),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filteredDiretorios();

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: UserBannerAppBar(
        screenTitle: "Gerenciador de Arquivos",
        isLoading: _isLoading,
        showFilterButton: false,
        onRefresh: _loadDiretorios,
      ),
      body: Column(
        children: [
          // BUSCA
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Buscar pasta ou arquivo…',
                prefixIcon: Icon(Icons.search, color: GridColors.secondary),
                filled: true,
                fillColor: GridColors.card,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: GridColors.primary),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: GridColors.primary, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: GridColors.secondary))
                : filtrados.isEmpty
                    ? const Center(
                        child: Text(
                          "Nenhum diretorio/arquivo encontrado",
                          style: TextStyle(
                            color: GridColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtrados.length,
                        itemBuilder: (context, i) =>
                            _buildDiretorioBox(filtrados[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildFAB(Icons.refresh, GridColors.primary, GridColors.textPrimary,
              _loadDiretorios, "refresh"),
          const SizedBox(height: 10),
          _buildFAB(Icons.add, GridColors.primary, GridColors.textPrimary,
              _showUploadDialog, "add"),
        ],
      ),
    );
  }

  Widget _buildFAB(IconData icon, Color backgroundColor, Color foregroundColor,
      VoidCallback onPressed, String tag) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: GridColors.card, width: 2),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: GridColors.shadow, blurRadius: 8, spreadRadius: 2)
        ],
      ),
      child: FloatingActionButton(
        heroTag: tag,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
