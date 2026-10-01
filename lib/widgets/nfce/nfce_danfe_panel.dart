import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/nfce/nfce_resultado_model.dart';
import '../../services/nfce_service.dart';

/// Widget compartilhado para exibir QR Code, download e impressão do DANFE NFC-e.
///
/// - Web/Desktop: imprime e salva o PDF.
/// - Mobile: imprime e compartilha o PDF.
/// - QR Code: prioriza o PNG gerado pelo backend (ZXing) e faz fallback
///   para renderização local quando a URL do QR já veio no resultado.
class NfceDanfeWidget extends StatefulWidget {
  final NfceResultadoModel resultado;

  const NfceDanfeWidget({super.key, required this.resultado});

  @override
  State<NfceDanfeWidget> createState() => _NfceDanfeWidgetState();
}

class _NfceDanfeWidgetState extends State<NfceDanfeWidget> {
  final NfceService _service = NfceService();
  bool _baixandoDanfe = false;
  bool _baixandoXml = false;
  String? _erro;

  bool get _usaSalvarArquivo {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  Future<Uint8List?> _obterDanfe() async {
    if (mounted) {
      setState(() {
        _baixandoDanfe = true;
        _erro = null;
      });
    }

    try {
      return await _service.baixarDanfe(widget.resultado.id);
    } on NfceException catch (e) {
      if (mounted) setState(() => _erro = e.message);
      return null;
    } catch (e) {
      if (mounted) setState(() => _erro = 'Erro ao baixar DANFE: $e');
      return null;
    } finally {
      if (mounted) setState(() => _baixandoDanfe = false);
    }
  }

  Future<void> _imprimirDanfe(BuildContext context) async {
    final bytes = await _obterDanfe();
    if (bytes == null || !context.mounted) return;

    try {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'danfe_nfce_${widget.resultado.id}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impressão não disponível nesta plataforma: $e')),
      );
    }
  }

  Future<void> _baixarDanfe(BuildContext context) async {
    final bytes = await _obterDanfe();
    if (bytes == null || !context.mounted) return;

    try {
      await FileSaver.instance.saveFile(
        name: 'danfe_nfce_${widget.resultado.id}',
        bytes: bytes,
        fileExtension: 'pdf',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DANFE salvo com sucesso.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar PDF: $e')),
      );
    }
  }

  Future<void> _compartilharDanfe(BuildContext context) async {
    final bytes = await _obterDanfe();
    if (bytes == null || !context.mounted) return;

    final nomeArquivo = 'danfe_nfce_${widget.resultado.id}.pdf';

    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: nomeArquivo,
          ),
        ],
        subject: 'DANFE NFC-e ${widget.resultado.chaveAcessoFormatada}',
        fileNameOverrides: [nomeArquivo],
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao compartilhar PDF: $e')),
      );
    }
  }

  Future<void> _executarAcaoSecundaria(BuildContext context) async {
    if (_usaSalvarArquivo) {
      await _baixarDanfe(context);
      return;
    }
    await _compartilharDanfe(context);
  }

  Future<void> _baixarXml(BuildContext context) async {
    if (mounted) {
      setState(() {
        _baixandoXml = true;
        _erro = null;
      });
    }

    try {
      final bytes = await _service.baixarXml(widget.resultado.id);
      if (!context.mounted) return;
      await FileSaver.instance.saveFile(
        name: 'xml_nfce_${widget.resultado.id}',
        bytes: bytes,
        fileExtension: 'xml',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('XML autorizado salvo com sucesso.')),
      );
    } on NfceException catch (e) {
      if (mounted) setState(() => _erro = e.message);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      final mensagem = 'Erro ao baixar XML: $e';
      if (mounted) setState(() => _erro = mensagem);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } finally {
      if (mounted) setState(() => _baixandoXml = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultado = widget.resultado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _QrCodeSection(resultado: resultado),
        const SizedBox(height: 16),
        SelectableText(
          resultado.chaveAcessoFormatada,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (resultado.protocolo.isNotEmpty)
          Text(
            'Protocolo: ${resultado.protocolo}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        if (resultado.dataAutorizacao != null)
          Text(
            'Autorizado em: ${_formatarData(resultado.dataAutorizacao!)}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        if (_erro != null) ...[
          const SizedBox(height: 8),
          Text(
            _erro!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        if (_baixandoDanfe || _baixandoXml)
          const CircularProgressIndicator()
        else
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Imprimir DANFE'),
                onPressed: () => _imprimirDanfe(context),
              ),
              OutlinedButton.icon(
                icon: Icon(_usaSalvarArquivo ? Icons.download : Icons.share),
                label: Text(_usaSalvarArquivo ? 'Baixar PDF' : 'Compartilhar PDF'),
                onPressed: () => _executarAcaoSecundaria(context),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.code),
                label: const Text('Baixar XML'),
                onPressed: () => _baixarXml(context),
              ),
            ],
          ),
      ],
    );
  }

  String _formatarData(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _QrCodeSection extends StatefulWidget {
  final NfceResultadoModel resultado;

  const _QrCodeSection({required this.resultado});

  @override
  State<_QrCodeSection> createState() => _QrCodeSectionState();
}

class _QrCodeSectionState extends State<_QrCodeSection> {
  final NfceService _service = NfceService();
  late final Future<Uint8List?> _qrCodeFuture = _carregarQrCode();

  Future<Uint8List?> _carregarQrCode() async {
    if (widget.resultado.id <= 0) return null;
    try {
      return await _service.baixarQrCodePng(widget.resultado.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrCodeData = widget.resultado.qrCodeUrl?.trim();
    final temQrLocal = qrCodeData != null && qrCodeData.isNotEmpty;

    return FutureBuilder<Uint8List?>(
      future: _qrCodeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return Image.memory(
            snapshot.data!,
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _fallbackQrCode(qrCodeData),
          );
        }

        if (temQrLocal) {
          return QrImageView(
            data: qrCodeData,
            version: QrVersions.auto,
            size: 180,
            backgroundColor: Colors.white,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 180,
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _fallbackQrCode(qrCodeData);
      },
    );
  }

  Widget _fallbackQrCode(String? qrCodeData) {
    if (qrCodeData != null && qrCodeData.isNotEmpty) {
      return QrImageView(
        data: qrCodeData,
        version: QrVersions.auto,
        size: 180,
        backgroundColor: Colors.white,
      );
    }

    return Container(
      width: 180,
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.qr_code, size: 96, color: Colors.black54),
    );
  }
}
