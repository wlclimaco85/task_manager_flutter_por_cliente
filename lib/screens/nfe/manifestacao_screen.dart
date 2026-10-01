import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/manifestacao/manifestacao_status.dart';
import '../../providers/manifestacao_notifier.dart';
import '../../utils/manifestacao_validator.dart';
import '../../widgets/manifestacao/confirmacao_modal_widget.dart';
import 'design_tokens.dart';
import 'manifestacao/manifestacao_header.dart';
import 'manifestacao/manifestacao_form.dart';
import 'manifestacao/manifestacao_footer.dart';

/// Screen principal de Manifestação de Recebimento NFe
class ManifestacaoScreen extends StatefulWidget {
  /// ID da NFe a manifestar
  final String nfeId;

  const ManifestacaoScreen({
    Key? key,
    required this.nfeId,
  }) : super(key: key);

  @override
  State<ManifestacaoScreen> createState() => _ManifestacaoScreenState();
}

class _ManifestacaoScreenState extends State<ManifestacaoScreen> {
  ManifestacaoNotifier? _ownNotifier;

  ManifestacaoNotifier get _notifier {
    try {
      return Provider.of<ManifestacaoNotifier>(context, listen: false);
    } catch (_) {
      _ownNotifier ??= ManifestacaoNotifier();
      return _ownNotifier!;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadManifestacao());
  }

  @override
  void dispose() {
    _ownNotifier?.dispose();
    super.dispose();
  }

  /// Carrega os dados da manifestação
  Future<void> _loadManifestacao() async {
    await _notifier.loadManifestacao(widget.nfeId);
  }

  /// Valida e submete com status "Aceitar"
  Future<void> _handleAceitar() async {
    final manifestacao = _notifier.manifestacao;
    if (manifestacao == null) return;

    _notifier.setStatus(ManifestacaoStatus.aceitar);

    final success = await _notifier.submitManifestacao();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('NFe aceita com sucesso'),
          backgroundColor: ManifestacaoDesignTokens.colorSuccess,
          duration: Duration(seconds: 3),
        ),
      );
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  /// Valida e submete com status "Recusar"
  Future<void> _handleRecusar() async {
    final manifestacao = _notifier.manifestacao;
    if (manifestacao == null) return;

    _notifier.setStatus(ManifestacaoStatus.recusar);

    final updated = _notifier.manifestacao!;
    final errors = ManifestacaoValidator.validateAll(
      status: updated.status,
      observacao: updated.observacao,
      quantidadeRecebida: updated.quantidadeRecebida,
      motivoRecusa: updated.motivoRecusa,
    );

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
          backgroundColor: ManifestacaoDesignTokens.colorError,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Mostra modal de confirmação
    ConfirmacaoModalWidget.show(
      context: context,
      titulo: 'Confirmar Recusa',
      mensagem: 'Tem certeza que deseja recusar esta NFe?',
      botaoPrincipal: 'Recusar',
      botaoSecundario: 'Cancelar',
      corBotaoPrincipal: ManifestacaoDesignTokens.colorError,
      icone: Icons.warning_amber,
      onBotaoPrincipal: () async {
        Navigator.of(context).pop(); // Fecha modal
        final success = await _notifier.submitManifestacao();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('NFe recusada com sucesso'),
              backgroundColor: ManifestacaoDesignTokens.colorSuccess,
              duration: Duration(seconds: 3),
            ),
          );
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) Navigator.of(context).pop(true);
          });
        }
      },
      onBotaoSecundario: () => Navigator.of(context).pop(),
    );
  }

  /// Valida e submete com status "Parcial"
  Future<void> _handleParcial() async {
    final manifestacao = _notifier.manifestacao;
    if (manifestacao == null) return;

    _notifier.setStatus(ManifestacaoStatus.parcial);

    final updated = _notifier.manifestacao!;
    final errors = ManifestacaoValidator.validateAll(
      status: updated.status,
      observacao: updated.observacao,
      quantidadeRecebida: updated.quantidadeRecebida,
      motivoRecusa: updated.motivoRecusa,
    );

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
          backgroundColor: ManifestacaoDesignTokens.colorError,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Mostra modal de confirmação
    ConfirmacaoModalWidget.show(
      context: context,
      titulo: 'Confirmar Recebimento Parcial',
      mensagem: 'Confirmar recebimento de ${manifestacao.quantidadeRecebida} unidades?',
      botaoPrincipal: 'Confirmar',
      botaoSecundario: 'Cancelar',
      corBotaoPrincipal: ManifestacaoDesignTokens.colorWarning,
      icone: Icons.assignment_late,
      onBotaoPrincipal: () async {
        Navigator.of(context).pop(); // Fecha modal
        final success = await _notifier.submitManifestacao();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recebimento parcial registrado'),
              backgroundColor: ManifestacaoDesignTokens.colorSuccess,
              duration: Duration(seconds: 3),
            ),
          );
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) Navigator.of(context).pop(true);
          });
        }
      },
      onBotaoSecundario: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ManifestacaoNotifier>.value(
      value: _notifier,
      child: Scaffold(
        backgroundColor: ManifestacaoDesignTokens.colorNeutral50,
        body: Column(
          children: [
            // Header com dados da NFe
            Expanded(
              child: Consumer<ManifestacaoNotifier>(
                builder: (_, notifier, __) {
                  if (notifier.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ManifestacaoDesignTokens.colorPrimary,
                        ),
                      ),
                    );
                  }

                  if (notifier.manifestacao == null) {
                    return Center(
                      child: Text(
                        'Erro ao carregar manifestação',
                        style: ManifestacaoDesignTokens.textBodyMedium,
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ManifestacaoHeader(
                        manifestacao: notifier.manifestacao!,
                      ),
                      Expanded(
                        child: ManifestacaoForm(
                          notifier: notifier,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Footer com botões
            Consumer<ManifestacaoNotifier>(
              builder: (_, notifier, __) {
                return ManifestacaoFooter(
                  notifier: notifier,
                  onAceitarTap: _handleAceitar,
                  onRecusarTap: _handleRecusar,
                  onParcialTap: _handleParcial,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
