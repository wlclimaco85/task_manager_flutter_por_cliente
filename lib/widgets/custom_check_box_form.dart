import 'package:flutter/material.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
int? selectedOption = 0;

class GetFazAvaliacao {
  test() {
    return selectedOption;
  }
}

class LabeledCheckbox extends StatefulWidget {
  final bool? value;
  final String label;
  final bool leadingCheckbox;
  final ValueChanged<bool?>? onChanged;

  const LabeledCheckbox({
    super.key,
    this.value,
    this.onChanged,
    this.label = '',
    this.leadingCheckbox = true,
  });

  @override
  State<StatefulWidget> createState() => _LabeledCheckboxState();
}

class _LabeledCheckboxState extends State<LabeledCheckbox> {
  var value = false;
  // Set the default value here
  @override
  void initState() {
    super.initState();
    value = widget.value == true;
  }

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[
      _buildCheckbox(context),
    ];
    if (widget.label.isNotEmpty) {
      if (widget.leadingCheckbox) {
        widgets.add(_buildLabel(context));
      } else {
        widgets.insert(0, _buildLabel(context));
      }
    }
    String selectedTransport = '';
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const Text('Faz Avaliação',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 22)),
            Container(
              margin: const EdgeInsets.all(10.0),
              color: Colors.transparent,
              width: 10.0,
              height: 10.0,
            ),
            Expanded(
              child: Card(
                elevation: 5.0, // add this
                child: SizedBox(
                  height: 100,
                  width: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Radio<int>(
                        value: 0,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value;
                            L.d("Selected Option: $selectedOption");
                          });
                        },
                      ),
                      const Text('Sim'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                elevation: 5.0, // add this
                child: Container(
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40.0),
                    topRight: Radius.circular(40.0),
                  )),
                  height: 100,
                  width: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Radio<int>(
                        value: 1,
                        groupValue: selectedOption,
                        onChanged: (int? value) {
                          setState(() {
                            selectedOption = value;
                            L.d("Selected Option: $selectedOption");
                          });
                        },
                      ),
                      const Text('Não'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                elevation: 5.0, // add this
                child: SizedBox(
                  height: 100,
                  width: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Radio<int>(
                        value: 2,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value;
                            L.d("Selected Option: $selectedOption");
                          });
                        },
                      ),
                      const Text(
                        'Apenas Alunos',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: (v) => _onCheckedChanged(),
    );
  }

  Widget _buildLabel(BuildContext context) {
    var padding = widget.leadingCheckbox
        ? const EdgeInsets.only(right: 8)
        : const EdgeInsets.only(left: 8);

    return Padding(
      padding: padding,
      child: Text(widget.label),
    );
  }

  void _onCheckedChanged() {
    setState(() {
      value = !value;
    });
    if (widget.onChanged != null) {
      widget.onChanged!.call(value);
    }
  }
}
