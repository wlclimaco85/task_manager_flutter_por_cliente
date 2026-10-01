// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../../constants/custom_colors.dart';

import 'package:dropdown_button2/dropdown_button2.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
final List<Map<String, dynamic>> _dataArray = []; //add this
String? _data = ""; //add this

var dias = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sabado',
  'Domingo',
];

List<String> diasSelectedItems = [];

class GetDiasSemana {
  test() {
    return _dataArray;
  }
}

class CustomDiasBoxForm extends StatefulWidget {
  const CustomDiasBoxForm({super.key});

  @override
  State<CustomDiasBoxForm> createState() => _CustomDiasBoxForm();
}

class _CustomDiasBoxForm extends State<CustomDiasBoxForm> {
  int _formCount = 1; //add this

  late FocusNode _focusNode;

  @override
  void initState() {
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onUpdate(int key, String? value, chave) {
    void addData() {
      Map<String, dynamic> json = {
        'id': key,
        chave: value,
        chave: value,
        chave: value,
        chave: value
      };
      _dataArray.add(json);
      setState(() {
        _data = _dataArray.toString();
      });
    }

    if (_dataArray.isEmpty) {
      addData();
    } else {
      _dataArray.asMap().entries.map((entry) {
        if (entry.key == key && entry.value == chave) {
          _dataArray[key][chave] = value;
        }
        L.d(entry.key);
        L.d(entry.value);
      });

      for (var map in _dataArray) {
        if (map["id"] == key) {
          _dataArray[key][chave] = value;
          setState(() {
            _data = _dataArray.toString();
          });
          break;
        }
      }

      for (var map in _dataArray) {
        if (map["id"] == key) {
          return;
        }
      }
      addData();
    }
  }

  Widget selected(
          int key, String hit, int? maxLine, TextInputType tipo, chave) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  hint: Text(
                    'Escolha Dia Semana',
                    style: TextStyle(
                      fontSize: 14,
                      color: CustomColors().getLightGreenBackground(),
                    ),
                  ),
                  items: dias.map((item) {
                    return DropdownItem(
                      value: item,
                      //disable default onTap to avoid closing menu when selecting an item
                      enabled: false,
                      child: StatefulBuilder(
                        builder: (context, menuSetState) {
                          final isSelected = diasSelectedItems.contains(item);
                          return InkWell(
                            onTap: () {
                              isSelected
                                  ? diasSelectedItems.remove(item)
                                  : diasSelectedItems.add(item);
                              //This rebuilds the StatefulWidget to update the button's text
                              _onUpdate(
                                  key, diasSelectedItems.join(","), chave);
                              setState(() {});
                              //This rebuilds the dropdownMenu Widget to update the check mark
                              menuSetState(() {
                                L.d(item);
                              });
                            },
                            child: Container(
                              height: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  if (isSelected)
                                    const Icon(Icons.check_box_outlined)
                                  else
                                    const Icon(Icons.check_box_outline_blank),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                  //Use last selected item as the current value so if we've limited menu height, it scroll to last item.
                  valueListenable: ValueNotifier<String?>(diasSelectedItems.isEmpty ? null : diasSelectedItems.last),
                  onChanged: (vale) => _onUpdate(key, vale, chave),

                  selectedItemBuilder: (context) {
                    return diasSelectedItems.map(
                      (item) {
                        return Container(
                          alignment: AlignmentDirectional.center,
                          child: Text(
                            diasSelectedItems.join(', '),
                            style: const TextStyle(
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        );
                      },
                    ).toList();
                  },
                  buttonStyleData: ButtonStyleData(
                    height: 50,
                    width: 280,
                    padding: const EdgeInsets.only(left: 14, right: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black26,
                      ),
                      color: CustomColors().getLightGreenBackground(),
                    ),
                    elevation: 2,
                  ),
                  iconStyleData: const IconStyleData(
                    icon: Icon(
                      Icons.arrow_forward_ios_outlined,
                    ),
                    iconSize: 14,
                    iconEnabledColor: Colors.yellow,
                    iconDisabledColor: Colors.grey,
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: CustomColors().getLightGreenBackground(),
                    ),
                    offset: const Offset(-20, 0),
                    scrollbarTheme: ScrollbarThemeData(
                      radius: const Radius.circular(40),
                      thickness: WidgetStateProperty.all(6),
                      thumbVisibility: WidgetStateProperty.all(true),
                    ),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    padding: EdgeInsets.only(left: 14, right: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget imput(int key, String hit, int? maxLine, TextInputType tipo, chave) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
        child: Column(
          children: <Widget>[
            TextFormField(
              //    controller: controller,
              maxLines: maxLine,
              key: Key('$hit ${key + 1}'),
              //    focusNode: _focusNode,
              keyboardType: tipo ?? TextInputType.text,
              decoration: InputDecoration(
                fillColor: CustomColors().getLightGreenBackground(),
                filled: true,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                  borderSide: BorderSide(
                    color: Colors.yellow,
                    width: 3.0,
                  ),
                ),
                labelStyle:
                    const TextStyle(color: Colors.black, fontSize: 16.0),
                hintText: ' $hit ',
              ),
              onChanged: (val) => _onUpdate(key, val, chave),
              //validator: validator,
            ),
          ],
        ),
      );

  Widget form(int key) => Padding(
        padding: const EdgeInsets.only(bottom: 15.0),
        child: Container(
          padding: EdgeInsets.zero,
          color: CustomColors().getLightGreenBackground(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              selected(
                  key, "Titulo Plano", null, TextInputType.text, 'diaAtene'),
              imput(key, "Hora Inicio", null, TextInputType.text, 'dtInicio'),
              imput(key, "Hora Final", null, TextInputType.number, 'dtFinal'),
            ],
          ),
        ),
      );

  Widget buttonRow() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Visibility(
            visible: _formCount > 0,
            child: IconButton(
                onPressed: () {
                  if (_dataArray.isNotEmpty) {
                    _dataArray.removeAt(_dataArray.length - 1);
                  }
                  setState(() {
                    _data = _dataArray.toString();
                    _formCount--;
                  });
                },
                icon: CircleAvatar(
                  backgroundColor: CustomColors().getLightGreenBackground(),
                  child: const Icon(
                    Icons.remove,
                  ),
                )),
          ),
          IconButton(
              onPressed: () {
                setState(() => _formCount++);
              },
              icon: CircleAvatar(
                backgroundColor: CustomColors().getLightGreenBackground(),
                child: const Icon(
                  Icons.add,
                ),
              )),
        ],
      );
  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 19),
              const Text('Horarios',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 22)),
              const SizedBox(height: 20),
              ...List.generate(_formCount, (index) => form(index)),
              buttonRow(),
              const SizedBox(height: 10),
              //   Visibility(visible: _dataArray.isNotEmpty, child: Text(_data!)),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
