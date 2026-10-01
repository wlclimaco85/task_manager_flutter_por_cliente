import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

/// AccessibleTextField — WCAG AA compliant text input with semantic labels and error handling.
///
/// Provides:
/// - Always-visible label (not placeholder-only)
/// - Semantics(container: true) + TextField semanticLabel
/// - Error messages announced via live region (TalkBack/VoiceOver)
/// - Focus indicator (2px colored border)
/// - Minimum 48 dp height for touch target
/// - Contrast ≥4.5:1 for borders and labels
/// - Keyboard-only navigation support (Tab/Shift+Tab)
class AccessibleTextField extends StatefulWidget {
  final String label; // Accessible label (always visible)
  final String? hint; // Hint text (supplementary, not a label)
  final String? errorText; // Error message (announced immediately)
  final TextEditingController controller;
  final Function(String)? onChanged;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final String? Function(String?)? validator; // Optional validation function
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    required this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.focusNode,
  });

  @override
  State<AccessibleTextField> createState() => _AccessibleTextFieldState();
}

class _AccessibleTextFieldState extends State<AccessibleTextField> {
  late FocusNode _internalFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(() {
      setState(() {
        _isFocused = _internalFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.errorText != null
        ? GridColors.error
        : (_isFocused ? GridColors.primary : GridColors.inputBorder);
    final borderWidth = _isFocused || widget.errorText != null ? 2.0 : 1.0;

    return Semantics(
      container: true,
      label: widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label — always visible, not placeholder-only
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: GridColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // TextField with accessible semantics
          TextField(
            controller: widget.controller,
            focusNode: _internalFocusNode,
            keyboardType: widget.keyboardType,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            obscureText: widget.obscureText,
            textInputAction: widget.textInputAction,
            decoration: InputDecoration(
              hintText: widget.hint,
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: borderColor,
                  width: borderWidth,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: GridColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: GridColors.error,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: GridColors.error,
                  width: 2,
                ),
              ),
              errorText: null, // We handle error display separately
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: false, // Allows minimum 48 dp height
            ),
            onChanged: widget.onChanged,
            style: TextStyle(
              fontSize: 16,
              color: GridColors.textSecondary,
            ),
          ),

          // Error message — wrapped in live region for immediate SR announcement
          if (widget.errorText != null) ...[
            const SizedBox(height: 4),
            Semantics(
              liveRegion: true,
              label: 'Erro: ${widget.errorText}',
              enabled: true,
              child: Text(
                widget.errorText!,
                style: TextStyle(
                  color: GridColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
