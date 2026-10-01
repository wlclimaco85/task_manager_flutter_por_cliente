import 'package:flutter/material.dart';
import '../../models/manifestacao/manifestacao_status.dart';
import 'status_dropdown.dart';

/// Wrapper de compatibilidade para StatusDropdownWidget
/// Mantém a interface antiga mas usa o novo widget refatorado
class StatusDropdownWidget extends StatelessWidget {
  final ManifestacaoStatus? value;
  final ValueChanged<ManifestacaoStatus?> onChanged;
  final String? errorText;

  const StatusDropdownWidget({
    Key? key,
    this.value,
    required this.onChanged,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatusDropdown(
      value: value,
      onChanged: onChanged,
      errorText: errorText,
      label: 'Tipo de Manifestação',
    );
  }
}
