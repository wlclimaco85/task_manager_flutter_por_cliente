import 'package:flutter/material.dart';
import '../../models/manifestacao/manifestacao_status.dart';
import '../../screens/nfe/design_tokens.dart';

/// Dropdown para seleção de status de manifestação
class StatusDropdownWidget extends StatelessWidget {
  final ManifestacaoStatus? value;
  final ValueChanged<ManifestacaoStatus?> onChanged;
  final String? errorText;

  const StatusDropdownWidget({
    Key? key,
    required this.value,
    required this.onChanged,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: ManifestacaoDesignTokens.textBodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ManifestacaoDesignTokens.spacing8),
        Container(
          height: ManifestacaoDesignTokens.inputHeightMedium,
          decoration: BoxDecoration(
            border: Border.all(
              color: errorText != null
                  ? ManifestacaoDesignTokens.colorError
                  : ManifestacaoDesignTokens.colorNeutral300,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(
              ManifestacaoDesignTokens.radiusMedium,
            ),
          ),
          child: DropdownButton<ManifestacaoStatus>(
            value: value,
            isExpanded: true,
            underline: Container(),
            hint: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ManifestacaoDesignTokens.spacing12,
              ),
              child: Text(
                'Selecione o status',
                style: ManifestacaoDesignTokens.textBodyMedium.copyWith(
                  color: ManifestacaoDesignTokens.colorNeutral500,
                ),
              ),
            ),
            items: ManifestacaoStatus.values
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ManifestacaoDesignTokens.spacing12,
                        ),
                        child: Text(
                          status.label,
                          style: ManifestacaoDesignTokens.textBodyMedium,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: ManifestacaoDesignTokens.spacing8),
          Text(
            errorText!,
            style: ManifestacaoDesignTokens.textBodySmall.copyWith(
              color: ManifestacaoDesignTokens.colorError,
            ),
          ),
        ],
      ],
    );
  }
}
