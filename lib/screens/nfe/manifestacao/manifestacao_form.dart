import 'package:flutter/material.dart';
import '../../../models/manifestacao/manifestacao_status.dart';
import '../../../providers/manifestacao_notifier.dart';
import '../../../widgets/manifestacao/status_dropdown_compat.dart';
import '../../../widgets/manifestacao/observacao_textfield_compat.dart';
import '../design_tokens.dart';

/// Formulário de manifestação com campos condicionais
class ManifestacaoForm extends StatefulWidget {
  final ManifestacaoNotifier notifier;

  const ManifestacaoForm({
    Key? key,
    required this.notifier,
  }) : super(key: key);

  @override
  State<ManifestacaoForm> createState() => _ManifestacaoFormState();
}

class _ManifestacaoFormState extends State<ManifestacaoForm> {
  late Map<String, String> _validationErrors;

  @override
  void initState() {
    super.initState();
    _validationErrors = {};
  }

  @override
  Widget build(BuildContext context) {
    final manifestacao = widget.notifier.manifestacao;
    if (manifestacao == null) {
      return SizedBox.shrink();
    }

    final isMobile = MediaQuery.of(context).size.width <
        ManifestacaoDesignTokens.breakpointTablet;

    return SingleChildScrollView(
      padding: EdgeInsets.all(ManifestacaoDesignTokens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Dropdown
          StatusDropdownWidget(
            value: manifestacao.status,
            onChanged: (status) {
              widget.notifier.setStatus(status);
              setState(() => _validationErrors.clear());
            },
            errorText: _validationErrors['status'],
          ),
          SizedBox(height: ManifestacaoDesignTokens.spacing20),

          // Observação (sempre presente)
          ObservacaoTextfieldWidget(
            value: manifestacao.observacao,
            onChanged: widget.notifier.setObservacao,
            errorText: _validationErrors['observacao'],
            required: manifestacao.status == ManifestacaoStatus.recusar,
            maxCharacters: 500,
          ),
          SizedBox(height: ManifestacaoDesignTokens.spacing20),

          // Campos condicionais baseado no status
          if (manifestacao.status == ManifestacaoStatus.parcial) ...[
            _buildQuantidadeField(manifestacao, context),
            SizedBox(height: ManifestacaoDesignTokens.spacing20),
          ],

          if (manifestacao.status == ManifestacaoStatus.recusar) ...[
            _buildMotivoRecusaField(manifestacao),
            SizedBox(height: ManifestacaoDesignTokens.spacing20),
          ],

          // Info de acessibilidade
          Container(
            padding: EdgeInsets.all(ManifestacaoDesignTokens.spacing12),
            decoration: BoxDecoration(
              color: ManifestacaoDesignTokens.colorInfo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ManifestacaoDesignTokens.radiusMedium,
              ),
              border: Border.all(
                color: ManifestacaoDesignTokens.colorInfo.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: ManifestacaoDesignTokens.colorInfo,
                  size: 20,
                ),
                SizedBox(width: ManifestacaoDesignTokens.spacing8),
                Expanded(
                  child: Text(
                    'Todos os campos marcados com * são obrigatórios',
                    style: ManifestacaoDesignTokens.textBodySmall.copyWith(
                      color: ManifestacaoDesignTokens.colorInfo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói campo de quantidade para recebimento parcial
  Widget _buildQuantidadeField(
    dynamic manifestacao,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantidade Recebida',
          style: ManifestacaoDesignTokens.textBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ManifestacaoDesignTokens.spacing8),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final qtd = int.tryParse(value);
            widget.notifier.setQuantidadeRecebida(qtd);
          },
          decoration: InputDecoration(
            hintText: 'Ex: 50',
            hintStyle: ManifestacaoDesignTokens.textBodyMedium.copyWith(
              color: ManifestacaoDesignTokens.colorNeutral500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ManifestacaoDesignTokens.radiusMedium,
              ),
            ),
            contentPadding: EdgeInsets.all(
              ManifestacaoDesignTokens.spacing12,
            ),
            errorText: _validationErrors['quantidadeRecebida'],
          ),
          style: ManifestacaoDesignTokens.textBodyMedium,
        ),
      ],
    );
  }

  /// Constrói campo de motivo da recusa
  Widget _buildMotivoRecusaField(dynamic manifestacao) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motivo da Recusa',
          style: ManifestacaoDesignTokens.textBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ManifestacaoDesignTokens.spacing8),
        TextField(
          onChanged: widget.notifier.setMotivoRecusa,
          maxLength: 150,
          maxLines: 2,
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Descreva o motivo...',
            hintStyle: ManifestacaoDesignTokens.textBodyMedium.copyWith(
              color: ManifestacaoDesignTokens.colorNeutral500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ManifestacaoDesignTokens.radiusMedium,
              ),
            ),
            contentPadding: EdgeInsets.all(
              ManifestacaoDesignTokens.spacing12,
            ),
            errorText: _validationErrors['motivoRecusa'],
          ),
          style: ManifestacaoDesignTokens.textBodyMedium,
        ),
      ],
    );
  }
}
