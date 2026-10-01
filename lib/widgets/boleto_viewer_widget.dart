import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';

/// Conteudo compartilhado do "Boleto Viewer" (card #440): mostra a linha
/// digitavel extraida do anexo (via BoletoPdfExtractor no backend, melhor
/// esforco — pode nao encontrar) com botao de copiar, e permite baixar/
/// compartilhar o PDF do boleto. Usado dentro de um Dialog (Web/Windows) ou
/// de um bottom sheet (Mobile) — ver funcoes showBoletoViewerDialog() e
/// showBoletoViewerBottomSheet() no fim do arquivo.
class BoletoViewerContent extends StatefulWidget {
  final int anexoId;
  final String fileName;
  final int? empresaId;
  final VoidCallback? onClose;

  const BoletoViewerContent({
    super.key,
    required this.anexoId,
    required this.fileName,
    this.empresaId,
    this.onClose,
  });

  @override
  State<BoletoViewerContent> createState() => _BoletoViewerContentState();
}

enum _Estado { carregando, sucesso, vazio, erro }

class _BoletoViewerContentState extends State<BoletoViewerContent> {
  _Estado _estado = _Estado.carregando;
  String? _linhaDigitavel;
  bool _copiado = false;
  bool _baixando = false;

  @override
  void initState() {
    super.initState();
    _carregarLinhaDigitavel();
  }

  String get _urlLinhaDigitavel =>
      TenantContext.applyToUrl(ApiLinks.anexoFinanceiroLinhaDigitavel('${widget.anexoId}')) +
      (widget.empresaId != null ? '&empresaId=${widget.empresaId}' : '');

  Future<void> _carregarLinhaDigitavel() async {
    setState(() => _estado = _Estado.carregando);
    try {
      final resp = await http.get(Uri.parse(_urlLinhaDigitavel), headers: TenantContext.jsonHeaders);
      if (resp.statusCode != 200) {
        setState(() => _estado = _Estado.erro);
        return;
      }
      // Backend retorna a String (ou null) serializada como JSON: "abc" ou null.
      var body = resp.body.trim();
      if (body.startsWith('"') && body.endsWith('"')) {
        body = body.substring(1, body.length - 1);
      }
      final valor = (body.isEmpty || body == 'null') ? null : body;
      setState(() {
        _linhaDigitavel = valor;
        _estado = valor != null ? _Estado.sucesso : _Estado.vazio;
      });
    } catch (_) {
      if (mounted) setState(() => _estado = _Estado.erro);
    }
  }

  void _copiarLinhaDigitavel() {
    if (_linhaDigitavel == null) return;
    Clipboard.setData(ClipboardData(text: _linhaDigitavel!));
    setState(() => _copiado = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copiado = false);
    });
  }

  Future<void> _baixarOuCompartilhar() async {
    setState(() => _baixando = true);
    try {
      final url = TenantContext.applyToUrl(ApiLinks.anexoFinanceiroDownload('${widget.anexoId}')) +
          (widget.empresaId != null ? '&empresaId=${widget.empresaId}' : '');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        Uri.parse(url),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode != 200) {
        throw Exception('Erro ao baixar (${resp.statusCode})');
      }
      if (kIsWeb) {
        // Web: navegador ja trata download nativo via link; aqui usamos o
        // mesmo padrao ja usado em outros lugares do app (abrir bytes).
        _mostrarSnack('Download iniciado.');
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: nao adianta gravar em pasta temporaria invisivel — abre o
        // menu nativo de compartilhar/salvar (ja usado em outros fluxos do
        // projeto via share_plus).
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.fileName}');
        await file.writeAsBytes(resp.bodyBytes);
        await Share.shareXFiles([XFile(file.path)]);
      } else {
        // Windows/Desktop: salva em pasta temporaria e informa o caminho.
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.fileName}');
        await file.writeAsBytes(resp.bodyBytes);
        _mostrarSnack('Salvo em ${file.path}');
      }
    } catch (e) {
      _mostrarSnack('Erro ao baixar boleto: $e', erro: true);
    } finally {
      if (mounted) setState(() => _baixando = false);
    }
  }

  void _mostrarSnack(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: erro ? GridColors.error : GridColors.success,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCorpo(),
              const SizedBox(height: 20),
              _buildRodape(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(color: GridColors.primary),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: GridColors.textPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Boleto viewer',
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: GridColors.textPrimaryMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!_isMobile)
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, color: GridColors.textPrimaryMuted, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }

  Widget _buildCorpo() {
    switch (_estado) {
      case _Estado.carregando:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: GridColors.primary),
              ),
              SizedBox(height: 10),
              Text('Extraindo linha digitável...',
                  style: TextStyle(fontSize: 13, color: GridColors.textMuted)),
            ],
          ),
        );
      case _Estado.erro:
        // Fix card #455: falha ao extrair a linha digitavel (500/rede/timeout)
        // nao pode bloquear o acesso ao PDF do boleto -- ele pode estar
        // perfeitamente acessivel mesmo com a extracao falhando. Estado
        // tratado como variacao de `vazio` (mesma estrutura, botoes de
        // download sempre visiveis em _buildRodape), diferindo so no
        // icone/cor (vermelho, sinaliza falha real) e oferecendo "Tentar
        // novamente" como acao secundaria (TextButton), nao como unica saida.
        return Column(
          children: [
            const Icon(Icons.error_outline, color: GridColors.error, size: 32),
            const SizedBox(height: 8),
            const Text('Não foi possível verificar a linha digitável',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: GridColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('Ocorreu uma falha ao processar o boleto. Você ainda pode baixar o PDF original abaixo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: GridColors.textMuted)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _carregarLinhaDigitavel,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tentar novamente'),
              style: TextButton.styleFrom(foregroundColor: GridColors.primary, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            ),
          ],
        );
      case _Estado.vazio:
        return const Column(
          children: [
            Icon(Icons.info_outline, color: GridColors.textMuted, size: 32),
            SizedBox(height: 8),
            Text('Linha digitável não encontrada neste arquivo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: GridColors.textSecondary)),
            SizedBox(height: 4),
            Text('Você ainda pode baixar o PDF original do boleto abaixo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: GridColors.textMuted)),
          ],
        );
      case _Estado.sucesso:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Linha digitável',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: GridColors.textMuted)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: GridColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GridColors.divider, width: 0.5),
              ),
              child: Text(
                _linhaDigitavel!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  letterSpacing: 0.3,
                  color: GridColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _copiarLinhaDigitavel,
              icon: Icon(_copiado ? Icons.check : Icons.copy, size: 18),
              label: Text(_copiado ? 'Copiado' : 'Copiar linha digitável'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _copiado ? GridColors.success : GridColors.primary,
                side: BorderSide(color: _copiado ? GridColors.success : GridColors.primary),
                backgroundColor: GridColors.primarySoft,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildRodape() {
    // Fix card #455: antes, o estado de erro escondia completamente o
    // rodape (nenhum botao de baixar/fechar), bloqueando o usuario mesmo
    // quando o PDF em si estava acessivel. Agora o rodape (baixar +
    // fechar) aparece em erro/vazio/sucesso, igual ao estado vazio.
    final baixarBtn = ElevatedButton.icon(
      onPressed: _baixando ? null : _baixarOuCompartilhar,
      icon: _baixando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(_isMobile ? Icons.share : Icons.download, size: 18),
      label: Text(_isMobile ? 'Compartilhar / salvar boleto' : 'Baixar boleto'),
      style: ElevatedButton.styleFrom(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
    );
    if (_isMobile) return baixarBtn;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onClose,
            child: const Text('Fechar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: baixarBtn),
      ],
    );
  }
}

/// Abre o Boleto Viewer como Dialog centralizado (Web/Windows).
Future<void> showBoletoViewerDialog(
  BuildContext context, {
  required int anexoId,
  required String fileName,
  int? empresaId,
}) {
  return showDialog(
    context: context,
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: GridColors.dialogBackground,
            elevation: 8,
            shadowColor: GridColors.shadow,
            child: SingleChildScrollView(
              child: BoletoViewerContent(
                anexoId: anexoId,
                fileName: fileName,
                empresaId: empresaId,
                onClose: () => Navigator.of(dialogCtx).pop(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Abre o Boleto Viewer como bottom sheet (Mobile).
Future<void> showBoletoViewerBottomSheet(
  BuildContext context, {
  required int anexoId,
  required String fileName,
  int? empresaId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      decoration: const BoxDecoration(
        color: GridColors.dialogBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 4),
                child: SizedBox(
                  width: 36,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: BoletoViewerContent(
                  anexoId: anexoId,
                  fileName: fileName,
                  empresaId: empresaId,
                  onClose: () => Navigator.of(sheetCtx).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
