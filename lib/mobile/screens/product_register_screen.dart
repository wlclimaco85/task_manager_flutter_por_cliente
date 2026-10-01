import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/venda_model.dart';
import '../../services/vendas_caller.dart';
import '../../services/parceiro_caller.dart';
import '../../../models/parceiro_model.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../constants/custom_colors.dart';
import '../../../models/auth_utility.dart';
import '../screens/update_profile.dart';
import '../../../widgets/user_banners.dart';
import '../../../utils/showSnackBar.dart';

class ProductRegisterScreen extends StatefulWidget {
  const ProductRegisterScreen({super.key});

  @override
  _ProductRegisterScreenState createState() => _ProductRegisterScreenState();
}

class _ProductRegisterScreenState extends State<ProductRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  bool isSubmitting = false;

  bool useCustomAddress = false;
  bool isCargaFechada = false;

  String selectedTipoProduto = "Arroz em Casca";
  String selectedTipoGrao = "Verde";
  String selectedSafra = "2023/2024"; // Novo campo
  String selectedTipoNegociacao =
      "Adicionar valor e aceitar propostas"; // Novo campo
  DateTime? dtRetirada;
  final TextEditingController dtRetiradaController = TextEditingController();
  final TextEditingController sementeController =
      TextEditingController(); // Novo campo

  String vendedorEndereco = '';
  List<Map<String, dynamic>> classificacoes = [];
  List<File> selectedImages = [];
  File? principalImage;

  final TextEditingController qtdSacosController = TextEditingController();
  final TextEditingController vlrSacosController = TextEditingController();
  final List<TextEditingController> classificacaoControllers = [];

  // Campos para endereço customizado
  final TextEditingController ruaController = TextEditingController();
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController bairroController = TextEditingController();
  final TextEditingController cidadeController = TextEditingController();
  final TextEditingController estadoController = TextEditingController();
  final TextEditingController cepController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null).then((_) {
      fetchInitialData();
    });
  }

  Future<void> fetchInitialData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<Parceiro> parceiroData = await ParceiroCaller()
          .fetchParceiros(context, AuthUtility.userInfo?.data?.id ?? 0);

      setState(() {
        vendedorEndereco =
            '${parceiroData[0].endereco!.bairro},  ${parceiroData[0].endereco!.cidade!.nome},  ${parceiroData[0].endereco!.estado!.nome}';
      });

      final List<Account> classificacoesData =
          await VendasCaller().fetchClassificacao(context);

      classificacoes = classificacoesData
          .expand((classificacao) => (classificacao.valores as List).map(
              (valor) => {'descricao': valor.descricao, 'valor': valor.valor}))
          .toList();

      await Future.delayed(const Duration(seconds: 1)); // Simulação de atraso
      setState(() {
        classificacaoControllers.addAll(
          classificacoes.map((_) => TextEditingController(text: '0')).toList(),
        );
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  void setPrincipalImage(File image) {
    setState(() {
      principalImage = image;
    });
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    final List<Map<String, dynamic>> classificacaoList = [];
    for (int i = 0; i < classificacoes.length; i++) {
      classificacaoList.add({
        'descricao': classificacoes[i]['descricao'],
        'valor': double.tryParse(classificacaoControllers[i].text) ?? 0,
      });
    }

    final List<Map<String, dynamic>> imageList = selectedImages.map((image) {
      final String base64Image = base64Encode(image.readAsBytesSync());
      return {
        'foto': base64Image,
        'isPrincipal': image == principalImage,
      };
    }).toList();

    final Map<String, dynamic> customAddress = {
      'rua': ruaController.text,
      'numero': numeroController.text,
      'bairro': bairroController.text,
      'cidade': cidadeController.text,
      'estado': estadoController.text,
      'cep': cepController.text,
    };

    try {
      final Map<String, dynamic> requestBody = {
        'tipoProdutoId': 1,
        'produtoId': 1,
        'descricao': '$selectedSafra - $selectedTipoProduto',
        'safra': selectedSafra, // Novo campo
        'semente': sementeController.text, // Novo campo
        'tiposNegociacoes': selectedTipoNegociacao, // Novo campo
        'listFotos': imageList,
        'qtdSacos': int.tryParse(qtdSacosController.text) ?? 0,
        'vlrSacos': selectedTipoNegociacao == "Sem valor, só negociar valor"
            ? 0
            : double.tryParse(vlrSacosController.text) ?? 0,
        'isCargaFechada': isCargaFechada,
        'tipoGrao': selectedTipoGrao,
        'dtRetirada': dtRetirada?.toIso8601String(),
        'parceiro': {'id': AuthUtility.userInfo?.data?.id},
        'status': 'A',
        'qtdsacosoriginal': int.tryParse(qtdSacosController.text) ?? 0,
        'classificacao': classificacaoList,
        if (useCustomAddress) 'enderecoRetirada': customAddress,
      };

      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.insertProduto, requestBody);

      if (response.isSuccess) {
        showSnackBar(
            message: "Venda enviada com sucesso!",
            isError: false,
            context: context);

        _formKey.currentState!.reset();
        qtdSacosController.clear();
        vlrSacosController.clear();
        for (var controller in classificacaoControllers) {
          controller.clear();
        }
        ruaController.clear();
        numeroController.clear();
        bairroController.clear();
        cidadeController.clear();
        estadoController.clear();
        cepController.clear();
        selectedImages.clear();
        principalImage = null;
        sementeController.clear(); // Limpar campo semente
      } else {
        showSnackBar(
            message: "Erro ao enviar proposta.",
            isError: true,
            context: context);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar formulário: $error')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dtRetirada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != dtRetirada) {
      setState(() {
        dtRetirada = picked;
        dtRetiradaController.text =
            DateFormat('dd/MM/yyyy', 'pt_BR').format(picked);
      });
    }
  }

  InputDecoration customInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: CustomColors().getBorderInput(), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: CustomColors().getBorderInput(), width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors().getLightGreenBackground(),
      appBar: UserBannerAppBar(
        screenTitle: "Cadastro de Produto",
        isLoading: isLoading,
        onRefresh: () {
          fetchInitialData();
        },
        onTapped: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen()));
        },
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Retirada: $vendedorEndereco'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Usar outro endereço para retirada?'),
                            Checkbox(
                              value: useCustomAddress,
                              onChanged: (value) {
                                setState(() {
                                  useCustomAddress = value!;
                                });
                              },
                            ),
                          ],
                        ),
                        if (useCustomAddress) ...[
                          TextFormField(
                            controller: ruaController,
                            decoration: customInputDecoration('Rua'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: numeroController,
                            decoration: customInputDecoration('Número'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: bairroController,
                            decoration: customInputDecoration('Bairro'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: cidadeController,
                            decoration: customInputDecoration('Cidade'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: estadoController,
                            decoration: customInputDecoration('Estado'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: cepController,
                            decoration: customInputDecoration('CEP'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Data para Retirada',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    locale: const Locale('pt', 'BR'),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      dtRetirada = pickedDate;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  backgroundColor:
                                      CustomColors().getDarkGreenBorder(),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  dtRetirada == null
                                      ? 'Data para Retirada'
                                      : DateFormat('dd/MM/yyyy', 'pt_BR')
                                          .format(dtRetirada!),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (dtRetirada == null)
                          const Text(
                            'Data para Retirada é obrigatória',
                            style: TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTipoProduto,
                          decoration: customInputDecoration('Tipo de Produto'),
                          items: ['Arroz em Casca', 'Arroz Esbramado']
                              .map((tipo) => DropdownMenuItem<String>(
                                    value: tipo,
                                    child: Text(tipo),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTipoProduto = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTipoGrao,
                          decoration: customInputDecoration('Tipo de Grão'),
                          items: ['Verde', 'Seco']
                              .map((tipo) => DropdownMenuItem<String>(
                                    value: tipo,
                                    child: Text(tipo),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTipoGrao = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedSafra,
                          decoration: customInputDecoration('Safra'),
                          items: ['2023/2024', '2024/2025']
                              .map((safra) => DropdownMenuItem<String>(
                                    value: safra,
                                    child: Text(safra),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSafra = value!;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Selecione uma safra' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: sementeController,
                          decoration: customInputDecoration('Semente'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTipoNegociacao,
                          decoration:
                              customInputDecoration('Tipo de Negociação'),
                          items: [
                            'Adicionar valor e aceitar propostas',
                            'Sem valor, só negociar valor',
                            'Adicionar valor e não aceitar proposta'
                          ]
                              .map((tipo) => DropdownMenuItem<String>(
                                    value: tipo,
                                    child: Text(tipo),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTipoNegociacao = value!;
                              if (value == "Sem valor, só negociar valor") {
                                vlrSacosController.text = '0';
                              }
                            });
                          },
                          validator: (value) => value == null
                              ? 'Selecione um tipo de negociação'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: pickImages,
                          icon: const Icon(Icons.photo),
                          label: const Text("Adicionar Fotos da Amostra"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            backgroundColor: CustomColors().getTextColor(),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: selectedImages.map((image) {
                            return GestureDetector(
                              onTap: () => setPrincipalImage(image),
                              child: Stack(
                                children: [
                                  Image.file(
                                    image,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  if (principalImage == image)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: CustomColors().getTextColor(),
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: qtdSacosController,
                          decoration:
                              customInputDecoration('Quantidade de Sacos'),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value == null || int.tryParse(value) == null
                                  ? 'Número inválido'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: vlrSacosController,
                          decoration: customInputDecoration('Valor por Saco'),
                          keyboardType: TextInputType.number,
                          enabled: selectedTipoNegociacao !=
                              "Sem valor, só negociar valor",
                          validator: (value) {
                            if (selectedTipoNegociacao !=
                                "Sem valor, só negociar valor") {
                              return value == null ||
                                      double.tryParse(value) == null
                                  ? 'Valor inválido'
                                  : null;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Classificações',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        for (int i = 0; i < classificacoes.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              controller: classificacaoControllers[i],
                              decoration: customInputDecoration(
                                  classificacoes[i]['descricao']),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FloatingActionButton.extended(
                      onPressed: isSubmitting ? null : submitForm,
                      label: isSubmitting
                          ? const CircularProgressIndicator(
                              color: Colors
                                  .white, // Consider changing if background is white
                            )
                          : const Text('Gravar'),
                      icon: const Icon(Icons.save),
                      backgroundColor: isSubmitting
                          ? Colors.white
                          : CustomColors().getBorderInput(),
                      foregroundColor: Colors.white, // Add this line
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
