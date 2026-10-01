import 'package:flutter/material.dart';
import '../../widgets/user_banners.dart';
import '../../services/network_caller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../utils/grid_colors.dart'; // ★ adicionado para aplicar o tema
import '../../../utils/api_links.dart';

class UserEditScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const UserEditScreen({super.key, required this.initialData});

  @override
  _UserEditScreenState createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  // Controladores para os campos do formulário
  late TextEditingController _nomeController;
  late TextEditingController _cpfController;
  late TextEditingController _telefoneController;
  late TextEditingController _logradouroController;
  late TextEditingController _numeroController;
  late TextEditingController _cepController;
  late TextEditingController _bairroController;
  late TextEditingController _cidadeController;
  late TextEditingController _estadoController;
  late TextEditingController _paisController;
  late TextEditingController _emailController;
  late TextEditingController _incrMunController;
  late TextEditingController _razaoSocialController;

  @override
  void initState() {
    super.initState();
    // Inicializa os controladores com os dados iniciais
    _nomeController =
        TextEditingController(text: widget.initialData['nome'] ?? '');
    _cpfController =
        TextEditingController(text: widget.initialData['cpf'] ?? '');
    _telefoneController =
        TextEditingController(text: widget.initialData['telefone1'] ?? '');
    _logradouroController =
        TextEditingController(text: widget.initialData['logradouro'] ?? '');
    _numeroController =
        TextEditingController(text: widget.initialData['numero'] ?? '');
    _cepController =
        TextEditingController(text: widget.initialData['cep'] ?? '');
    _bairroController =
        TextEditingController(text: widget.initialData['bairro'] ?? '');
    _cidadeController =
        TextEditingController(text: widget.initialData['cidade'] ?? '');
    _estadoController =
        TextEditingController(text: widget.initialData['estado'] ?? '');
    _paisController =
        TextEditingController(text: widget.initialData['pais'] ?? '');
    _emailController =
        TextEditingController(text: widget.initialData['email'] ?? '');
    _incrMunController =
        TextEditingController(text: widget.initialData['incrMun'] ?? '');
    _razaoSocialController =
        TextEditingController(text: widget.initialData['razaoSocial'] ?? '');
  }

  @override
  void dispose() {
    // Dispose dos controladores
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _cepController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _paisController.dispose();
    _emailController.dispose();
    _incrMunController.dispose();
    _razaoSocialController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Verifica o tamanho do arquivo (limite de 2MB)
        final fileSize = await file.length();
        if (fileSize > 2 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A imagem deve ter no máximo 2MB'),
              backgroundColor: GridColors.error,
            ),
          );
          return;
        }

        setState(() {
          _selectedImage = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: GridColors.dialogBackground,
          title: const Text(
            'Selecionar imagem',
            style: TextStyle(color: GridColors.textSecondary),
          ),
          content: const Text(
            'Escolha a fonte da imagem',
            style: TextStyle(color: GridColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: const Text(
                'Câmera',
                style: TextStyle(color: GridColors.primary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: const Text(
                'Galeria',
                style: TextStyle(color: GridColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // Mostra loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(GridColors.primary),
          ),
        ),
      );

      try {
        // Prepara os dados para envio
        final Map<String, dynamic> requestData = {
          'id': widget.initialData['id'],
          'nome': _nomeController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'telefone1': _telefoneController.text.trim(),
          'endereco': {
            'logradouro': _logradouroController.text.trim(),
            'numero': _numeroController.text.trim(),
            'cep': _cepController.text.trim(),
            'bairro': _bairroController.text.trim(),
            'cidade': {"nome": _cidadeController.text.trim()},
            'estado': {"nome": _estadoController.text.trim()},
            'pais': {"nome": _paisController.text.trim()},
          },
          'email': _emailController.text.trim(),
          'incrMun': _incrMunController.text.trim(),
          'razaoSocial': _razaoSocialController.text.trim(),
          'photo': _selectedImage != null
              ? _selectedImage!.path
              : widget.initialData['photo'],
        };

        // Faz a chamada POST para atualizar o usuário
        final response = await NetworkCaller().postRequest(
          ApiLinks.atualizarUsuario(
              widget.initialData['id']), // Ajuste a URL conforme sua API
          requestData,
        );

        // Fecha o loading
        Navigator.pop(context);

        if (response.isSuccess) {
          Navigator.pop(context, requestData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: GridColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar: $response'),
              backgroundColor: GridColors.error,
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: GridColors.error,
          ),
        );
      }
    }
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: GridColors.inputBackground,
          borderRadius: BorderRadius.circular(60),
          border: Border.all(color: GridColors.inputBorder, width: 2),
        ),
        child: Stack(
          children: [
            if (_selectedImage != null)
              ClipOval(
                child: Image.file(
                  _selectedImage!,
                  width: 116,
                  height: 116,
                  fit: BoxFit.cover,
                ),
              )
            else if (widget.initialData['photo'] != null &&
                widget.initialData['photo']!.isNotEmpty)
              ClipOval(
                child: Image.network(
                  widget.initialData['photo']!,
                  width: 116,
                  height: 116,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person,
                        size: 50, color: GridColors.primary);
                  },
                ),
              )
            else
              const Icon(Icons.person, size: 50, color: GridColors.primary),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: GridColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                    const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: GridColors.textSecondary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: GridColors.textSecondary),
        filled: true,
        fillColor: GridColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GridColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GridColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GridColors.inputBorder),
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Este campo é obrigatório';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: UserBannerAppBar(
        screenTitle: 'Editar Perfil',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Seção da Foto
              Column(
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 8),
                  const Text(
                    'Clique na imagem para alterar',
                    style: TextStyle(
                      color: GridColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Formulário
              Card(
                color: GridColors.card,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Dados Pessoais
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Dados Pessoais',
                          style: TextStyle(
                            color: GridColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Nome *',
                        controller: _nomeController,
                        required: true,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'CPF',
                        controller: _cpfController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Telefone',
                        controller: _telefoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 24),

                      // Endereço
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Endereço',
                          style: TextStyle(
                            color: GridColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Logradouro',
                        controller: _logradouroController,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              label: 'Número',
                              controller: _numeroController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              label: 'CEP',
                              controller: _cepController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Bairro',
                        controller: _bairroController,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              label: 'Cidade',
                              controller: _cidadeController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              label: 'Estado',
                              controller: _estadoController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'País',
                        controller: _paisController,
                      ),

                      const SizedBox(height: 24),

                      // Dados Adicionais
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Dados Adicionais',
                          style: TextStyle(
                            color: GridColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'Inscrição Municipal',
                        controller: _incrMunController,
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        label: 'Razão Social',
                        controller: _razaoSocialController,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.buttonBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'SALVAR ALTERAÇÕES',
                    style: TextStyle(
                      color: GridColors.buttonText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
