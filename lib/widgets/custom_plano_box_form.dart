// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../../constants/custom_colors.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
final List<Map<String, dynamic>> _dataArray = []; //add this
String? _data = ""; //add this

class NumberToDay {
  test() {
    return _dataArray;
  }
}

class CustomComboBoxForm extends StatefulWidget {
  const CustomComboBoxForm({super.key});

  @override
  State<CustomComboBoxForm> createState() => _CustomComboBoxForm();
}

class _CustomComboBoxForm extends State<CustomComboBoxForm> {
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

  void _onUpdate(int key, String value, chave) {
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
                labelStyle: const TextStyle(color: Colors.red, fontSize: 16.0),
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
              imput(key, "Titulo Plano", null, TextInputType.text, 'nome'),
              imput(key, "Detalhe do Plano", 5, TextInputType.multiline,
                  'descricao'),
              imput(key, "Qnt. Aula Mês *dias", null, TextInputType.number,
                  'qtdAula'),
              imput(key, "Valor Plano", null, TextInputType.number, 'valor'),
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
              const Text('Planos',
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
