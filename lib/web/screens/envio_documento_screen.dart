import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class EnvioDocumentoScreen extends StatefulWidget {
  final int? parceiroId;

  const EnvioDocumentoScreen({super.key, this.parceiroId});

  @override
  State<EnvioDocumentoScreen> createState() => _EnvioDocumentoScreenState();
}

class _EnvioDocumentoScreenState extends State<EnvioDocumentoScreen> {
  final _picker = ImagePicker();
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<XFile> _arquivos = [];
  bool _enviando = false;
  List<Map<String, dynamic>> _enviados = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarEnviados();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarEnviados() async {
    try {
      final parceiroParam = widget.parceiroId != null
          ? '?parceiroId=${widget.parceiroId}' : '';
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/documentos-cliente$parceiroParam');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final lista = body['data'] ?? body['content'] ?? [];
        setState(() {
          _enviados = List<Map<String, dynamic>>.from(lista);
          _carregando = false;
        });
      } else {
        setState(() => _carregando = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _selecionarArquivos() async {
    final selecionados = await _picker.pickMultiImage(imageQuality: 85);
    if (selecionados.isNotEmpty) {
      setState(() => _arquivos = selecionados);
    }
  }

  Future<void> _tirarFoto() async {
    final foto = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 85);
    if (foto != null) {
      setState(() => _arquivos = [foto]);
    }
  }

  Future<void> _enviar() async {
    if (_arquivos.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecione ao menos um arquivo')));
      return;
    }
    setState(() => _enviando = true);
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/documentos-cliente/upload');
      final token = AuthUtility.userInfo?.token;

      for (final arquivo in _arquivos) {
        final request = http.MultipartRequest('POST', Uri.parse(url));
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
        if (widget.parceiroId != null) {
          request.fields['parceiroId'] = widget.parceiroId.toString();
        }
        request.fields['nome'] = _nomeCtrl.text.trim().isNotEmpty
            ? _nomeCtrl.text.trim() : arquivo.name;
        request.fields['descricao'] = _descCtrl.text.trim();

        final bytes = await File(arquivo.path).readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'arquivo',
          bytes,
          filename: arquivo.name,
          contentType: MediaType('image', 'jpeg'),
        ));
        await request.send();
      }

      if (!mounted) return;
      setState(() {
        _enviando = false;
        _arquivos = [];
        _nomeCtrl.clear();
        _descCtrl.clear();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Documento(s) enviado(s) com sucesso!')));
      _carregarEnviados();
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao enviar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envio de Documentos'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Novo documento',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: GridColors.primary)),
            const SizedBox(height: 12),
            TextField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do documento (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeria'),
                    onPressed: _selecionarArquivos,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Câmera'),
                    onPressed: _tirarFoto,
                  ),
                ),
              ],
            ),
            if (_arquivos.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('${_arquivos.length} arquivo(s) selecionado(s)',
                  style: TextStyle(color: GridColors.primary)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload),
                label: Text(_enviando ? 'Enviando...' : 'Enviar'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white),
                onPressed: _enviando ? null : _enviar,
              ),
            ),
            const SizedBox(height: 24),
            Text('Documentos enviados',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: GridColors.primary)),
            const SizedBox(height: 8),
            _carregando
                ? const Center(child: CircularProgressIndicator())
                : _enviados.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Nenhum documento enviado',
                              style: TextStyle(color: Colors.grey)),
                        ))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _enviados.length,
                        itemBuilder: (_, i) {
                          final doc = _enviados[i];
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file,
                                color: Colors.grey),
                            title: Text(doc['nome']?.toString() ?? ''),
                            subtitle: Text(
                                doc['dataUpload']?.toString() ?? '',
                                style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
