import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../../customization/dynamic_grid_windows_screen.dart';
import '../../models/alvara_model.dart';
import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';
import '../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType, CustomAction;
import './ged_arquivos_screen.dart';

// Alias de tipo para checar permissões (mesmo padrão dos outros screens)
typedef SecurityCheck = bool Function(String permission);

// ─────────────────────────────────────────────────────────────────────────────
// Tela Web/Windows de Alvarás
// ─────────────────────────────────────────────────────────────────────────────
class WebAlvaraGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebAlvaraGridScreen({super.key, required this.hasPermission});

  // ── Dropdown helpers ────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> _loadEmpresas() async {
    try {
      final token = AuthUtility.userInfo?.token;
      final empId = TenantContext.empresaId;
      final url = empId != null
          ? '${ApiLinks.baseUrl}/api/empresa?empId=$empId'
          : '${ApiLinks.baseUrl}/api/empresa';
      final r = await http.get(Uri.parse(url),
          headers: {if (token != null) 'Authorization': 'Bearer $token'});
      if (r.statusCode != 200) return [];
      final body = jsonDecode(r.body);
      final List lista = body['data']?['dados'] ?? body['data'] ?? [];
      return lista.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _loadParceiros() async {
    try {
      final token = AuthUtility.userInfo?.token;
      final empId = TenantContext.empresaId;
      final url = empId != null
          ? '${ApiLinks.baseUrl}/api/parceiro?empId=$empId'
          : '${ApiLinks.baseUrl}/api/parceiro';
      final r = await http.get(Uri.parse(url),
          headers: {if (token != null) 'Authorization': 'Bearer $token'});
      if (r.statusCode != 200) return [];
      final body = jsonDecode(r.body);
      final List lista = body['data']?['dados'] ?? body['data'] ?? [];
      return lista
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<Map<String, dynamic>> _statusOptions() => [
        {'id': 'ATIVO', 'nome': 'Ativo'},
        {'id': 'VENCIDO', 'nome': 'Vencido'},
        {'id': 'EM_RENOVACAO', 'nome': 'Em Renovação'},
        {'id': 'CANCELADO', 'nome': 'Cancelado'},
      ];

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<AlvaraModel>(
      telaNome: 'alvara',
      hasPermission: hasPermission,
      fromJson: (json) => AlvaraModel.fromJson(json),
      toJson: (a) => a.toJson(),

      fieldOverrides: [
        // ── Suprimir IDs de FK brutos ──────────────────────────────────────
        const FieldConfigWindows(
            fieldName: 'empresa_id',
            label: '',
            isInForm: false,
            isVisibleByDefault: false,
            enabled: false),
        const FieldConfigWindows(
            fieldName: 'parceiro_id',
            label: '',
            isInForm: false,
            isVisibleByDefault: false,
            enabled: false),
        const FieldConfigWindows(
            fieldName: 'file_id',
            label: '',
            isInForm: false,
            isVisibleByDefault: false,
            enabled: false),

        // ── Campos principais ─────────────────────────────────────────────
        const FieldConfigWindows(
          fieldName: 'descricao',
          label: 'Descrição',
          isInForm: true,
          isVisibleByDefault: true,
          enabled: true,
          isRequired: true,
        ),
        const FieldConfigWindows(
          fieldName: 'numero',
          label: 'Número',
          isInForm: true,
          isVisibleByDefault: true,
          enabled: true,
        ),
        const FieldConfigWindows(
          fieldName: 'dataEmissao',
          label: 'Data Emissão',
          fieldType: FieldType.date,
          isInForm: true,
          isVisibleByDefault: true,
          enabled: true,
        ),
        const FieldConfigWindows(
          fieldName: 'dataVencimento',
          label: 'Data Vencimento',
          fieldType: FieldType.date,
          isInForm: true,
          isVisibleByDefault: true,
          enabled: true,
          isFilterable: true,
        ),
        const FieldConfigWindows(
          fieldName: 'orgaoEmissor',
          label: 'Órgão Emissor',
          isInForm: true,
          isVisibleByDefault: true,
          enabled: true,
        ),
        // H6: tipoAlvara como dropdown com lista fixa
        FieldConfigWindows(
          fieldName: 'tipoAlvara',
          label: 'Tipo de Alvará',
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () async => const [
            {'id': 'Funcionamento', 'nome': 'Funcionamento'},
            {'id': 'Sanitário',     'nome': 'Sanitário'},
            {'id': 'Bombeiros',     'nome': 'Bombeiros'},
            {'id': 'Ambiental',     'nome': 'Ambiental'},
            {'id': 'Publicidade',   'nome': 'Publicidade'},
            {'id': 'Outros',        'nome': 'Outros'},
          ],
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          isInForm: true,
          isVisibleByDefault: true,
          isFilterable: true,
          enabled: true,
        ),

        // ── Status → dropdown ─────────────────────────────────────────────
        // No INSERT o status não deve ser editável (o backend define o valor
        // inicial); no EDIT o usuário pode alterar livremente.
        FieldConfigWindows(
          fieldName: 'status',
          label: 'Status',
          fieldType: FieldType.dropdown,
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownFutureBuilder: () async => _statusOptions(),
          isInForm: true,
          isVisibleByDefault: true,
          isFilterable: true,
          enabled: true,
          enabledOnInsert: false,
          enabledOnEdit: true,
        ),

        // ── Empresa → dropdown ────────────────────────────────────────────
        const FieldConfigWindows(
          fieldName: 'empresa',
          label: 'Empresa',
          displayFieldName: 'empresa.nomeFantasia',
          fieldType: FieldType.dropdown,
          dropdownValueField: 'id',
          dropdownDisplayField: 'nomeFantasia',
          dropdownFutureBuilder: _loadEmpresas,
          isInForm: true,
          isVisibleByDefault: false,
          isFilterable: true,
          enabled: true,
        ),

        // ── Parceiro/Cliente → dropdown ───────────────────────────────────
        const FieldConfigWindows(
          fieldName: 'parceiro',
          label: 'Parceiro/Cliente',
          displayFieldName: 'parceiro.nome',
          fieldType: FieldType.dropdown,
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownFutureBuilder: _loadParceiros,
          isInForm: true,
          isVisibleByDefault: true,
          isFilterable: true,
          enabled: true,
        ),

        // ── Observação ────────────────────────────────────────────────────
        const FieldConfigWindows(
          fieldName: 'observacao',
          label: 'Observação',
          fieldType: FieldType.multiline,
          isInForm: true,
          isVisibleByDefault: false,
          enabled: true,
        ),
      ],

      // ── Ações customizadas: Upload PDF, Visualizar PDF e GED ────────────
      customActions: () => [
        CustomAction<AlvaraModel>(
          icon: Icons.upload_file,
          label: 'Upload PDF',
          onPressed: (ctx, item) => _uploadPdf(ctx, item),
        ),
        CustomAction<AlvaraModel>(
          icon: Icons.picture_as_pdf,
          label: 'Ver PDF',
          isVisible: (item) => item.temPdf,
          onPressed: (ctx, item) => _visualizarPdf(ctx, item),
        ),
        // H5-21: navegar para o GED filtrado por este alvará
        CustomAction<AlvaraModel>(
          icon: Icons.folder_open,
          label: 'Ver GED',
          isVisible: (item) => item.id != null,
          onPressed: (ctx, item) {
            Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => GedArquivosScreen(
                moduloOrigem: 'alvara',
                idOrigem: item.id,
                nomeOrigem: item.descricao,
              ),
            ));
          },
        ),
      ],
    );
  }

  // ── Upload PDF do alvará ──────────────────────────────────────────────────
  static Future<void> _uploadPdf(BuildContext context, AlvaraModel item) async {
    if (item.id == null) {
      _snack(context, 'Salve o alvará antes de anexar o PDF.', Colors.orange);
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final arquivo = result.files.first;
    final bytes = arquivo.bytes ?? Uint8List(0);
    if (bytes.isEmpty) {
      if (!context.mounted) return;                     // guard após await
      _snack(context, 'Arquivo vazio.', Colors.red);
      return;
    }

    try {
      final token = AuthUtility.userInfo?.token;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiLinks.baseUrl}/api/alvara/${item.id}/upload'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: arquivo.name,
      ));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (!context.mounted) return;                     // guard após await
      if (resp.statusCode == 200) {
        _snack(context, 'PDF enviado com sucesso!', Colors.green);
      } else {
        _snack(context, 'Erro ao enviar PDF (${resp.statusCode}).', Colors.red);
      }
    } catch (e) {
      if (!context.mounted) return;                     // guard no catch
      _snack(context, 'Erro: $e', Colors.red);
    }
  }

  // ── Visualizar PDF do alvará ──────────────────────────────────────────────
  static void _visualizarPdf(BuildContext context, AlvaraModel item) {
    if (item.id == null || !item.temPdf) {
      _snack(context, 'Nenhum PDF anexado a este alvará.', Colors.orange);
      return;
    }
    final url = '${ApiLinks.baseUrl}/api/alvara/${item.id}/pdf';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('PDF — ${item.descricao}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context))
              ],
            ),
            // Mostra URL para abrir em aba nova (web) ou abre via flutter_pdfview
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.picture_as_pdf,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  SelectableText(url,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir PDF'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.primary),
                    onPressed: () async {
                      await _abrirUrl(url);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _abrirUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Não foi possível abrir URL: $url');
      }
    } catch (e) {
      debugPrint('Erro ao abrir URL: $e');
    }
  }

  static void _snack(BuildContext context, String msg, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alias para Windows (mesmo widget, mantém convenção de nome dos outros screens)
// ─────────────────────────────────────────────────────────────────────────────
class WindowsAlvaraGridScreen extends WebAlvaraGridScreen {
  const WindowsAlvaraGridScreen({super.key, required super.hasPermission});
}
