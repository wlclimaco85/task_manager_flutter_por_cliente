import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/chamado_model.dart';
import '../models/empresa_model.dart';
import '../models/login_model.dart';
import '../models/setor_model.dart';
import '../models/auth_utility.dart';
import '../services/chamado_caller.dart';
import '../services/anexo_financeiro_service.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';
import '../utils/grid_colors.dart';
import '../utils/grid_texts.dart';

/// Popup "Abrir Chamado" para Web/Windows, disparado a partir do chat de
/// Atendimento (card #432). Mesma logica/campos do TicketFormBottomSheet
/// (mobile), em formato de Dialog em vez de bottom sheet.
///
/// Ao confirmar: cria o chamado (ChamadoCaller.createChamado, endpoint ja
/// existente e funcional /api/chamados) e, em seguida, baixa cada imagem
/// anexada no chat (anexosChat) e reenvia como anexo do chamado via
/// AnexoFinanceiroService.uploadBytes(tipo: 'CHAMADO') — reaproveitando o
/// mecanismo generico de anexos ja usado em Contas a Pagar/Receber (nao
/// exige tabela nova nem endpoint novo, pois 'tipo' e uma String livre).
class TicketFormDialog extends StatefulWidget {
  final String sectorDescricao;

  /// Historico do chat ja formatado como texto, usado para pre-preencher
  /// a descricao do chamado (editavel pelo usuario antes de enviar).
  final String initialDescricao;

  /// Imagens anexadas na conversa do chat: cada item precisa de
  /// 'fileId' (int) e 'fileName' (String) para poder buscar os bytes via
  /// ApiLinks.downloadArquivo e reenviar como anexo do chamado.
  final List<Map<String, dynamic>> anexosChat;

  const TicketFormDialog({
    super.key,
    required this.sectorDescricao,
    this.initialDescricao = '',
    this.anexosChat = const [],
  });

  @override
  State<TicketFormDialog> createState() => _TicketFormDialogState();
}

class _TicketFormDialogState extends State<TicketFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _descricao;

  // Chamado sempre abre com status ABERTO — nao exposto no form (card #432:
  // so mostrar campos que fazem sentido no contexto do chat).
  final String _status = 'ABERTO';
  String _prioridade = 'MEDIA';

  int? _setorId;

  bool _submitting = false;
  String? _progresso;
  List<Map<String, dynamic>> _setores = [];

  @override
  void initState() {
    super.initState();
    _titulo = TextEditingController();
    _descricao = TextEditingController(text: widget.initialDescricao);
    _carregarSetores();
  }

  Future<void> _carregarSetores() async {
    final itens = await Chamado.loadSetores();
    if (!mounted) return;
    setState(() {
      _setores = itens;
      final found = _setores.firstWhere(
        (e) => (e['label'] as String).toLowerCase().trim() ==
            widget.sectorDescricao.toLowerCase().trim(),
        orElse: () => {},
      );
      if (found.isNotEmpty) {
        _setorId = found['value'] as int;
      }
    });
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _setorId == null) return;
    setState(() {
      _submitting = true;
      _progresso = null;
    });
    try {
      final token = AuthUtility.userInfo?.token ?? '';
      final user = AuthUtility.userInfo?.data;

      final empresa = Empresa(id: TenantContext.empresaId ?? 0);
      final usuarioAbertura = Login(id: user?.id ?? 0);
      final setor = Setor(id: _setorId!);

      final chamado = Chamado(
        titulo: _titulo.text,
        descricao: _descricao.text,
        status: StatusChamadoEnum.fromString(_status),
        prioridade: PrioridadeChamadoEnum.fromString(_prioridade),
        empresa: empresa,
        usuarioAbertura: usuarioAbertura,
        setor: setor,
        dataAbertura: DateTime.now(),
      );

      final criado = await ChamadoCaller().createChamado(chamado, token: token);

      await _anexarImagensDoChat(criado.id!, criado.empresa.id);

      if (mounted) Navigator.pop(context, criado);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GridColors.error,
            content: Text('Erro ao abrir chamado: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Baixa cada imagem da conversa (ja hospedada no GED via /api/arquivos) e
  /// reenvia como anexo do chamado recem-criado. Falha em um anexo nao
  /// interrompe o fluxo — o chamado ja foi criado, e o essencial.
  Future<void> _anexarImagensDoChat(int chamadoId, int? empresaId) async {
    for (var i = 0; i < widget.anexosChat.length; i++) {
      final anexo = widget.anexosChat[i];
      final fileId = anexo['fileId'];
      final fileName = (anexo['fileName'] ?? 'anexo_$i').toString();
      if (fileId == null) continue;
      if (mounted) {
        setState(() =>
            _progresso = 'Anexando ${i + 1}/${widget.anexosChat.length}...');
      }
      try {
        final resp = await http.get(
          Uri.parse(TenantContext.applyToUrl(
              ApiLinks.downloadArquivo(fileId.toString()))),
          headers: TenantContext.headers,
        );
        if (resp.statusCode == 200) {
          await AnexoFinanceiroService().uploadBytes(
              chamadoId, 'CHAMADO', resp.bodyBytes, fileName,
              empresaId: empresaId);
        }
      } catch (_) {
        // Anexo individual falhou — nao bloqueia o restante do fluxo.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: GridColors.dialogBackground,
            elevation: 8,
            shadowColor: GridColors.shadow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(color: GridColors.primary),
                  child: Row(
                    children: [
                      const Icon(Icons.support_agent,
                          color: GridColors.textPrimary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Abrir Chamado',
                          style: TextStyle(
                            color: GridColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _submitting ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close,
                            color: GridColors.textPrimaryMuted, size: 20),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _titulo,
                            decoration: const InputDecoration(labelText: 'Título'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Informe o título'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descricao,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              alignLabelWithHint: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Informe a descrição'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _prioridade,
                            decoration:
                                const InputDecoration(labelText: 'Prioridade'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'BAIXA', child: Text('Baixa')),
                              DropdownMenuItem(
                                  value: 'MEDIA', child: Text('Média')),
                              DropdownMenuItem(
                                  value: 'ALTA', child: Text('Alta')),
                              DropdownMenuItem(
                                  value: 'URGENTE', child: Text('Urgente')),
                            ],
                            onChanged: (v) =>
                                setState(() => _prioridade = v ?? 'MEDIA'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _setorId,
                            isExpanded: true,
                            decoration:
                                const InputDecoration(labelText: 'Setor'),
                            items: _setores
                                .map((e) => DropdownMenuItem<int>(
                                      value: e['value'] as int,
                                      child: Text(e['label'] as String),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _setorId = v),
                            validator: (v) =>
                                v == null ? 'Selecione um setor' : null,
                          ),
                          if (widget.anexosChat.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.attach_file,
                                    size: 16, color: GridColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  '${widget.anexosChat.length} '
                                  '${widget.anexosChat.length == 1 ? 'imagem do chat sera anexada' : 'imagens do chat serao anexadas'}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: GridColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                          if (_progresso != null) ...[
                            const SizedBox(height: 8),
                            Text(_progresso!,
                                style: const TextStyle(
                                    fontSize: 12, color: GridColors.info)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(GridTexts.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GridColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Abrir Chamado'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
