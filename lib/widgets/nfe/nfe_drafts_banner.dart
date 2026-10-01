import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/models/nfe/nfe_draft_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_draft_status.dart';
import 'package:task_manager_flutter/repositories/nfe_draft_repository.dart';
import 'package:task_manager_flutter/services/nfe/nfe_draft_sync_service.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';

/// Seção de rascunhos offline de NFe + banner de "sem conexão".
///
/// Especificação de UI definida pelo `ui-ux-pro-max` (card W3R3): faixa fixa
/// no topo da lista de NFe (não aba separada), banner persistente de sem
/// conexão, badge por estado (rascunho/enviando/enviado/conflito/erro) e
/// botão "Enviar quando online" -> "Enviar agora" conforme conectividade.
///
/// Usado tanto em `mobile/screens/nfe_grid_screen.dart` quanto em
/// `windows/screens/nfe_grid_screen.dart`.
class NfeDraftsBanner extends StatefulWidget {
  /// Chamado após uma sincronização mudar o estado dos rascunhos (ex.: para
  /// a tela recarregar a grid principal quando algo for enviado).
  final VoidCallback? onSincronizado;

  const NfeDraftsBanner({super.key, this.onSincronizado});

  @override
  State<NfeDraftsBanner> createState() => NfeDraftsBannerState();
}

class NfeDraftsBannerState extends State<NfeDraftsBanner> {
  final _repository = NfeDraftRepository();
  late final NfeDraftSyncService _syncService =
      NfeDraftSyncService(repository: _repository);

  List<NfeDraftModel> _drafts = const [];
  bool _online = true;
  final Set<String> _enviando = {};

  @override
  void initState() {
    super.initState();
    _carregar();
    _checarConectividade();
    Connectivity().onConnectivityChanged.listen((_) => _checarConectividade());
  }

  Future<void> _checarConectividade() async {
    final result = await Connectivity().checkConnectivity();
    final online = result != ConnectivityResult.none;
    if (mounted && online != _online) {
      setState(() => _online = online);
    } else if (mounted) {
      _online = online;
    }
  }

  /// Recarrega a lista de rascunhos. Público para a tela hospedeira poder
  /// forçar refresh (ex.: logo após salvar um novo rascunho).
  Future<void> recarregar() => _carregar();

  Future<void> _carregar() async {
    final drafts = await _repository.listarRascunhos();
    if (!mounted) return;
    setState(() => _drafts = drafts);
  }

  Future<void> _enviar(NfeDraftModel draft) async {
    setState(() => _enviando.add(draft.id));
    final resultado = await _syncService.sincronizar(draft);
    if (!mounted) return;
    setState(() => _enviando.remove(draft.id));
    await _carregar();
    widget.onSincronizado?.call();

    if (!mounted) return;
    switch (resultado) {
      case NfeDraftSyncResult.enviado:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Rascunho enviado com sucesso!'),
          backgroundColor: GridColors.success,
        ));
        break;
      case NfeDraftSyncResult.conflito:
        _mostrarDialogoConflito(draft);
        break;
      case NfeDraftSyncResult.semConexao:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ainda sem conexão. Tente novamente mais tarde.'),
          backgroundColor: GridColors.warning,
        ));
        break;
      case NfeDraftSyncResult.erro:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao enviar rascunho.'),
          backgroundColor: GridColors.error,
        ));
        break;
    }
  }

  Future<void> _mostrarDialogoConflito(NfeDraftModel draft) async {
    if (!mounted) return;
    final descartar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nota já transmitida'),
        content: const Text(
          'Este rascunho não pôde ser enviado porque já existe uma NFe '
          'transmitida no servidor com este número/chave. O rascunho local '
          'não pode substituir uma nota já emitida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fechar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: GridColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar rascunho'),
          ),
        ],
      ),
    );
    if (descartar != true || !mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Descartar rascunho local?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await _repository.excluirRascunho(draft.id);
      await _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_drafts.isEmpty && _online) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_online) _buildOfflineBanner(),
        if (_drafts.isNotEmpty) _buildDraftsSection(),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: GridColors.warningDark.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: GridColors.warningDark),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sem conexão. Notas serão salvas como rascunho e enviadas '
              'automaticamente quando a conexão voltar.',
              style: TextStyle(fontSize: 12, color: GridColors.warningDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsSection() {
    return Container(
      color: GridColors.warning.withOpacity(0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              'Rascunhos pendentes (${_drafts.length})',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: GridColors.textSecondary),
            ),
          ),
          ..._drafts.map(_buildDraftRow),
          const Divider(height: 1, color: GridColors.divider),
        ],
      ),
    );
  }

  Widget _buildDraftRow(NfeDraftModel draft) {
    final enviando = _enviando.contains(draft.id) ||
        draft.status == NfeDraftStatus.enviando;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _buildStatusChip(draft.status, enviando: enviando),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _descricaoLinha(draft),
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildActionButton(draft, enviando: enviando),
        ],
      ),
    );
  }

  /// Texto de exibição do rascunho — usa somente [NfeDraftModel.contextoExibicao]
  /// (dado só para exibição), nunca `dadosFormulario` (que é fielmente o que
  /// será reenviado ao backend, ex.: `{}` para a ação 'emitir').
  String _descricaoLinha(NfeDraftModel draft) {
    final numero = draft.contextoExibicao['numero'];
    final destinatario = draft.contextoExibicao['destinatario'] ??
        draft.contextoExibicao['razaoSocial'];
    final partes = [
      if (numero != null) 'NF-e #$numero' else 'NFe ref. ${draft.nfeIdReferencia}',
      if (destinatario != null) destinatario.toString(),
    ];
    // partes sempre tem ao menos 1 item (o if/else da 1ª posição garante
    // isso), mas join funciona igual com 1 ou 2 itens.
    return partes.join(' — ');
  }

  Widget _buildStatusChip(NfeDraftStatus status, {required bool enviando}) {
    late Color cor;
    late IconData icone;
    late String label;

    if (enviando) {
      cor = GridColors.info;
      icone = Icons.sync;
      label = 'Enviando...';
    } else {
      switch (status) {
        case NfeDraftStatus.rascunho:
          cor = GridColors.warning;
          icone = Icons.edit_note;
          label = 'Rascunho';
          break;
        case NfeDraftStatus.enviando:
          cor = GridColors.info;
          icone = Icons.sync;
          label = 'Enviando...';
          break;
        case NfeDraftStatus.enviado:
          cor = GridColors.success;
          icone = Icons.check_circle;
          label = 'Enviado';
          break;
        case NfeDraftStatus.conflito:
          cor = GridColors.error;
          icone = Icons.report_problem_outlined;
          label = 'Conflito';
          break;
        case NfeDraftStatus.erro:
          cor = GridColors.error;
          icone = Icons.error_outline;
          label = 'Erro ao enviar';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: cor),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: cor)),
        ],
      ),
    );
  }

  Widget _buildActionButton(NfeDraftModel draft, {required bool enviando}) {
    if (draft.status == NfeDraftStatus.conflito) {
      return TextButton(
        onPressed: () => _mostrarDialogoConflito(draft),
        child: const Text('Ver detalhes do conflito',
            style: TextStyle(fontSize: 11, color: GridColors.error)),
      );
    }

    if (enviando) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!_online) {
      return TextButton.icon(
        onPressed: null,
        icon: const Icon(Icons.cloud_off_outlined, size: 14),
        label: const Text('Enviar quando online', style: TextStyle(fontSize: 11)),
      );
    }

    return TextButton.icon(
      onPressed: () => _enviar(draft),
      icon: const Icon(Icons.cloud_upload, size: 14, color: GridColors.secondary),
      label: const Text('Enviar agora',
          style: TextStyle(fontSize: 11, color: GridColors.secondary)),
    );
  }
}
