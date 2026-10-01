import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/user_banners.dart';
import '../../mobile/screens/update_profile.dart';
import '../../../widgets/custom_input_form.dart';
import '../../constants/custom_colors.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/personal_validation.dart';
import '../../../widgets/custom_plano_box_form.dart';
import '../../../widgets/custom_check_box_form.dart';
import '../../../widgets/custom_horario_box_form.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class HomeModalAdd extends StatefulWidget {
  const HomeModalAdd({super.key});
  @override
  State<HomeModalAdd> createState() => _HomeModalAddState();
}

class _HomeModalAddState extends State<HomeModalAdd> {
  final TextEditingController _nameController = TextEditingController();

  late GlobalKey<FormState> _formKey;
  late FocusNode _focusNode;
  XFile? pickImage;
  String? base64Image;
  bool _signUpInProgress = false;
  // List of items in our dropdown menu
  var sexo = [
    'Masculino',
    'Feminino',
  ];

  List<String> sexoSelectedItems = [];

  @override
  void initState() {
    _formKey = GlobalKey<FormState>();
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numCPFController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _numCREFController = TextEditingController();
  final TextEditingController _vlrAulaController = TextEditingController();

  Future<List<int>> getLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    final XFile? files = response.file;
    final XFile? photo;
    if (files != null) {
      photo = pickImage;
      return files.readAsBytes();
    } else {
      const asciiDecoder = AsciiDecoder();
      final asciiValues = [104, 101, 108, 108, 111];
      return asciiValues;
      L.d(response.exception);
    }
  }

  String MapToJson(List<Map<String, dynamic>> map) {
    String res = "";
    bool isEntrou = false;
    for (var s in map) {
      res += "{";

      for (String k in s.keys) {
        //"[{"id":"0","diaAtene":"Segunda,Segunda,Terça","dtInicio":"10:00"
        res += '"';
        res += k;
        res += '":"';
        res += (k == "diaAtene"
            ? getChaveDiasSemana(s[k].toString())
            : s[k].toString());
        res += '",';
      }
      res = res.substring(0, res.length - 1);

      res += "},";
      isEntrou = true;
    }
    if (isEntrou) {
      res = "[${res.substring(0, res.length - 1)}]";
    } else {
      res = "";
    }

    return res;
  }

  int diasSemanaEnum(String diasd) {
    late int dias;
    switch (diasd) {
      case "Segunda":
        dias = 9;
        break;
      case "Terça":
        dias = 1;
        break;
      case "Quarta":
        dias = 2;
        break;
      case "Quinta":
        dias = 3;
        break;
      case "Sexta":
        dias = 4;
        break;
      case "Sabado":
        dias = 5;
        break;
      case "Domingo":
        dias = 6;
        break;
      case "Feriado":
        dias = 7;
        break;
      default:
        dias = 8;
        break;
    }
    return dias;
  }

  int sexoEnum(String diasd) {
    late int dias;
    switch (diasd) {
      case "Masculino":
        dias = 0;
        break;
      case "Feminino":
        dias = 1;
        break;
      default:
        dias = 3;
        break;
    }
    return dias;
  }

  int getChaveSexo(String disas) {
    late int diasSemana = 3;
    late List<String> aa = disas.split(",");
    if (aa.length > 1) {
      return 2;
    }
    for (var element in aa) {
      diasSemana = sexoEnum(element);
    }

    return diasSemana;
  }

  String getChaveDiasSemana(String disas) {
    late String diasSemana = "";
    late List<String> aa = disas.split(",");
    late bool entrou = false;
    for (var element in aa) {
      diasSemana += "${diasSemanaEnum(element)},";
      entrou = true;
    }
    if (entrou) {
      diasSemana = diasSemana.substring(0, diasSemana.length - 1);
    } else {
      diasSemana = "";
    }

    return diasSemana.replaceAll(",", "");
  }

  Future<void> updateProfile() async {
    _signUpInProgress = true;
    if (mounted) {
      setState(() {});
    }
    String base64Imagess = "";
    if (pickImage != null) {
      // var bytes = File(pickImage!.path).readAsBytesSync();
      // String base64Image = base64Encode(bytes);
      L.d('upload proccess started');
      final bytess = io.File(pickImage!.path).readAsBytesSync();
      //  List<int> imageBytes = pickImage?.readAsBytesSync();
      // L.d(imageBytes);
      //String base64Images = base64Encode(imageBytes);
      base64Imagess = base64Encode(bytess);
    }
    NumberToDay myObjectInstance = NumberToDay();
    List<Map<String, dynamic>> dayName = myObjectInstance.test();

    String aa = MapToJson(dayName);

    GetDiasSemana myObjectInstances = GetDiasSemana();
    List<Map<String, dynamic>> dayNames = myObjectInstances.test();

    GetFazAvaliacao myObjectInstancesd = GetFazAvaliacao();
    int fazAval = myObjectInstancesd.test();
    String bb = MapToJson(dayNames);

    Map<String, dynamic> requestBody = {
      "cref": _numCREFController.text.trim(),
      "vlrAula": _vlrAulaController.text.trim(),
      "fazAvaliacao": fazAval,
      "sexoAtendimento": sexoSelectedItems.isNotEmpty
          ? getChaveSexo(sexoSelectedItems.join(', ').toString())
          : "",
      "codDadosPessoal": {
        "nome": _nomeController.text.trim(),
        "cpf": _numCPFController.text.trim(),
        "telefone1": _telefoneController.text.trim(),
        "email": _emailController.text.trim(),
        "tipoAluno": 2,
        "photo": "data:image/png;base64,$base64Imagess",
      },
      "planos": jsonDecode(aa),
      "horarios": jsonDecode(bb),
      /* {
          "titulo": "titulo",
          "descricao": "descricao",
          "qtdAula": 1,
          "valor": 1.99,
        }*/
    };
    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.insertPersonal, requestBody);
    _signUpInProgress = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile update Successful"),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile update Failed"),
          ),
        );
      }
    }
  }

  final List<Map<String, dynamic>> _dataArray = []; //add this
  String? _data = ""; //add this
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserBannerAppBar(onTapped: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const UpdateProfileScreen()));
      }),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            alignment: Alignment.topCenter,
            color: CustomColors().getLightGreenBackground(),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Nome",
                    controller: _nomeController,
                    onPressed: (vale) => _onUpdate(0, "Nome", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.number,
                    keyField: "Email",
                    controller: _emailController,
                    onPressed: (vale) => _onUpdate(0, "Email", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.number,
                    keyField: "CPF",
                    controller: _numCPFController,
                    onPressed: (vale) => _onUpdate(0, "CPF", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.number,
                    keyField: "Telefone",
                    controller: _telefoneController,
                    onPressed: (vale) => _onUpdate(0, "TELEFONE", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.number,
                    keyField: "Numero CREF",
                    controller: _numCREFController,
                    onPressed: (vale) => _onUpdate(0, "CREF", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.number,
                    keyField: "Vlr Aula",
                    controller: _vlrAulaController,
                    onPressed: (vale) => _onUpdate(0, "VLRAULA", vale),
                  ),
                  InkWell(
                    onTap: () {
                      imagePicked();
                    },
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: const Text("Foto"),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: CustomColors().getLightGreenBackground(),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            pickImage?.name ?? "",
                            maxLines: 1,
                            style: const TextStyle(
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const LabeledCheckbox(
                      value: true,
                      label: "Sim",
                      leadingCheckbox: false,
                      onChanged: null),
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
                                'Escolha o sexo atendimento',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      CustomColors().getLightGreenBackground(),
                                ),
                              ),
                              items: sexo.map((item) {
                                return DropdownItem(
                                  value: item,
                                  //disable default onTap to avoid closing menu when selecting an item
                                  enabled: false,
                                  child: StatefulBuilder(
                                    builder: (context, menuSetState) {
                                      final isSelected =
                                          sexoSelectedItems.contains(item);
                                      return InkWell(
                                        onTap: () {
                                          isSelected
                                              ? sexoSelectedItems.remove(item)
                                              : sexoSelectedItems.add(item);
                                          //This rebuilds the StatefulWidget to update the button's text
                                          setState(() {});
                                          //This rebuilds the dropdownMenu Widget to update the check mark
                                          menuSetState(() {});
                                        },
                                        child: Container(
                                          height: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: Row(
                                            children: [
                                              if (isSelected)
                                                const Icon(
                                                    Icons.check_box_outlined)
                                              else
                                                const Icon(Icons
                                                    .check_box_outline_blank),
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
                              valueListenable: ValueNotifier<String?>(sexoSelectedItems.isEmpty ? null : sexoSelectedItems.last),
                              onChanged: (value) {},
                              selectedItemBuilder: (context) {
                                return sexoSelectedItems.map(
                                  (item) {
                                    return Container(
                                      alignment: AlignmentDirectional.center,
                                      child: Text(
                                        sexoSelectedItems.join(', '),
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
                                padding:
                                    const EdgeInsets.only(left: 14, right: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.black26,
                                  ),
                                  color:
                                      CustomColors().getLightGreenBackground(),
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
                                  color:
                                      CustomColors().getLightGreenBackground(),
                                ),
                                offset: const Offset(-20, 0),
                                scrollbarTheme: ScrollbarThemeData(
                                  radius: const Radius.circular(40),
                                  thickness: WidgetStateProperty.all(6),
                                  thumbVisibility:
                                      WidgetStateProperty.all(true),
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
                  ),
                  const CustomComboBoxForm(),
                  const CustomDiasBoxForm(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final form = _formKey.currentState!;
          form.validate();
          _focusNode.requestFocus();
          updateProfile();
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  void imagePicked() async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pick Image From:'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  onTap: () async {
                    pickImage = await ImagePicker()
                        .pickImage(source: ImageSource.camera);
                    if (pickImage != null) {
                      setState(() {});
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } else {}
                  },
                  leading: const Icon(Icons.camera),
                  title: const Text('Camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  onTap: () async {
                    pickImage = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (pickImage != null) {
                      setState(() {});
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } else {}
                  },
                  title: const Text('Gallery'),
                )
              ],
            ),
          );
        });
  }
}
