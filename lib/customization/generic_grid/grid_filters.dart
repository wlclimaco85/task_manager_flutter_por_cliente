// lib/data/customization/grid_filters.dart
import 'package:flutter/material.dart';
import '../../../utils/app_logger.dart';

import 'grid_models.dart';

class GridFilters extends StatefulWidget {
  final bool enableSearch;
  final Map<String, TextEditingController> filterControllers;
  final TextEditingController searchController;
  final List<FieldConfig> fieldConfigs;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const GridFilters({
    super.key,
    required this.enableSearch,
    required this.filterControllers,
    required this.searchController,
    required this.fieldConfigs,
    required this.onApply,
    required this.onClear,
    required this.onClose,
  });

  @override
  State<GridFilters> createState() => _GridFiltersState();
}

class _GridFiltersState extends State<GridFilters> {
  @override
  void initState() {
    super.initState();
    L.d('[GridFilters] initState');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.filter_alt, color: cs.primary),
              const SizedBox(width: 8),
              Text('Filtros e Busca', style: tt.titleMedium),
              const Spacer(),
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(Icons.close, color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ]),
            const SizedBox(height: 12),
            if (widget.enableSearch) ...[
              Text('Busca Global', style: tt.bodyMedium),
              const SizedBox(height: 8),
              TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Buscar...',
                  suffixIcon: widget.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            widget.searchController.clear();
                            setState(() {});
                            L.d('[GridFilters] search cleared');
                            widget.onApply();
                          },
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
            ],
            Text('Filtros por Campo', style: tt.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: widget.fieldConfigs
                  .where((c) => c.isFilterable)
                  .map((c) => SizedBox(
                        width: 240,
                        child: _FieldFilterTile(
                          config: c,
                          controller: widget.filterControllers[c.fieldName],
                          onChanged: () {
                            L.d('[GridFilters] field "${c.fieldName}" changed');
                            setState(() {});
                          },
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              FilledButton.tonal(
                onPressed: () {
                  L.d('[GridFilters] clear filters');
                  widget.onClear();
                },
                child: const Row(children: [
                  Icon(Icons.clear_all, size: 18),
                  SizedBox(width: 6),
                  Text('Limpar')
                ]),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  L.d('[GridFilters] apply filters');
                  widget.onApply();
                },
                child: const Row(children: [
                  Icon(Icons.check, size: 18),
                  SizedBox(width: 6),
                  Text('Aplicar')
                ]),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _FieldFilterTile extends StatelessWidget {
  final FieldConfig config;
  final TextEditingController? controller;
  final VoidCallback onChanged;

  const _FieldFilterTile({
    required this.config,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? TextEditingController();
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: config.label,
        prefixIcon: Icon(config.icon ?? Icons.filter_list_alt, size: 18),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  ctrl.clear();
                  onChanged();
                },
              )
            : null,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
