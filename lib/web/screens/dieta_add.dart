import 'dart:io';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import '../../models/login_model.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/user_banners.dart';
import '../../../models/auth_utility.dart';
import '../../web/screens/update_profile.dart';
import '../../../widgets/custom_input_form.dart';
import '../../constants/custom_colors.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/personal_validation.dart';
import '../../../widgets/data_picker_core_date.dart';
import '../../../widgets/custom_dieta_box_form.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class DietaModalAdd extends StatefulWidget {
  const DietaModalAdd({super.key});
  @override
  State<DietaModalAdd> createState() => _DietaModalAddState();
}

class _DietaModalAddState extends State<DietaModalAdd> {
  final TextEditingController _nameController = TextEditingController();

  late GlobalKey<FormState> _formKey;
  late FocusNode _focusNode;
  XFile? pickImage;
  String? base64Image;
  bool _signUpInProgress = false;
  final List<Map<String, dynamic>> _dataArrayMain = []; //add this

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

  final TextEditingController _nutricionistaController =
      TextEditingController();
  final TextEditingController _objetivoController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _dtConsultaController = TextEditingController();
  final TextEditingController _dtInicioController = TextEditingController();
  final TextEditingController _dtFinalController = TextEditingController();

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

  Future<String?> uploadPdf(String fileName, File file) async {
    return null;
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
    Data userInfo = AuthUtility.userInfo?.data ?? Data();

    NumberToDieta myObjectInstanced = NumberToDieta();
    List<Map<String, dynamic>> dayNamed = myObjectInstanced.test();

    Map<String, dynamic> af = {};
    af["id"] = userInfo.id;

    Map<String, dynamic> fotos = {};
    af["foto"] = "data:image/png;base64,$base64Imagess";

    Map<String, dynamic> requestBody = {
      "idaluno": af,
      "nutricionista": _nutricionistaController.text.trim(),
      "objetivo": _objetivoController.text.trim(),
      "descricao": _descricaoController.text.trim(),
      "dtConsulta": _dtConsultaController.text.trim(),
      "dtInicio": _dtInicioController.text.trim(),
      "dtFinal": _dtFinalController.text.trim(),
      "fotos": [fotos],
    };

    final NetworkResponse response = await NetworkCaller().postRequest(
      ApiLinks.insertMedicamento,
      requestBody,
    );
    _signUpInProgress = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Exame inserido com Success")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Erro ao inserir Exame")));
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
        chave: value,
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
      appBar: UserBannerAppBar(
        onTapped: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebUpdateProfileScreen(),
            ),
          );
        },
      ),
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
                    keyField: "Nutricionista",
                    controller: _nutricionistaController,
                    onPressed: (vale) => _onUpdate(0, "Nutricionista", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Objetivo",
                    controller: _objetivoController,
                    onPressed: (vale) => _onUpdate(0, "Objetivo", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Descrição",
                    controller: _descricaoController,
                    onPressed: (vale) => _onUpdate(0, "descricao", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Descrição ('Porque do medicamento')",
                    controller: _descricaoController,
                    onPressed: (vale) => _onUpdate(0, "descricao", vale),
                  ),
                  DatePickerExample(labels: "Data Consulta"),
                  DatePickerExample(labels: "Data Ini dieta"),
                  DatePickerExample(labels: "Data Fim dieta"),
                  CustomDietaBoxForm(dataArray: _dataArrayMain),
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
                  pickImage = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );
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
                  pickImage = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (pickImage != null) {
                    setState(() {});
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } else {}
                },
                title: const Text('Gallery'),
              ),
            ],
          ),
        );
      },
    );
  }
}
