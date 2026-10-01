import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/chamado_model.dart';
import '../../services/chamado_caller.dart';
import '../../services/anexo_financeiro_service.dart';
import '../../../models/auth_utility.dart';
import '../../../models/empresa_model.dart';
import '../../../models/setor_model.dart';
import '../../../models/login_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/utils.dart';
// ★ adicionando paleta de cores
import '../../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

class TicketFormBottomSheet extends StatefulWidget {
  final String sectorDescricao; // nome do setor vindo do chat

  /// Historico do chat, usado para pre-preencher a descricao (card #432).
  final String initialDescricao;

  /// Imagens anexadas na conversa ({'fileId', 'fileName'}), reanexadas ao
  /// chamado apos a criacao (card #432).
  final List<Map<String, dynamic>> anexosChat;

  const TicketFormBottomSheet({
    super.key,
    required this.sectorDescricao,
    this.initialDescricao = '',
    this.anexosChat = const [],
  });

  @override
  State<TicketFormBottomSheet> createState() => _TicketFormBottomSheetState();
}

class _TicketFormBottomSheetState extends State<TicketFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  late final TextEditingController _descricao;

  String _status = 'ABERTO';
  String _prioridade = 'MEDIA';

  int? _setorId;
  String? _setorDesc;

  bool _submitting = false;
  String? _progresso;
  List<Map<String, dynamic>> _setores = [];

  @override
  void initState() {
    super.initState();
    _descricao = TextEditingController(text: widget.initialDescricao);
    _carregarSetores();
  }

  Future<void> _carregarSetores() async {
    final itens = await Chamado.loadSetores();
    setState(() {
      _setores = itens;
      final found = _setores.firstWhere(
        (e) =>
            (e['label'] as String).toLowerCase().trim() ==
            widget.sectorDescricao.toLowerCase().trim(),
        orElse: () => {},
      );
      if (found.isNotEmpty) {
        _setorId = found['value'] as int;
        _setorDesc = found['label'] as String;
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
    setState(() => _submitting = true);
    try {
      final token = AuthUtility.userInfo?.token ?? '';
      final user = AuthUtility.userInfo?.data;

      final empresa = Empresa(id: pegarEmpresaLogada());
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

      if (mounted) {
        Navigator.pop(context, criado);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GridColors.secondary, // ★ verde sucesso
            content: Text(
              'Chamado aberto com sucesso (ID ${criado.id})',
              style: const TextStyle(color: GridColors.textPrimary),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GridColors.error, // ★ vermelho erro
            content: Text('Erro ao abrir chamado: $e',
                style: const TextStyle(color: GridColors.textPrimary)),
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
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: GridColors.card, // ★ fundo branco do card
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Abrir Chamado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GridColors.primary, // ★ título vermelho logo
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titulo,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      labelStyle: TextStyle(color: GridColors.secondary), // ★
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: GridColors.primary), // ★
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o título'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descricao,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      labelStyle: TextStyle(color: GridColors.secondary), // ★
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: GridColors.primary), // ★
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe a descrição'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _prioridade,
                    decoration: const InputDecoration(
                      labelText: 'Prioridade',
                      labelStyle: TextStyle(color: GridColors.secondary), // ★
                    ),
                    items: const [
                      DropdownMenuItem(value: 'BAIXA', child: Text('Baixa')),
                      DropdownMenuItem(value: 'MEDIA', child: Text('Média')),
                      DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                      DropdownMenuItem(
                          value: 'URGENTE', child: Text('Urgente')),
                    ],
                    onChanged: (v) =>
                        setState(() => _prioridade = v ?? 'MEDIA'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      labelStyle: TextStyle(color: GridColors.secondary), // ★
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ABERTO', child: Text('Aberto')),
                      DropdownMenuItem(
                          value: 'EM_ANDAMENTO', child: Text('Em Andamento')),
                      DropdownMenuItem(
                          value: 'FECHADO', child: Text('Fechado')),
                      DropdownMenuItem(
                          value: 'CANCELADO', child: Text('Cancelado')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'ABERTO'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _setorId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Setor',
                      labelStyle: TextStyle(color: GridColors.secondary), // ★
                    ),
                    items: _setores.map((e) {
                      return DropdownMenuItem<int>(
                        value: e['value'] as int,
                        child: Text(e['label'] as String),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _setorId = v;
                        _setorDesc =
                            _setores.firstWhere((e) => e['value'] == v)['label']
                                as String;
                      });
                    },
                    validator: (v) => v == null ? 'Selecione um setor' : null,
                  ),
                  if (widget.anexosChat.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_file,
                            size: 16, color: GridColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.anexosChat.length} '
                          '${widget.anexosChat.length == 1 ? 'imagem do chat sera anexada' : 'imagens do chat serao anexadas'}',
                          style: const TextStyle(
                              fontSize: 12, color: GridColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                  if (_progresso != null) ...[
                    const SizedBox(height: 6),
                    Text(_progresso!,
                        style: const TextStyle(
                            fontSize: 12, color: GridColors.info)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: GridColors.secondary), // ★
                      foregroundColor: GridColors.secondary, // ★
                    ),
                    child: const Text(GridTexts.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.primary, // ★
                      foregroundColor: GridColors.textPrimary, // ★
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: GridColors.textPrimary), // ★
                          )
                        : const Text('Abrir Chamado'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
