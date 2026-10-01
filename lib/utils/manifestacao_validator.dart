import '../models/manifestacao/manifestacao_status.dart';
import '../core/constants/manifestacao_constants.dart';
import '../core/exceptions/manifestacao_exceptions.dart';
import '../core/services/logger_service.dart';

/// Utilitário de validação para Manifestação
/// Implementa validação centralizada com error handling significativo
class ManifestacaoValidator {
  /// Valida status (obrigatório)
  static String? validateStatus(ManifestacaoStatus? value) {
    if (value == null) {
      LoggerService.validacao('status', 'FALHOU: nulo');
      return 'Status é obrigatório';
    }
    LoggerService.validacao('status', 'PASSOU', detalhes: value.label);
    return null;
  }

  /// Valida observação (obrigatória para recusa)
  static String? validateObservacao(
    String? value,
    ManifestacaoStatus? status,
  ) {
    if (status == ManifestacaoStatus.recusar) {
      if (value == null || value.trim().isEmpty) {
        LoggerService.validacao('observacao', 'FALHOU: vazia para recusa');
        return 'Observação é obrigatória para recusa';
      }
      if (value.length < ManifestacaoConstants.observacaoMinLengthRecusa) {
        LoggerService.validacao('observacao', 'FALHOU: muito curta',
          detalhes: '${value.length} < ${ManifestacaoConstants.observacaoMinLengthRecusa}');
        return 'Observação deve ter pelo menos ${ManifestacaoConstants.observacaoMinLengthRecusa} caracteres';
      }
    }
    if (value != null && value.length > ManifestacaoConstants.observacaoMaxLength) {
      LoggerService.validacao('observacao', 'FALHOU: muito longa',
        detalhes: '${value.length} > ${ManifestacaoConstants.observacaoMaxLength}');
      return 'Observação não pode exceder ${ManifestacaoConstants.observacaoMaxLength} caracteres';
    }
    LoggerService.validacao('observacao', 'PASSOU', detalhes: '${value?.length ?? 0}/${ManifestacaoConstants.observacaoMaxLength}');
    return null;
  }

  /// Valida quantidade recebida (obrigatória para parcial)
  static String? validateQuantidade(
    int? value,
    ManifestacaoStatus? status,
  ) {
    if (status == ManifestacaoStatus.parcial) {
      if (value == null || value <= 0) {
        LoggerService.validacao('quantidade', 'FALHOU: inválida', detalhes: 'valor=$value');
        return 'Quantidade deve ser maior que ${ManifestacaoConstants.quantidadeMinima}';
      }
    }
    LoggerService.validacao('quantidade', 'PASSOU', detalhes: 'valor=$value');
    return null;
  }

  /// Valida motivo da recusa (obrigatório para recusa total)
  static String? validateMotivoRecusa(
    String? value,
    ManifestacaoStatus? status,
  ) {
    if (status == ManifestacaoStatus.recusar) {
      if (value == null || value.trim().isEmpty) {
        LoggerService.validacao('motivoRecusa', 'FALHOU: vazio');
        return 'Motivo é obrigatório';
      }
    }
    LoggerService.validacao('motivoRecusa', 'PASSOU');
    return null;
  }

  /// Valida todo o formulário e lança ValidationException se houver erros
  static Map<String, String> validateAll({
    required ManifestacaoStatus? status,
    required String observacao,
    required int? quantidadeRecebida,
    required String? motivoRecusa,
  }) {
    final errors = <String, String>{};

    final statusError = validateStatus(status);
    if (statusError != null) {
      errors['status'] = statusError;
    }

    final obsError = validateObservacao(observacao, status);
    if (obsError != null) {
      errors['observacao'] = obsError;
    }

    final qtdError = validateQuantidade(quantidadeRecebida, status);
    if (qtdError != null) {
      errors['quantidadeRecebida'] = qtdError;
    }

    final motivoError = validateMotivoRecusa(motivoRecusa, status);
    if (motivoError != null) {
      errors['motivoRecusa'] = motivoError;
    }

    if (errors.isNotEmpty) {
      LoggerService.warning('Validação falhou com ${errors.length} erros', tag: 'VALIDATOR');
      throw ValidationException(erros: errors);
    }

    LoggerService.info('Formulário validado com sucesso', tag: 'VALIDATOR');
    return errors;
  }

  /// Valida contador de observação e retorna msg de feedback visual
  static String validarContadorObservacao(String texto) {
    final count = texto.length;
    final max = ManifestacaoConstants.observacaoMaxLength;
    return '$count/$max';
  }
}
