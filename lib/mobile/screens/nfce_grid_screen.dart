import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../customization/generic_grid/grid_models.dart' show CustomAction;
import '../../models/nfce_model.dart';
import '../../services/nfce_service.dart';
import '../../services/print_service_nfce.dart';
import '../../utils/api_links.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/tenant_context.dart';
import '../../web/screens/nfce/pdv_screen.dart';

class MobileNfceGridScreen extends StatefulWidget {
  final SecurityCheck? hasPermission;

  const MobileNfceGridScreen({super.key, this.hasPermission});

  @override
  State<MobileNfceGridScreen> createState() => _MobileNfceGridScreenState();
}

class _MobileNfceGridScreenState extends State<MobileNfceGridScreen> {
  @override
  Widget build(BuildContext context) {
    final effectiveHasPerm = widget.hasPermission ?? (p) => true;

    return Scaffold(
      body: DynamicGridDynamicScreen(
        telaNome: 'nfce',
        hasPermission: effectiveHasPerm,
        storageKey: 'mobile_dynamic_nfce',
        showAppBar: true,
        useUserBannerAppBar: true,
        createEndpointOverride: '', // Evita FAB generico do grid mobile
        tituloOverride: 'NFC-e / Cupons',
        fetchEndpointOverride: '${ApiLinks.baseUrl}/api/v1/nfce',
        customActions: () => _buildCustomActions(context),
      ),
      floatingActionButton: effectiveHasPerm('inserir')
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PdvScreen()),
              ),
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Nova NFC-e'),
            )
          : null,
    );
  }

  List<CustomAction> _buildCustomActions(BuildContext context) {
    return [
      CustomAction(
        label: 'Consultar status',
        icon: Icons.manage_search,
        onPressed: (ctx, item) => _consultarStatus(ctx, NfceModel.fromJson(item)),
      ),
      CustomAction(
        label: 'Cancelar',
        icon: Icons.cancel,
        onPressed: (ctx, item) {
          final nfce = NfceModel.fromJson(item);
          final s = nfce.statusSefaz.toUpperCase();
          if (s != 'AUTORIZADA') {
            AppSnackbar.error(
              ctx,
              'Apenas NFC-e com status AUTORIZADA pode ser cancelada (status atual: $s).',
            );
            return;
          }
          _cancelar(ctx, nfce);
        },
      ),
      CustomAction(
        label: 'Contingência / EPEC',
        icon: Icons.podcasts,
        onPressed: (ctx, item) {
          final nfce = NfceModel.fromJson(item);
          final s = nfce.statusSefaz.toUpperCase();
          if (s != 'CONTINGENCIA') {
            AppSnackbar.error(
              ctx,
              'Esta NFC-e não está em contingência offline (status atual: $s).',
            );
            return;
          }
          _reenviarContingencia(ctx, nfce);
        },
      ),
      CustomAction(
        label: 'Inutilizar numeração',
        icon: Icons.block,
        onPressed: (ctx, item) => _inutilizar(ctx, NfceModel.fromJson(item)),
      ),
      CustomAction(
        label: 'Gerar PDF',
        icon: Icons.picture_as_pdf,
        onPressed: (ctx, item) {
          final nfce = NfceModel.fromJson(item);
          final s = nfce.statusSefaz.toUpperCase();
          if (!['AUTORIZADA', 'CONTINGENCIA'].contains(s) &&
              (nfce.numero == null || nfce.numero! <= 0)) {
            AppSnackbar.error(
              ctx,
              'Apenas NFC-e com status AUTORIZADA ou CONTINGÊNCIA possui Cupom/DANFE para emissão.',
            );
            return;
          }
          _gerarPdf(ctx, nfce);
        },
      ),
      CustomAction(
        label: 'Baixar XML',
        icon: Icons.code,
        onPressed: (ctx, item) {
          final nfce = NfceModel.fromJson(item);
          final s = nfce.statusSefaz.toUpperCase();
          if (!['AUTORIZADA', 'CANCELADA', 'CONTINGENCIA'].contains(s) &&
              !nfce.xmlAutorizadoDisponivel) {
            AppSnackbar.error(
              ctx,
              'XML autorizado não está disponível para esta NFC-e (status atual: $s).',
            );
            return;
          }
          _baixarXml(ctx, nfce);
        },
      ),
      CustomAction(
        label: 'Enviar e-mail',
        icon: Icons.email,
        onPressed: (ctx, item) {
          final nfce = NfceModel.fromJson(item);
          final s = nfce.statusSefaz.toUpperCase();
          if (s != 'AUTORIZADA') {
            AppSnackbar.error(
              ctx,
              'Apenas NFC-e com status AUTORIZADA pode ser enviada por e-mail (status atual: $s).',
            );
            return;
          }
          _enviarEmail(ctx, nfce);
        },
      ),
    ];
  }

  static Future<void> _consultarStatus(
    BuildContext context,
    NfceModel nfce,
  ) async {
    try {
      final status = await NfceService().consultarStatus(nfce.id);
      if (!context.mounted) return;
      _showDataDialog(context, 'Status NFC-e', {
        'id': status.id,
        'status': status.status,
        'mensagem': status.mensagem ?? '-',
        'protocolo': status.protocolo ?? '-',
        'codigoRetorno': status.codigoRetorno ?? '-',
        'motivoRejeicao': status.motivoRejeicao ?? '-',
      });
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao consultar status: $e');
      }
    }
  }

  Future<void> _cancelar(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    final justificativa = await _promptText(
      context,
      title: 'Cancelar NFC-e #',
      label: 'Justificativa',
      hint: 'Mínimo 15 caracteres',
      initialValue: 'Cancelamento solicitado pela listagem',
      minLength: 15,
    );
    if (justificativa == null) return;
    try {
      await NfceService().cancelarNfce(
        nfce.id,
        justificativa,
        empresaId: TenantContext.empresaId ?? 0,
      );
      if (context.mounted) {
        AppSnackbar.success(context, 'NFC-e cancelada com sucesso.');
      }
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao cancelar: $e');
    }
  }

  Future<void> _reenviarContingencia(
    BuildContext context,
    NfceModel nfce,
  ) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    try {
      await NfceService().reenviarContingencia(nfce.id);
      if (context.mounted) {
        AppSnackbar.success(context, 'NFC-e enviada em contingência.');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao enviar contingência: $e');
      }
    }
  }

  Future<void> _inutilizar(BuildContext context, NfceModel nfce) async {
    if (nfce.numero == null || nfce.serie == null) {
      AppSnackbar.error(context, 'NFC-e sem número ou série.');
      return;
    }
    final justificativa = await _promptText(
      context,
      title: 'Inutilizar numeração',
      label: 'Justificativa',
      hint: 'Explique o motivo da inutilização (mínimo 15 caracteres)',
      minLength: 15,
    );
    if (justificativa == null) return;
    try {
      await NfceService().inutilizar(
        empresaId: TenantContext.empresaId ?? 0,
        uf: nfce.uf ?? 'MG',
        ambiente: nfce.ambiente ?? 'HOMOLOGACAO',
        serie: nfce.serie!,
        numeroInicio: nfce.numero!,
        numeroFim: nfce.numero!,
        justificativa: justificativa,
      );
      if (context.mounted) {
        AppSnackbar.success(context, 'Numeração inutilizada com sucesso.');
      }
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao inutilizar: $e');
    }
  }

  static Future<void> _gerarPdf(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    try {
      await PrintServiceNfce().imprimirDanfe(context, nfce.id);
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao gerar PDF: $e');
    }
  }

  static Future<void> _baixarXml(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    try {
      final xml = await NfceService().baixarXml(nfce.id);
      await FileSaver.instance.saveFile(
        name: 'nfce_${nfce.id}',
        bytes: xml,
        fileExtension: 'xml',
      );
      if (context.mounted) AppSnackbar.success(context, 'XML baixado.');
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao baixar XML: $e');
    }
  }

  static Future<void> _enviarEmail(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    final email = await _promptText(
      context,
      title: 'Enviar NFC-e por e-mail',
      label: 'E-mail',
      hint: 'destinatario@empresa.com',
      minLength: 5,
    );
    if (email == null) return;
    try {
      await NfceService().enviarEmail(nfce.id, email);
      if (context.mounted) {
        AppSnackbar.success(context, 'E-mail enviado com sucesso.');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao enviar e-mail: $e');
      }
    }
  }

  static Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String label,
    String? hint,
    String? initialValue,
    int minLength = 15,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: label == 'E-mail' ? 1 : 3,
          keyboardType: label == 'E-mail'
              ? TextInputType.emailAddress
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (value == null) return null;
    if (value.length < minLength) {
      if (context.mounted) {
        AppSnackbar.error(
          context,
          '$label deve ter pelo menos $minLength caracteres.',
        );
      }
      return null;
    }
    return value;
  }

  static void _showDataDialog(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('${e.key}: ${e.value}'),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
