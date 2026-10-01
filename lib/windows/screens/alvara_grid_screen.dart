import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
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
class WindowsAlvaraGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsAlvaraGridScreen({super.key, required this.hasPermission});

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
        {'id': 'ATIVO', 'nome': GridTexts.active},
        {'id': 'VENCIDO', 'nome': GridTexts.expired},
        {'id': 'EM_RENOVACAO', 'nome': GridTexts.renewing},
        {'id': 'CANCELADO', 'nome': GridTexts.cancelled},
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
          label: GridTexts.description,
          isInForm: true,
          isVisibleByDefault: true,
          enabled: true,
          isRequired: true,
        ),
        const FieldConfigWindows(
          fieldName: 'numero',
          label: GridTexts.number,
          isInForm: true,
          isVisibleByDefault: true,
          enabled: true,
        ),
        const FieldConfigWindows(
          fieldName: 'dataEmissao',
          label: GridTexts.issueDate,
          fieldType: FieldType.date,
          isInForm: true,
          isVisibleByDefault: true,
          enabled: true,
        ),
        const FieldConfigWindows(
          fieldName: 'dataVencimento',
          label: GridTexts.dueDate,
          fieldType: FieldType.date,
          isInForm: true,
          isVisibleByDefault: true,
          enabled: true,
          isFilterable: true,
        ),
        const FieldConfigWindows(
          fieldName: 'orgaoEmissor',
          label: GridTexts.issuingAgency,
          isInForm: true,
          isVisibleByDefault: true,
          enabled: true,
        ),
        // H6: tipoAlvara como dropdown com lista fixa
        FieldConfigWindows(
          fieldName: 'tipoAlvara',
          label: GridTexts.licenseType,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () async => const [
            {'id': 'Funcionamento', 'nome': GridTexts.businessLicense},
            {'id': 'Sanitário',     'nome': GridTexts.healthLicense},
            {'id': 'Bombeiros',     'nome': GridTexts.fireDepartment},
            {'id': 'Ambiental',     'nome': GridTexts.environmental},
            {'id': 'Publicidade',   'nome': GridTexts.advertising},
            {'id': 'Outros',        'nome': GridTexts.others},
          ],
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          isInForm: true,
          isVisibleByDefault: true,
          isFilterable: true,
          enabled: true,
        ),

        // ── Status → dropdown ─────────────────────────────────────────────
        FieldConfigWindows(
          fieldName: 'status',
          label: GridTexts.status,
          fieldType: FieldType.dropdown,
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownFutureBuilder: () async => _statusOptions(),
          isInForm: true,
          isVisibleByDefault: true,
          isFilterable: true,
          enabled: true,
        ),

        // ── Empresa → dropdown ────────────────────────────────────────────
        const FieldConfigWindows(
          fieldName: 'empresa',
          label: GridTexts.company,
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
          label: GridTexts.partnerCustomer,
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
          label: GridTexts.notes,
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
          label: GridTexts.uploadPdf,
          onPressed: (ctx, item) => _uploadPdf(ctx, item),
        ),
        CustomAction<AlvaraModel>(
          icon: Icons.picture_as_pdf,
          label: GridTexts.viewPdf,
          isVisible: (item) => item.temPdf,
          onPressed: (ctx, item) => _visualizarPdf(ctx, item),
        ),
        // H5-21: navegar para o GED filtrado por este alvará
        CustomAction<AlvaraModel>(
          icon: Icons.folder_open,
          label: GridTexts.viewGed,
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
      _snack(context, GridTexts.saveLicenseBeforePdf, GridColors.warning);
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
      _snack(context, GridTexts.emptyFile, GridColors.error);
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
        _snack(context, GridTexts.pdfUploadSuccess, GridColors.success);
      } else {
        _snack(context, GridTexts.pdfUploadError(resp.statusCode), GridColors.error);
      }
    } catch (e) {
      if (!context.mounted) return;                     // guard no catch
      _snack(context, GridTexts.genericError(e.toString()), GridColors.error);
    }
  }

  // ── Visualizar PDF do alvará ──────────────────────────────────────────────
  static void _visualizarPdf(BuildContext context, AlvaraModel item) {
    if (item.id == null || !item.temPdf) {
      _snack(context, GridTexts.noLicensePdfAttached, GridColors.warning);
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
              title: Text(GridTexts.licensePdfTitle(item.descricao)),
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
                      size: 64, color: GridColors.error),
                  const SizedBox(height: 12),
                  SelectableText(url,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text(GridTexts.openPdf),
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
