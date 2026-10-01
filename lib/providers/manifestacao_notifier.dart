import 'package:flutter/foundation.dart';
import '../models/manifestacao/manifestacao_model.dart';
import '../models/manifestacao/manifestacao_status.dart';
import '../services/manifestacao_caller.dart';

typedef ListarPendentesFunc = Future<ManifestacaoResult> Function();
typedef RegistrarManifestacaoFunc = Future<ManifestacaoResult> Function({
  required String chave,
  required String tipo,
  String? justificativa,
});

class ManifestacaoNotifier extends ChangeNotifier {
  final ListarPendentesFunc _listarPendentes;
  final RegistrarManifestacaoFunc _registrarManifestacao;

  ManifestacaoModel? _manifestacao;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSubmitting = false;

  ManifestacaoNotifier({
    ListarPendentesFunc? listarPendentes,
    RegistrarManifestacaoFunc? registrarManifestacao,
  })  : _listarPendentes = listarPendentes ?? ManifestacaoCaller.listarPendentes,
        _registrarManifestacao = registrarManifestacao ??
            ManifestacaoCaller.registrarManifestacao;

  ManifestacaoModel? get manifestacao => _manifestacao;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;

  bool get isFormValid => _manifestacao?.isValid ?? false;

  Future<void> loadManifestacao(String nfeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _listarPendentes();
      if (result.success && result.list != null && result.list!.isNotEmpty) {
        final item = result.list!.firstWhere(
          (e) => e is Map && e['nfeId'] == nfeId,
          orElse: () => null,
        );
        if (item == null) {
          _errorMessage = 'NFe $nfeId não encontrada nas pendências';
        } else if (item is Map<String, dynamic>) {
          _manifestacao = ManifestacaoModel.fromJson(item);
        } else {
          _errorMessage = 'Formato inesperado na resposta da API';
        }
      } else {
        _errorMessage =
            result.message ?? 'Nenhuma manifestação pendente encontrada';
      }
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Erro ao carregar manifestação: $e';
      _isLoading = false;
    }
    notifyListeners();
  }

  void setStatus(ManifestacaoStatus? status) {
    if (_manifestacao == null) return;
    _manifestacao = _manifestacao!.copyWith(status: status);
    notifyListeners();
  }

  void setObservacao(String obs) {
    if (_manifestacao == null) return;
    _manifestacao = _manifestacao!.copyWith(observacao: obs);
    notifyListeners();
  }

  void setQuantidadeRecebida(int? qtd) {
    if (_manifestacao == null) return;
    _manifestacao = _manifestacao!.copyWith(quantidadeRecebida: qtd);
    notifyListeners();
  }

  void setMotivoRecusa(String? motivo) {
    if (_manifestacao == null) return;
    _manifestacao = _manifestacao!.copyWith(motivoRecusa: motivo);
    notifyListeners();
  }

  Future<bool> submitManifestacao() async {
    if (!isFormValid || _manifestacao == null) {
      _errorMessage = 'Formulário inválido';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _registrarManifestacao(
        chave: _manifestacao!.nfeId,
        tipo: _manifestacao!.status!.codigo,
        justificativa: _manifestacao!.observacao.isNotEmpty
            ? _manifestacao!.observacao
            : null,
      );

      if (result.success) {
        _isSubmitting = false;
        _manifestacao = null;
      } else {
        _errorMessage = result.message ?? 'Erro ao registrar manifestação';
        _isSubmitting = false;
      }
    } catch (e) {
      _errorMessage = 'Erro ao enviar manifestação: $e';
      _isSubmitting = false;
    }
    notifyListeners();
    return _errorMessage == null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _manifestacao = null;
    _errorMessage = null;
    _isLoading = false;
    _isSubmitting = false;
    notifyListeners();
  }
}
