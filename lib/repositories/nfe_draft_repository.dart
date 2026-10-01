import 'package:hive/hive.dart';
import 'package:task_manager_flutter/models/nfe/nfe_draft_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_draft_status.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Repositório de rascunhos offline de NFe (card W3R3).
///
/// Usa uma box Hive própria (`nfe_drafts_offline`), independente de qualquer
/// cache legado de NFes transmitidas. Não reaproveita a mesma box porque
/// guarda payload de formulário pendente, não NFe já normalizada.
class NfeDraftRepository {
  static const String boxName = 'nfe_drafts_offline';
  static bool _adapterRegistered = false;

  Future<Box<NfeDraftModel>> _abrirBox() async {
    if (!_adapterRegistered && !Hive.isAdapterRegistered(41)) {
      Hive.registerAdapter(NfeDraftModelAdapter());
      _adapterRegistered = true;
    }
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<NfeDraftModel>(boxName);
    }
    return Hive.openBox<NfeDraftModel>(boxName);
  }

  /// Gera um id local determinístico o suficiente para uso single-device
  /// (timestamp + referência da NFe).
  String gerarId(String nfeIdReferencia) =>
      '${nfeIdReferencia}_${DateTime.now().microsecondsSinceEpoch}';

  Future<NfeDraftModel> salvarRascunho({
    required String nfeIdReferencia,
    required Map<String, dynamic> dadosFormulario,
    Map<String, dynamic> contextoExibicao = const {},
    required String acao,
  }) async {
    final box = await _abrirBox();
    final agora = DateTime.now();
    final draft = NfeDraftModel(
      id: gerarId(nfeIdReferencia),
      nfeIdReferencia: nfeIdReferencia,
      dadosFormulario: dadosFormulario,
      contextoExibicao: contextoExibicao,
      acao: acao,
      status: NfeDraftStatus.rascunho,
      criadoEm: agora,
      atualizadoEm: agora,
    );
    await box.put(draft.id, draft);
    L.d('[NfeDraftRepository] Rascunho ${draft.id} salvo (ref=$nfeIdReferencia)');
    return draft;
  }

  Future<List<NfeDraftModel>> listarRascunhos() async {
    final box = await _abrirBox();
    final lista = box.values.toList()
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return lista;
  }

  Future<NfeDraftModel?> obterRascunho(String id) async {
    final box = await _abrirBox();
    return box.get(id);
  }

  Future<void> atualizarStatus(
    String id, {
    required NfeDraftStatus status,
    String? mensagemErro,
    bool limparMensagemErro = false,
  }) async {
    final box = await _abrirBox();
    final atual = box.get(id);
    if (atual == null) return;
    final atualizado = atual.copyWith(
      status: status,
      atualizadoEm: DateTime.now(),
      mensagemErro: mensagemErro,
      clearMensagemErro: limparMensagemErro,
    );
    await box.put(id, atualizado);
    L.d('[NfeDraftRepository] Rascunho $id -> status ${status.code}');
  }

  Future<void> excluirRascunho(String id) async {
    final box = await _abrirBox();
    await box.delete(id);
    L.d('[NfeDraftRepository] Rascunho $id removido');
  }

  Future<int> contarPendentes() async {
    final box = await _abrirBox();
    return box.values
        .where((d) =>
            d.status == NfeDraftStatus.rascunho ||
            d.status == NfeDraftStatus.erro)
        .length;
  }
}
