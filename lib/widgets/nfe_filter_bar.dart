import 'package:flutter/material.dart';
import 'package:task_manager_flutter/models/nfe/nfe_filter_model.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Barra sticky de filtros para lista de NFes.
/// Permite filtrar por status, data range e ordenação.
class NfeFilterBar extends StatefulWidget {
  final Function(NfeFilterModel) onFilterChanged;

  const NfeFilterBar({
    super.key,
    required this.onFilterChanged,
  });

  @override
  State<NfeFilterBar> createState() => _NfeFilterBarState();
}

class _NfeFilterBarState extends State<NfeFilterBar> {
  late NfeFilterModel _filter;
  final _dateFormatRegex = RegExp(r'(\d{2})/(\d{2})/(\d{4})');

  @override
  void initState() {
    super.initState();
    _filter = NfeFilterModel();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Dropdown
          _buildStatusDropdown(isDark),

          const SizedBox(height: 12),

          // Date Range + Clear
          _buildDateRangeRow(isDark),

          const SizedBox(height: 12),

          // Filtros ativos badge
          if (_filter.hasActiveFilters) _buildActiveFiltersBadge(),
        ],
      ),
    );
  }

  /// Dropdown de status
  Widget _buildStatusDropdown(bool isDark) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Expanded(
          child: DropdownButton<NfeStatusFilter>(
            isExpanded: true,
            value: _filter.status,
            onChanged: (value) {
              if (value != null) {
                _updateFilter(_filter.copyWith(status: value));
              }
            },
            items: NfeStatusFilter.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.label),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Linha de date range + clear
  Widget _buildDateRangeRow(bool isDark) {
    return Row(
      children: [
        // Data Início
        Expanded(
          child: _buildDateField(
            label: 'De',
            value: _filter.dataInicio,
            onChanged: (date) {
              _updateFilter(_filter.copyWith(dataInicio: date));
            },
          ),
        ),
        const SizedBox(width: 12),

        // Data Fim
        Expanded(
          child: _buildDateField(
            label: 'Até',
            value: _filter.dataFim,
            onChanged: (date) {
              _updateFilter(_filter.copyWith(dataFim: date));
            },
          ),
        ),
        const SizedBox(width: 12),

        // Clear button
        if (_filter.dataInicio != null || _filter.dataFim != null)
          SizedBox(
            width: 48,
            child: Tooltip(
              message: 'Limpar datas',
              child: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _updateFilter(_filter.clearDateRange());
                },
                iconSize: 18,
              ),
            ),
          ),
      ],
    );
  }

  /// Campo de data (read-only, abre date picker)
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return TextField(
      readOnly: true,
      onTap: () => _selectDate(context, value, onChanged),
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      controller: TextEditingController(
        text: value != null ? _formatDate(value) : '',
      ),
    );
  }

  /// Date picker
  Future<void> _selectDate(
    BuildContext context,
    DateTime? initialDate,
    Function(DateTime?) onChanged,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  /// Badge de filtros ativos
  Widget _buildActiveFiltersBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF2196F3),
          width: 0.5,
        ),
      ),
      child: Text(
        '${_filter.activeFilterCount} filtro(s) ativo(s)',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2196F3),
        ),
      ),
    );
  }

  /// Atualiza filtro e notifica parent
  void _updateFilter(NfeFilterModel newFilter) {
    L.d('[NfeFilterBar] Filtro atualizado: $newFilter');
    setState(() => _filter = newFilter);
    widget.onFilterChanged(_filter);
  }

  /// Formata DateTime para DD/MM/YYYY
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
