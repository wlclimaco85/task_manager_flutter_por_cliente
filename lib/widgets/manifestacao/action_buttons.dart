import 'package:flutter/material.dart';
import '../../screens/nfe/design_tokens.dart';
import '../../core/constants/manifestacao_constants.dart';

/// Tipos de botão de ação
enum ActionButtonType { primary, secondary, danger }

/// Botão de ação com estados (padrão, loading, disabled)
/// Implementa WCAG 2.1 AA: 48×48dp touch target, focus outline, semantic labels
class ActionButton extends StatefulWidget {
  /// Label do botão
  final String label;

  /// Callback ao clicar
  final VoidCallback onPressed;

  /// Tipo de botão (primary, secondary, danger)
  final ActionButtonType type;

  /// Se está em loading
  final bool isLoading;

  /// Se está desabilitado
  final bool isEnabled;

  /// Se deve usar tema dark
  final bool isDarkMode;

  /// Aria-label acessibilidade
  final String? ariaLabel;

  const ActionButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.type = ActionButtonType.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.isDarkMode = false,
    this.ariaLabel,
  }) : super(key: key);

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(ActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _animationController.forward();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < ManifestacaoConstants.breakpointTablet;

    return Semantics(
      label: widget.ariaLabel ?? widget.label,
      button: true,
      enabled: widget.isEnabled && !widget.isLoading,
      child: SizedBox(
        width: isMobile ? double.infinity : null,
        height: ManifestacaoConstants.botaoAltura,
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    return switch (widget.type) {
      ActionButtonType.primary => _buildPrimaryButton(),
      ActionButtonType.secondary => _buildSecondaryButton(),
      ActionButtonType.danger => _buildDangerButton(),
    };
  }

  /// Botão primário (Aceitar/Enviar)
  Widget _buildPrimaryButton() {
    final isDisabled = !widget.isEnabled || widget.isLoading;

    return ElevatedButton(
      onPressed: isDisabled ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFFD32F2F)
            : ManifestacaoDesignTokens.colorPrimary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: ManifestacaoDesignTokens.colorNeutral300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 0,
      ),
      child: widget.isLoading
          ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
          : Text(
            widget.label,
            style: ManifestacaoDesignTokens.textButton.copyWith(
              color: isDisabled ? ManifestacaoDesignTokens.colorNeutral600 : Colors.white,
            ),
          ),
    );
  }

  /// Botão secundário (Recusar)
  Widget _buildSecondaryButton() {
    final isDisabled = !widget.isEnabled || widget.isLoading;
    final corBorda = widget.isDarkMode
        ? const Color(0xFFD32F2F)
        : ManifestacaoDesignTokens.colorPrimary;

    return OutlinedButton(
      onPressed: isDisabled ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDisabled
            ? ManifestacaoDesignTokens.colorNeutral400
            : corBorda,
        side: BorderSide(
          color: isDisabled
              ? ManifestacaoDesignTokens.colorNeutral300
              : corBorda,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        widget.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDisabled
              ? ManifestacaoDesignTokens.colorNeutral600
              : corBorda,
        ),
      ),
    );
  }

  /// Botão de perigo (Limpar/Cancelar)
  Widget _buildDangerButton() {
    final isDisabled = !widget.isEnabled || widget.isLoading;
    final corBorda = ManifestacaoDesignTokens.colorError;

    return OutlinedButton(
      onPressed: isDisabled ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDisabled
            ? ManifestacaoDesignTokens.colorNeutral400
            : corBorda,
        side: BorderSide(
          color: isDisabled
              ? ManifestacaoDesignTokens.colorNeutral300
              : corBorda,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        widget.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDisabled
              ? ManifestacaoDesignTokens.colorNeutral600
              : corBorda,
        ),
      ),
    );
  }
}

/// Widget com grupo de botões responsivo
/// Stack vertical em mobile, horizontal em desktop
class ActionButtonGroup extends StatelessWidget {
  /// Lista de botões a exibir
  final List<ActionButton> buttons;

  /// Se deve usar tema dark
  final bool isDarkMode;

  const ActionButtonGroup({
    Key? key,
    required this.buttons,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < ManifestacaoConstants.breakpointTablet;

    return isMobile
        ? _buildVerticalLayout()
        : _buildHorizontalLayout();
  }

  Widget _buildVerticalLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        buttons.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < buttons.length - 1 ? 8 : 0),
          child: buttons[index],
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        buttons.length,
        (index) => Padding(
          padding: EdgeInsets.only(right: index < buttons.length - 1 ? 12 : 0),
          child: buttons[index],
        ),
      ),
    );
  }
}
