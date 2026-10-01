import 'package:flutter/material.dart';
import '../../screens/nfe/design_tokens.dart';
import '../../core/constants/manifestacao_constants.dart';

/// TextField para observações com contador e validação
/// Implementa WCAG 2.1 AA: 48dp min height, focus outline, live counter
class ObservacaoTextfield extends StatefulWidget {
  /// Controller do input
  final TextEditingController controller;

  /// Callback ao mudar valor
  final ValueChanged<String>? onChanged;

  /// Mensagem de erro a exibir
  final String? errorText;

  /// Máximo de caracteres
  final int maxLength;

  /// Linhas mínimas
  final int minLines;

  /// Linhas máximas
  final int maxLines;

  /// Se deve usar tema dark
  final bool isDarkMode;

  /// Label do campo
  final String label;

  /// Hint text
  final String hintText;

  const ObservacaoTextfield({
    Key? key,
    required this.controller,
    this.onChanged,
    this.errorText,
    this.maxLength = ManifestacaoConstants.observacaoMaxLength,
    this.minLines = 3,
    this.maxLines = 6,
    this.isDarkMode = false,
    this.label = 'Observações',
    this.hintText = 'Digite observações...',
  }) : super(key: key);

  @override
  State<ObservacaoTextfield> createState() => _ObservacaoTextfieldState();
}

class _ObservacaoTextfieldState extends State<ObservacaoTextfield> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Retorna cor de background
  Color _getBackgroundColor() {
    if (widget.errorText != null) {
      return widget.isDarkMode
          ? const Color(0xFF3E2020)
          : const Color(0xFFFFF5F5);
    }
    return widget.isDarkMode
        ? const Color(0xFF2A2A2A)
        : ManifestacaoDesignTokens.colorNeutral50;
  }

  /// Retorna cor de borda
  Color _getBorderColor() {
    if (widget.errorText != null) {
      return ManifestacaoDesignTokens.colorError;
    }
    if (_focusNode.hasFocus) {
      return widget.isDarkMode
          ? const Color(0xFF505050)
          : ManifestacaoDesignTokens.colorNeutral400;
    }
    return widget.isDarkMode
        ? const Color(0xFF404040)
        : ManifestacaoDesignTokens.colorNeutral300;
  }

  /// Retorna cor do texto
  Color _getTextColor() {
    return widget.isDarkMode
        ? const Color(0xFFF0F0F0)
        : ManifestacaoDesignTokens.colorNeutral900;
  }

  /// Retorna cor do hint text
  Color _getHintColor() {
    return widget.isDarkMode
        ? const Color(0xFF808080)
        : ManifestacaoDesignTokens.colorNeutral600;
  }

  /// Calcula cor do contador baseada no preenchimento
  Color _getCounterColor() {
    final count = widget.controller.text.length;
    final max = widget.maxLength;
    final percentual = count / max;

    if (percentual >= 1.0) {
      return ManifestacaoDesignTokens.colorError; // Vermelho
    } else if (percentual >= 0.8) {
      return ManifestacaoDesignTokens.colorWarning; // Laranja
    }
    return widget.isDarkMode
        ? const Color(0xFF808080)
        : ManifestacaoDesignTokens.colorNeutral600;
  }

  @override
  Widget build(BuildContext context) {
    final counter = '${widget.controller.text.length}/${widget.maxLength}';

    return Semantics(
      label: widget.label,
      textField: true,
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(),
                ),
              ),
            ),

          // TextField
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: _getHintColor(),
                fontStyle: FontStyle.italic,
              ),
              filled: true,
              fillColor: _getBackgroundColor(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: _getBorderColor(),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: _getBorderColor(),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: ManifestacaoDesignTokens.colorError,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: ManifestacaoDesignTokens.colorError,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
              counterText: '', // Hide default counter
              errorStyle: const TextStyle(
                fontSize: 12,
                color: ManifestacaoDesignTokens.colorError,
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              color: _getTextColor(),
              height: 1.6,
            ),
            cursorColor: _getBorderColor(),
          ),

          // Custom counter + error message
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Counter
                Text(
                  counter,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getCounterColor(),
                  ),
                ),
                // Error message
                if (widget.errorText != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        widget.errorText!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ManifestacaoDesignTokens.colorError,
                        ),
                        textAlign: TextAlign.right,
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
}
