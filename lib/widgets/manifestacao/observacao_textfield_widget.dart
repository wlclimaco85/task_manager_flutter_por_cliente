import 'package:flutter/material.dart';
import '../../screens/nfe/design_tokens.dart';

/// TextField para observações com contador de caracteres
class ObservacaoTextfieldWidget extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool required;
  final int maxCharacters;

  const ObservacaoTextfieldWidget({
    Key? key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.required = false,
    this.maxCharacters = 500,
  }) : super(key: key);

  @override
  State<ObservacaoTextfieldWidget> createState() =>
      _ObservacaoTextfieldWidgetState();
}

class _ObservacaoTextfieldWidgetState extends State<ObservacaoTextfieldWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characterCount = _controller.text.length;
    final isNearLimit = characterCount > widget.maxCharacters * 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Observação',
              style: ManifestacaoDesignTokens.textBodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.required) ...[
              SizedBox(width: ManifestacaoDesignTokens.spacing4),
              Text(
                '*',
                style: ManifestacaoDesignTokens.textBodyMedium.copyWith(
                  color: ManifestacaoDesignTokens.colorError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: ManifestacaoDesignTokens.spacing8),
        TextField(
          controller: _controller,
          maxLength: widget.maxCharacters,
          maxLines: 4,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            counterText: '',
            hintText: 'Descreva a razão da recusa ou observação...',
            hintStyle: ManifestacaoDesignTokens.textBodyMedium.copyWith(
              color: ManifestacaoDesignTokens.colorNeutral500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ManifestacaoDesignTokens.radiusMedium,
              ),
              borderSide: BorderSide(
                color: widget.errorText != null
                    ? ManifestacaoDesignTokens.colorError
                    : ManifestacaoDesignTokens.colorNeutral300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ManifestacaoDesignTokens.radiusMedium,
              ),
              borderSide: BorderSide(
                color: ManifestacaoDesignTokens.colorPrimary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ManifestacaoDesignTokens.radiusMedium,
              ),
              borderSide: BorderSide(
                color: ManifestacaoDesignTokens.colorError,
              ),
            ),
            contentPadding: EdgeInsets.all(
              ManifestacaoDesignTokens.spacing12,
            ),
          ),
          style: ManifestacaoDesignTokens.textBodyMedium,
        ),
        SizedBox(height: ManifestacaoDesignTokens.spacing8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$characterCount/${widget.maxCharacters}',
              style: ManifestacaoDesignTokens.textBodySmall.copyWith(
                color: isNearLimit
                    ? ManifestacaoDesignTokens.colorWarning
                    : ManifestacaoDesignTokens.colorNeutral500,
              ),
            ),
            if (widget.errorText != null)
              Text(
                widget.errorText!,
                style: ManifestacaoDesignTokens.textBodySmall.copyWith(
                  color: ManifestacaoDesignTokens.colorError,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
