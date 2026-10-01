import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

/// AccessibleButton — WCAG AA compliant button with semantic labels and focus management.
///
/// Provides:
/// - Semantics(button: true) for screen reader support
/// - Minimum 48×48 dp touch target
/// - Contrast ≥4.5:1 with GridColors palette
/// - Focus indicator (2px colored border)
/// - Keyboard activation (Enter, Space)
/// - Disabled state with visual indication
class AccessibleButton extends StatefulWidget {
  final String label; // User-facing label + semantic label for SR
  final String? hint; // Optional additional context for SR (longer explanation)
  final VoidCallback onPressed;
  final bool isEnabled;
  final Color backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isDestructive; // If true, announces as "destructive action"

  const AccessibleButton({
    super.key,
    required this.label,
    this.hint,
    required this.onPressed,
    this.isEnabled = true,
    this.backgroundColor = GridColors.primary,
    this.textColor = Colors.white,
    this.width,
    this.height = 48,
    this.isDestructive = false,
  });

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semanticLabel =
        widget.isDestructive ? 'Ação perigosa: ${widget.label}' : widget.label;

    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      label: semanticLabel,
      hint: widget.hint,
      onTap: widget.isEnabled ? widget.onPressed : null,
      focusable: widget.isEnabled,
      focused: _isFocused,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: _isFocused
              ? Border.all(
                  color: widget.backgroundColor,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ExcludeSemantics(
          child: ElevatedButton(
            focusNode: _focusNode,
            onPressed: widget.isEnabled ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor,
              disabledBackgroundColor: widget.backgroundColor.withOpacity(0.5),
              padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14), // CR-03: +2dp vertical safety margin
              minimumSize:
                  Size(48, 48), // Explicit minimum to prevent height drop
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
