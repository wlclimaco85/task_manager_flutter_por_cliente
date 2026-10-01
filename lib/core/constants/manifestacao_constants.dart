/// Constantes para Manifestação NFe

class ManifestacaoConstants {
  // ======== VALIDAÇÃO ========
  static const int observacaoMaxLength = 500;
  static const int observacaoMinLengthRecusa = 10;
  static const int quantidadeMinima = 1;
  static const int motivoRecusaMinLength = 10;

  // ======== PRAZOS ========
  static const Duration timeout = Duration(seconds: 30);
  static const Duration delayNavegacao = Duration(milliseconds: 500);
  static const Duration duracionSnackBar = Duration(seconds: 3);

  // ======== RETRY ========
  static const int maxRetry = 5;
  static const Duration delayRetry = Duration(seconds: 2);

  // ======== UI ========
  static const double botaoAltura = 48.0;
  static const double iconeTamanho = 20.0;
  static const double cardPadding = 16.0;
  static const double raioCard = 8.0;

  // ======== BREAKPOINTS ========
  static const double breakpointMobile = 480.0;
  static const double breakpointTablet = 600.0;
  static const double breakpointDesktop = 1024.0;

  // ======== LABELS ========
  static const String labelTipoManifestacao = 'Tipo de Manifestação';
  static const String labelObservacoes = 'Observações (Opcional)';
  static const String labelQuantidade = 'Quantidade Recebida';
  static const String labelMotivoRecusa = 'Motivo da Recusa';

  // ======== MENSAGENS ========
  static const String erroCarregamento = 'Erro ao carregar manifestação';
  static const String erroPreenchimento = 'Preencha todos os campos obrigatórios';
  static const String erroFormulario = 'Formulário inválido';
  static const String sucessoAceitacao = 'NFe aceita com sucesso';
  static const String sucessoRecusa = 'NFe recusada com sucesso';
  static const String sucessoParcial = 'Recebimento parcial registrado';

  // ======== REGEX ========
  static const String regexNumeroNfe = r'^\d{44}$';
  static const String regexCnpj = r'^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$';
}
