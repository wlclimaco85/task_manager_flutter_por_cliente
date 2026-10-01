import 'package:flutter/material.dart';
import '../../../widgets/localizacao_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/auth_utility.dart';
import '../../models/login_model.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../../services/parceiro_caller.dart';
import '../../../models/parceiro_model.dart';
import '../../constants/custom_colors.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
int idParceiro = AuthUtility.userInfo?.data!.id ?? 0;

class WindowsSignUpScreen extends StatefulWidget {
  const WindowsSignUpScreen({super.key});

  @override
  State<WindowsSignUpScreen> createState() => _WindowsSignUpScreenState();
}

class _WindowsSignUpScreenState extends State<WindowsSignUpScreen> {
  Data userInfo = AuthUtility.userInfo?.data ?? Data();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _codProdutorController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefone1Controller = TextEditingController();
  final TextEditingController _telefone2Controller = TextEditingController();
  final TextEditingController _razaoSocialController = TextEditingController();
  final TextEditingController _incrMunController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _fotoController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmSenhaController = TextEditingController();
  final TextEditingController _parceiroIdController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _senhaVisible = false;
  bool _confirmSenhaVisible = false;

  XFile? pickImage;
  String? base64Image;

  Pais? paisSelecionado;
  Estado? estadoSelecionado;
  Cidade? cidadeSelecionada;

  @override
  void initState() {
    super.initState();
  }

  Future<XFile?> getLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) {
      return null;
    }
    final XFile? files = response.file;
    if (files != null) {
      final XFile? photo = pickImage;
      return files;
    } else {
      L.d(response.exception);
    }
    return null;
  }

  Future<void> sendProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    if (pickImage != null) {
      final bytes = await File(pickImage!.path).readAsBytes();
      base64Image = base64Encode(bytes);
    }

    Map<String, dynamic> requestBody = {
      "id": _parceiroIdController.text.trim(),
      "nome": _nomeController.text.trim(),
      "cpf": _cpfController.text.trim(),
      "codProdutor": _codProdutorController.text.trim(),
      "email": _emailController.text.trim(),
      "telefone1": _telefone1Controller.text.trim(),
      "telefone2": _telefone2Controller.text.trim(),
      "razaoSocial": _razaoSocialController.text.trim(),
      "incrMun": _incrMunController.text.trim(),
      "status": _statusController.text.trim(),
      "foto": base64Image ?? "",
      "endereco": {
        "rua": _ruaController.text.trim(),
        "numero": _numeroController.text.trim(),
        "bairro": _bairroController.text.trim(),
        "pais": {"id": paisSelecionado!.id ?? 0},
        "cidade": {"id": cidadeSelecionada!.id ?? 0},
        "estado": {"id": estadoSelecionado!.id ?? 0},
        "cep": _cepController.text.trim(),
      },
      "senha": _senhaController.text.trim(),
    };

    try {
      bool result = await ParceiroCaller().insertParceiro(context, requestBody);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors().getLightGreenBackground(),
      appBar: AppBar(
        title: const Text("Cadastro Produtores"),
        backgroundColor: CustomColors().getDarkGreenBorder(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextFormField(
                hintText: "Nome",
                controller: _nomeController,
                validator: (value) =>
                    value == null || value.isEmpty ? "Nome obrigatório" : null,
              ),
              CustomTextFormField(
                hintText: "CPF",
                controller: _cpfController,
                validator: (value) =>
                    value == null || value.isEmpty ? "CPF obrigatório" : null,
              ),
              CustomTextFormField(
                hintText: "Email",
                controller: _emailController,
                validator: (value) =>
                    value == null || value.isEmpty ? "Email obrigatório" : null,
              ),
              CustomTextFormField(
                hintText: "Telefone",
                controller: _telefone1Controller,
                validator: (value) => value == null || value.isEmpty
                    ? "Telefone obrigatório"
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                hintText: "Telefone2",
                controller: _telefone2Controller,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                hintText: "Cod. Produtor",
                controller: _codProdutorController,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                hintText: "Razão Social",
                controller: _razaoSocialController,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: imagePicked,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: const Text("Photos"),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CustomColors().getDarkGreenBorder(),
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
              const SizedBox(height: 16),
              CustomTextFormField(
                hintText: "Inscr. Municipal",
                controller: _incrMunController,
              ),
              CustomTextFormField(
                hintText: "CEP",
                controller: _cepController,
                validator: (value) =>
                    value == null || value.isEmpty ? "CEP obrigatório" : null,
              ),
              CustomTextFormField(
                hintText: "Rua",
                controller: _ruaController,
                validator: (value) =>
                    value == null || value.isEmpty ? "Rua obrigatória" : null,
              ),
              CustomTextFormField(
                hintText: "Número",
                controller: _numeroController,
                validator: (value) => value == null || value.isEmpty
                    ? "Número obrigatório"
                    : null,
              ),
              const SizedBox(height: 16),
              LocalizacaoWidget(
                required: true,
                onChanged: (pais, estado, cidade) {
                  paisSelecionado = pais;
                  estadoSelecionado = estado;
                  cidadeSelecionada = cidade;
                },
              ),
              const SizedBox(height: 16),
              CustomPasswordTextFormField(
                hintText: "Senha",
                controller: _senhaController,
                obscureText: !_senhaVisible,
                togglePasswordVisibility: () {
                  setState(() {
                    _senhaVisible = !_senhaVisible;
                  });
                },
              ),
              CustomPasswordTextFormField(
                hintText: "Repetir Senha",
                controller: _confirmSenhaController,
                obscureText: !_confirmSenhaVisible,
                togglePasswordVisibility: () {
                  setState(() {
                    _confirmSenhaVisible = !_confirmSenhaVisible;
                  });
                },
                validator: (value) {
                  if (value != _senhaController.text) {
                    return "As senhas não coincidem";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : sendProfileData,
        label: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Gravar'),
        icon: const Icon(Icons.save),
        backgroundColor: _isSubmitting ? Colors.grey : Colors.green,
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
                  }
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
                  }
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

class CustomTextFormField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const CustomTextFormField({
    super.key,
    required this.hintText,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: CustomColors().getDarkGreenBorder(),
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: CustomColors().getDarkGreenBorder(),
              width: 2.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: CustomColors().getDarkGreenBorder(),
              width: 2.0,
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }
}

class CustomPasswordTextFormField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback togglePasswordVisibility;
  final FormFieldValidator<String>? validator;

  const CustomPasswordTextFormField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.obscureText,
    required this.togglePasswordVisibility,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: CustomColors().getDarkGreenBorder(),
              width: 2.0,
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: togglePasswordVisibility,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
