import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/user_banners.dart';
import '../../web/screens/update_profile.dart';
import '../../../widgets/custom_input_form.dart';
import '../../constants/custom_colors.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/personal_validation.dart';
import '../../models/login_model.dart';
import '../../../models/auth_utility.dart';
import 'dart:io';


import 'package:task_manager_flutter/utils/app_logger.dart';
class MedicamentosModalAdd extends StatefulWidget {
  const MedicamentosModalAdd({super.key});
  @override
  State<MedicamentosModalAdd> createState() => _MedicamentosModalAddState();
}

class _MedicamentosModalAddState extends State<MedicamentosModalAdd> {
  final TextEditingController _nameController = TextEditingController();

  late GlobalKey<FormState> _formKey;
  late FocusNode _focusNode;
  XFile? pickImage;
  String? base64Image;
  bool _signUpInProgress = false;

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

  final TextEditingController _medicamentoController = TextEditingController();
  final TextEditingController _laboratorioController = TextEditingController();
  final TextEditingController _medicoReceitouController =
      TextEditingController();
  final TextEditingController _dosagemController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
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
    Data userInfo = AuthUtility.userInfo?.data! ?? Data();

    Map<String, dynamic> af = {};
    af["id"] = userInfo.id;

    Map<String, dynamic> fotos = {};
    af["foto"] = "data:image/png;base64,$base64Imagess";

    Map<String, dynamic> requestBody = {
      "idaluno": af,
      "medicamento": _medicamentoController.text.trim(),
      "laboratorio": _laboratorioController.text.trim(),
      "medicoReceitou": _medicoReceitouController.text.trim(),
      "dosagem": _dosagemController.text.trim(),
      "descricao": _descricaoController.text.trim(),
      "observacao": _observacaoController.text.trim(),
      "valor": _valorController.text.trim(),
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
                    keyField: "Medicamanto",
                    controller: _medicamentoController,
                    onPressed: (vale) => _onUpdate(0, "Nome", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Nome Laboratorio",
                    controller: _laboratorioController,
                    onPressed: (vale) => _onUpdate(0, "laboratorio", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Nome Medico que receitou",
                    controller: _medicoReceitouController,
                    onPressed: (vale) => _onUpdate(0, "laboratorio", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Descrição ('Porque do medicamento')",
                    controller: _descricaoController,
                    onPressed: (vale) => _onUpdate(0, "descricao", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Dosagem",
                    controller: _dosagemController,
                    onPressed: (vale) => _onUpdate(0, "resultado", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Observações",
                    controller: _observacaoController,
                    onPressed: (vale) => _onUpdate(0, "dtExame", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.number,
                    keyField: "Valor",
                    controller: _valorController,
                    onPressed: (vale) => _onUpdate(0, "dtExame", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.datetime,
                    keyField: "Data de quando começou a tomar",
                    controller: _dtInicioController,
                    onPressed: (vale) =>
                        _onUpdate(0, "dtEntregaResulExame", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.datetime,
                    keyField: "Data de quando terminou de tomar",
                    controller: _dtFinalController,
                    onPressed: (vale) => _onUpdate(0, "medico", vale),
                  ),
                  InkWell(
                    onTap: () {
                      imagePicked();
                    },
                    child: Row(
                      children: [
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
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
