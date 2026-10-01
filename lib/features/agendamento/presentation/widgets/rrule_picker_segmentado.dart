import 'package:flutter/material.dart';

/// Widget de picker segmentado para RRULE (RFC 5545)
class RrulePickerSegmentado extends StatefulWidget {
  final Function(String) onRruleChanged;

  const RrulePickerSegmentado({
    Key? key,
    required this.onRruleChanged,
  }) : super(key: key);

  @override
  State<RrulePickerSegmentado> createState() => _RrulePickerSegmentadoState();
}

class _RrulePickerSegmentadoState extends State<RrulePickerSegmentado> {
  String _freq = 'DAILY';
  List<String> _byday = [];
  int _bymonthday = 1;

  String _buildRrule() {
    String rrule = 'FREQ=$_freq';

    if (_byday.isNotEmpty) {
      rrule += ';BYDAY=${_byday.join(',')}';
    }

    if (_freq == 'MONTHLY' && _bymonthday > 0) {
      rrule += ';BYMONTHDAY=$_bymonthday';
    }

    return rrule;
  }

  void _notifyChange() {
    widget.onRruleChanged(_buildRrule());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frequency Selector
        Text(
          'Frequência',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'DAILY', label: Text('Diariamente')),
            ButtonSegment(value: 'WEEKLY', label: Text('Semanalmente')),
            ButtonSegment(value: 'MONTHLY', label: Text('Mensalmente')),
            ButtonSegment(value: 'YEARLY', label: Text('Anualmente')),
          ],
          selected: {_freq},
          onSelectionChanged: (selected) {
            setState(() {
              _freq = selected.first;
              _byday.clear(); // Reset BYDAY ao mudar frequência
              _bymonthday = 1;
            });
            _notifyChange();
          },
        ),
        const SizedBox(height: 24),

        // BYDAY picker (para WEEKLY)
        if (_freq == 'WEEKLY') _buildBydayPicker(context),

        // BYMONTHDAY picker (para MONTHLY)
        if (_freq == 'MONTHLY') _buildBymonthdayPicker(context),

        const SizedBox(height: 16),
        Text(
          'RRULE Gerada:',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SelectableText(
            _buildRrule(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBydayPicker(BuildContext context) {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    const dayLabels = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dias da Semana',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(
            days.length,
            (index) => FilterChip(
              label: Text(dayLabels[index]),
              selected: _byday.contains(days[index]),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _byday.add(days[index]);
                  } else {
                    _byday.remove(days[index]);
                  }
                });
                _notifyChange();
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBymonthdayPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dia do Mês',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _bymonthday.toDouble(),
                min: 1,
                max: 31,
                divisions: 30,
                label: 'Dia $_bymonthday',
                onChanged: (value) {
                  setState(() {
                    _bymonthday = value.toInt();
                  });
                  _notifyChange();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Dia $_bymonthday',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
