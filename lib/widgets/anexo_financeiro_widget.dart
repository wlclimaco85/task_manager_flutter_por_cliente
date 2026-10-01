import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../models/anexo_financeiro_model.dart';
import '../services/anexo_financeiro_service.dart';
import '../utils/grid_colors.dart';

/// Dialog/bottom sheet de Comprovantes para Contas a Pagar/Receber.
///
/// Uso:
/// ```dart
/// AnexoFinanceiroWidget(
///   lancamentoId: conta.id!,
///   lancamentoTipo: 'PAGAR', // ou 'RECEBER'
/// )
/// ```
class AnexoFinanceiroWidget extends StatefulWidget {
  final int lancamentoId;
  final String lancamentoTipo; // "PAGAR" ou "RECEBER"

  /// Empresa dona do lancamento. Obrigatorio na pratica para usuarios MASTER
  /// (TenantContext deles nunca tem empresaId — ver TenantContextPopulator no
  /// backend), sem isso o backend nao sabe de qual empresa sao os anexos e
  /// retorna 500. Passe sempre que souber (ex.: conta.empresa.id).
  final int? empresaId;

  /// Fix (card #468): callback opcional, disparado após upload confirmado
  /// com o nome do arquivo. Usado por telas que precisam refletir o anexo
  /// em algo além da lista de comprovantes (ex.: chamado_detalhe_screen.dart
  /// registra o evento na timeline "Histórico e comentários", que antes
  /// nunca sabia que um anexo tinha sido adicionado).
  final void Function(String nomeArquivo)? onAnexoSalvo;

  const AnexoFinanceiroWidget({
    super.key,
    required this.lancamentoId,
    required this.lancamentoTipo,
    this.empresaId,
    this.onAnexoSalvo,
  });

  @override
  State<AnexoFinanceiroWidget> createState() => _AnexoFinanceiroWidgetState();
}

class _AnexoFinanceiroWidgetState extends State<AnexoFinanceiroWidget> {
  final _service = AnexoFinanceiroService();

  List<AnexoFinanceiro> _anexos = [];
  bool _carregando = false;
  bool _enviando = false;
  String? _erro;

  // Arquivo selecionado aguardando confirmação
  PlatformFile? _arquivoPendente;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ── Dados ───────────────────────────────────────────────────────────────────

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      _anexos = await _service.listar(
          widget.lancamentoId, widget.lancamentoTipo, empresaId: widget.empresaId);
    } catch (e) {
      _erro = e.toString();
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'xml'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _arquivoPendente = result.files.first);
  }

  Future<void> _confirmarUpload() async {
    if (_arquivoPendente == null) return;
    final arquivo = _arquivoPendente!;
    setState(() {
      _enviando = true;
      _arquivoPendente = null;
      _erro = null;
    });
    try {
      final novo = await _service.upload(
          widget.lancamentoId, widget.lancamentoTipo, arquivo, empresaId: widget.empresaId);
      setState(() => _anexos.add(novo));
      _snackbar('Comprovante anexado com sucesso', sucesso: true);
      widget.onAnexoSalvo?.call(arquivo.name);
    } catch (e) {
      setState(() => _erro = e.toString());
      _snackbar('Erro ao enviar: $e', sucesso: false);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _baixar(AnexoFinanceiro anexo) async {
    if (anexo.id == null) return;
    setState(() => _carregando = true);
    try {
      final bytes = await _service.download(anexo.id!, empresaId: widget.empresaId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${anexo.fileName}');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Mobile: gravar so em pasta temporaria e inutil, o usuario nao
        // acessa esse diretorio. Abre o menu nativo de compartilhar/salvar
        // (mesmo padrao ja usado em outros fluxos de download do app).
        await Share.shareXFiles([XFile(file.path)]);
      } else {
        _snackbar('Salvo em ${file.path}', sucesso: true);
      }
    } catch (e) {
      if (mounted) _snackbar('Erro ao baixar: $e', sucesso: false);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _remover(AnexoFinanceiro anexo) async {
    if (anexo.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover comprovante'),
        content: Text('Deseja remover "${anexo.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: GridColors.error),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _carregando = true);
    try {
      await _service.remover(anexo.id!, empresaId: widget.empresaId);
      setState(() => _anexos.removeWhere((a) => a.id == anexo.id));
      _snackbar('Comprovante removido', sucesso: true);
    } catch (e) {
      if (mounted) _snackbar('Erro ao remover: $e', sucesso: false);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _snackbar(String mensagem, {required bool sucesso}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: sucesso ? GridColors.success : GridColors.error,
        content: Text(mensagem, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_erro != null) _buildBannerErro(),
                  if (_enviando) _buildProgressoUpload(),
                  if (_arquivoPendente != null) _buildPreviewArquivo(),
                  const SizedBox(height: 12),
                  _buildCorpoLista(),
                  const SizedBox(height: 16),
                  _buildBotaoUpload(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: GridColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long,
                color: GridColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comprovantes',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Anexe arquivos PDF, imagens ou XML',
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Color(0xFF757575)),
            tooltip: 'Fechar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerErro() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GridColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: GridColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _erro!,
              style:
                  const TextStyle(color: GridColors.error, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: GridColors.error),
            onPressed: () => setState(() => _erro = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressoUpload() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1976D2),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Enviando comprovante...',
            style: TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArquivo() {
    final arquivo = _arquivoPendente!;
    final icone = _iconeArquivo(arquivo.name);
    final tamanhoFormatado = arquivo.size < 1024 * 1024
        ? '${(arquivo.size / 1024).toStringAsFixed(1)} KB'
        : '${(arquivo.size / (1024 * 1024)).toStringAsFixed(1)} MB';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GridColors.secondarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GridColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arquivo selecionado — confirmar envio?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: GridColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icone.icon, color: icone.color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arquivo.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tamanhoFormatado,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _arquivoPendente = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF757575),
                    side:
                        const BorderSide(color: Color(0xFFBBBBBB)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmarUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Confirmar envio'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCorpoLista() {
    if (_carregando && _anexos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: GridColors.primary),
        ),
      );
    }

    if (_anexos.isEmpty) {
      return _buildEstadoVazio();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${_anexos.length} ${_anexos.length == 1 ? 'comprovante' : 'comprovantes'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF757575),
            ),
          ),
        ),
        ..._anexos.map((a) => _AnexoCard(
              anexo: a,
              onDownload: () => _baixar(a),
              onRemove: () => _remover(a),
              carregando: _carregando,
            )),
      ],
    );
  }

  Widget _buildEstadoVazio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Color(0xFFBBBBBB),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum comprovante anexado',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Anexe PDFs, imagens ou XMLs\npara documentar este lançamento.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoUpload() {
    return ElevatedButton.icon(
      onPressed: (_enviando || _carregando || _arquivoPendente != null)
          ? null
          : _selecionarArquivo,
      icon: const Icon(Icons.upload_file, size: 20),
      label: const Text(
        'Anexar comprovante',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: GridColors.disabledBackground,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  ({IconData icon, Color color}) _iconeArquivo(String nomeArquivo) {
    final ext = nomeArquivo.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf'  => (icon: Icons.picture_as_pdf, color: const Color(0xFFE53935)),
      'jpg'  => (icon: Icons.image, color: const Color(0xFF1976D2)),
      'jpeg' => (icon: Icons.image, color: const Color(0xFF1976D2)),
      'png'  => (icon: Icons.image, color: const Color(0xFF1976D2)),
      'xml'  => (icon: Icons.code, color: const Color(0xFF388E3C)),
      _      => (icon: Icons.attach_file, color: const Color(0xFF757575)),
    };
  }
}

// ── Card individual de anexo ──────────────────────────────────────────────────

class _AnexoCard extends StatelessWidget {
  final AnexoFinanceiro anexo;
  final VoidCallback onDownload;
  final VoidCallback onRemove;
  final bool carregando;

  const _AnexoCard({
    required this.anexo,
    required this.onDownload,
    required this.onRemove,
    required this.carregando,
  });

  @override
  Widget build(BuildContext context) {
    final nomeArquivo = anexo.fileName;
    final ext = nomeArquivo.split('.').last.toLowerCase();

    final (IconData icone, Color corIcone) = switch (ext) {
      'pdf'  => (Icons.picture_as_pdf, const Color(0xFFE53935)),
      'jpg'  => (Icons.image, const Color(0xFF1976D2)),
      'jpeg' => (Icons.image, const Color(0xFF1976D2)),
      'png'  => (Icons.image, const Color(0xFF1976D2)),
      'xml'  => (Icons.code, const Color(0xFF388E3C)),
      _      => (Icons.attach_file, const Color(0xFF757575)),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icone, color: corIcone, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeArquivo,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (anexo.tamanhoBytes != null)
                    Text(
                      anexo.tamanhoFormatado,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E)),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BotaoAcaoAnexo(
                  icone: Icons.download_outlined,
                  cor: GridColors.info,
                  tooltip: 'Baixar',
                  onPressed: carregando ? null : onDownload,
                ),
                const SizedBox(width: 4),
                _BotaoAcaoAnexo(
                  icone: Icons.delete_outline,
                  cor: GridColors.error,
                  tooltip: 'Remover',
                  onPressed: carregando ? null : onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoAcaoAnexo extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String tooltip;
  final VoidCallback? onPressed;

  const _BotaoAcaoAnexo({
    required this.icone,
    required this.cor,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icone,
            size: 20,
            color: onPressed != null ? cor : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
