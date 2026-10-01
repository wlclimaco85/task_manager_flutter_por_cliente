import 'package:flutter/material.dart';
import '../../models/manifestacao/manifestacao_status.dart';
import '../../screens/nfe/design_tokens.dart';
import '../../core/constants/manifestacao_constants.dart';

/// Dropdown para seleção de status de manifestação
/// Implementa WCAG 2.1 AA: focus outline, semantic labels, 48dp touch target
class StatusDropdown extends StatefulWidget {
  /// Status selecionado
  final ManifestacaoStatus? value;

  /// Callback ao selecionar
  final ValueChanged<ManifestacaoStatus?> onChanged;

  /// Mensagem de erro
  final String? errorText;

  /// Se deve usar tema dark
  final bool isDarkMode;

  /// Se está desabilitado
  final bool isEnabled;

  /// Label do campo
  final String label;

  const StatusDropdown({
    Key? key,
    this.value,
    required this.onChanged,
    this.errorText,
    this.isDarkMode = false,
    this.isEnabled = true,
    this.label = 'Tipo de Manifestação',
  }) : super(key: key);

  @override
  State<StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<StatusDropdown> {
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
    if (!widget.isEnabled) {
      return widget.isDarkMode
          ? const Color(0xFF151515)
          : ManifestacaoDesignTokens.colorNeutral200;
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
    if (!widget.isEnabled) {
      return widget.isDarkMode
          ? const Color(0xFF808080)
          : ManifestacaoDesignTokens.colorNeutral600;
    }
    return widget.isDarkMode
        ? const Color(0xFFF0F0F0)
        : ManifestacaoDesignTokens.colorNeutral900;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      enabled: widget.isEnabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(),
                    ),
                  ),
                  if (widget.value == null)
                    Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 14,
                        color: ManifestacaoDesignTokens.colorError,
                      ),
                    ),
                ],
              ),
            ),

          // Dropdown
          Container(
            height: ManifestacaoConstants.botaoAltura,
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              border: Border.all(
                color: _getBorderColor(),
                width: widget.errorText != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<ManifestacaoStatus>(
              value: widget.value,
              isExpanded: true,
              onChanged: widget.isEnabled ? widget.onChanged : null,
              focusNode: _focusNode,
              underline: const SizedBox(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              style: TextStyle(
                fontSize: 14,
                color: _getTextColor(),
                fontWeight: FontWeight.w400,
              ),
              dropdownColor: widget.isDarkMode
                  ? const Color(0xFF1F1F1F)
                  : ManifestacaoDesignTokens.colorNeutral50,
              icon: Icon(
                Icons.arrow_drop_down,
                color: _getTextColor(),
                size: 24,
              ),
              items: ManifestacaoStatus.values
                  .map((status) => DropdownMenuItem<ManifestacaoStatus>(
                    value: status,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _getIconForStatus(status),
                            size: 16,
                            color: _getColorForStatus(status),
                          ),
                          const SizedBox(width: 8),
                          Text(status.label),
                        ],
                      ),
                    ),
                  ))
                  .toList(),
            ),
          ),

          // Error message
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.errorText!,
                style: const TextStyle(
                  fontSize: 12,
                  color: ManifestacaoDesignTokens.colorError,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Retorna ícone para status
  IconData _getIconForStatus(ManifestacaoStatus status) {
    return switch (status) {
      ManifestacaoStatus.aceitar => Icons.check_circle_outline,
      ManifestacaoStatus.parcial => Icons.assignment_late,
      ManifestacaoStatus.recusar => Icons.cancel_outlined,
    };
  }

  /// Retorna cor para status
  Color _getColorForStatus(ManifestacaoStatus status) {
    return switch (status) {
      ManifestacaoStatus.aceitar => ManifestacaoDesignTokens.colorSuccess,
      ManifestacaoStatus.parcial => ManifestacaoDesignTokens.colorWarning,
      ManifestacaoStatus.recusar => ManifestacaoDesignTokens.colorError,
    };
  }
}
