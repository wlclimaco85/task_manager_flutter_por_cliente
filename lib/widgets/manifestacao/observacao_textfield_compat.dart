import 'package:flutter/material.dart';
import 'observacao_textfield.dart';

/// Wrapper de compatibilidade para ObservacaoTextfieldWidget
/// Mantém a interface antiga (value, onChanged) mas usa o novo widget refatorado
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
  void didUpdateWidget(ObservacaoTextfieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ObservacaoTextfield(
      controller: _controller,
      label: widget.required ? 'Observações *' : 'Observações',
      maxLength: widget.maxCharacters,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
    );
  }
}
