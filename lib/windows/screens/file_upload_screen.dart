import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_windows_screen.dart';

class WindowsFileUploadScreen extends StatefulWidget {
  final SecurityCheck hasPermission;

  const WindowsFileUploadScreen({super.key, required this.hasPermission});

  @override
  _WindowsFileUploadScreenState createState() => _WindowsFileUploadScreenState();
}

class _WindowsFileUploadScreenState extends State<WindowsFileUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _diretorioId;
  int? _empresaId;
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  final List<Map<String, dynamic>> _diretorios = [];
  final List<Map<String, dynamic>> _empresas = [];

  @override
  void initState() {
    super.initState();
    _loadDiretorios();
    _loadEmpresas();
  }

  Future<void> _loadDiretorios() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allDiretorios,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      setState(() {
        _diretorios.clear();
        _diretorios.addAll(
          data
              .map((item) => {'value': item['id'], 'label': item['nome']})
              .toList(),
        );
      });
    }
  }

  Future<void> _loadEmpresas() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allEmpresas,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      setState(() {
        _empresas.clear();
        _empresas.addAll(
          data
              .map((item) => {'value': item['id'], 'label': item['nome']})
              .toList(),
        );
      });
    }
  }

  Future<void> _selectFile() async {
    FilePickerResult? result = await FilePicker.pickFiles();

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  // file_upload_screen.dart
  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um arquivo primeiro')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      Uint8List? fileBytes = _selectedFile!.bytes;
      String fileName = _selectedFile!.name;

      // Se não temos os bytes em memória, ler do arquivo
      if (fileBytes == null && _selectedFile!.path != null) {
        File ioFile = File(_selectedFile!.path!);
        fileBytes = await ioFile.readAsBytes();
      }

      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível ler o arquivo')),
        );
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.uploadArquivo),
      );

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      // Adicionar campos adicionais
      if (_diretorioId != null) {
        request.fields['diretorioId'] = _diretorioId!.toString();
      }
      if (_empresaId != null) {
        request.fields['empresaId'] = _empresaId!.toString();
      }

      // Adicionar headers de autenticação se necessário
      // request.headers['Authorization'] = 'Bearer seu_token';

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        // Processar a resposta conforme necessário

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo enviado com sucesso!')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha no upload: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload de Arquivo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _diretorioId,
                decoration: const InputDecoration(
                  labelText: 'Diretório',
                  border: OutlineInputBorder(),
                ),
                items: _diretorios.map((diretorio) {
                  return DropdownMenuItem<int>(
                    value: diretorio['value'],
                    child: Text(diretorio['label']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _diretorioId = value;
                  });
                },
                isExpanded: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _empresaId,
                decoration: const InputDecoration(
                  labelText: 'Empresa',
                  border: OutlineInputBorder(),
                ),
                items: _empresas.map((empresa) {
                  return DropdownMenuItem<int>(
                    value: empresa['value'],
                    child: Text(empresa['label']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _empresaId = value;
                  });
                },
                isExpanded: true,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _selectFile,
                child: const Text('Selecionar Arquivo'),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFile != null
                    ? 'Arquivo selecionado: ${_selectedFile!.name}'
                    : 'Nenhum arquivo selecionado',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadFile,
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Fazer Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
