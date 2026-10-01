import 'package:flutter/material.dart';
import '../../services/vendas_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/fotos_util.dart';
import '../../windows/screens/update_profile.dart';
import '../../../widgets/user_banners.dart';
import '../../mobile/screens/checkoutScreen.dart';
import '../../constants/custom_colors.dart';
import '../../utils/grid_texts.dart';

class WindowsNegociacaoCatalogPage extends StatefulWidget {
  final String title;
  final String apiUrl;
  final IconData actionIcon;
  final String actionTooltip;

  const WindowsNegociacaoCatalogPage({
    super.key,
    required this.title,
    required this.apiUrl,
    required this.actionIcon,
    required this.actionTooltip,
  });

  @override
  _WindowsNegociacaoCatalogPageState createState() => _WindowsNegociacaoCatalogPageState();
}

class _WindowsNegociacaoCatalogPageState extends State<WindowsNegociacaoCatalogPage> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await VendasCaller().fetchItensANegocias(context);
      setState(() {
        products = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produtos: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: "Vendas",
        onRefresh: fetchProducts,
        isLoading: isLoading,
        onTapped: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WindowsUpdateProfileScreen(),
            ),
          );
        },
      ),
      body: Container(
        color: CustomColors().getLightGreenBackground(),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : products.isEmpty
                ? const Center(child: Text('Nenhum produto encontrado'))
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        actionIcon: widget.actionIcon,
                        actionTooltip: widget.actionTooltip,
                        onAction: () => showActionPopup(context, product),
                      );
                    },
                  ),
      ),
    );
  }

  void showActionPopup(BuildContext context, dynamic product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CustomColors().getLightGreenBackground(),
        title: Text(
          product.descricao ?? 'Sem descrição',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${product.tipo ?? 'Não especificado'}'),
            Text('Quantidade de sacos: ${product.qtdSacos ?? 0}'),
            Text('Valor por saco: R\$${product.vlrSacos ?? 0.0}'),
            Text(
                'Data de retirada: ${product.dtRetirada ?? 'Não especificado'}'),
            const SizedBox(height: 8),
            const Text('Negociações:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...List.generate((product.negociacoes as List).length, (i) {
              final negotiation = product.negociacoes[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comprador ID: ${negotiation.compradorId}'),
                  Text('Quantidade: ${negotiation.qtdSacos}'),
                  Text('Valor por saco: R\$${negotiation.vlrSacos}'),
                  Text('Status: ${negotiation.status}'),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ação realizada com sucesso')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors().getButtonBackground(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: CustomColors().getDarkGreenBorder(), width: 2),
              ),
            ),
            child: const Text('Confirmar Ação'),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final dynamic product;
  final IconData actionIcon;
  final String actionTooltip;
  final VoidCallback onAction;

  const ProductCard({
    super.key,
    required this.product,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
  });

  Future<void> fetchProducts(BuildContext context) async {
    try {
      final data = await VendasCaller().fetchItensANegocias(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produtos: $e')),
      );
    } finally {}
  }

  Future<Map<String, dynamic>?> finalizarNegociacao(
    BuildContext context,
    int vendaId,
    int quantidade,
    double vlrSaco,
    String lote,
    Function onLoad,
  ) async {
    try {
      // Chamada para a API com tratamento de erros mais detalhado
      final response =
          await VendasCaller().confirmarNegociacao(context, vendaId);

      // Verificar se a resposta é válida e se a negociação foi concluída com sucesso
      // Mostrar Snackbar de sucesso e fechar o diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Negociação aceita com sucesso!'),
        ),
      );

      // Fechar o diálogo
      Navigator.pop(context);
    } catch (e) {
      // Tratar outras exceções que possam ocorrer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    } finally {
      // Chamar a função onLoad para atualizar a interface, se necessário
      onLoad(context);
    }
    return null;
  }

  Future<Map<String, dynamic>?> enviarContraProposta(
    BuildContext context,
    int negociacaoId,
    int vendaId,
    int compradorId,
    int vendedorId,
    double qtdSacos,
    double vlrSacos,
  ) async {
    try {
      final response = await VendasCaller().enviarContraProposta(
        context,
        negociacaoId,
        vendaId,
        compradorId,
        vendedorId,
        qtdSacos,
        vlrSacos,
      );

      if (response != null) {
        return response;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar contraproposta.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    }
    return null;
  }

  Future<Map<String, dynamic>?> recusarNegociacao(
    BuildContext context,
    int vendaId,
    int quantidade,
    double vlrSaco,
    String lote,
    Function onLoad,
  ) async {
    try {
      // Chamada para a API com tratamento de erros mais detalhado
      final response = await VendasCaller().confirmarRecusar(context, vendaId);

      // Verificar se a resposta é válida e se a negociação foi concluída com sucesso
      // Mostrar Snackbar de sucesso e fechar o diálogo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sua Negociação foi recusada!'),
        ),
      );

      // Fechar o diálogo
      Navigator.pop(context);
    } catch (e) {
      // Tratar outras exceções que possam ocorrer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    } finally {
      // Chamar a função onLoad para atualizar a interface, se necessário
      onLoad(context);
    }
    return null;
  }

  InputDecoration customInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  void showContraPropostaPopup(BuildContext context, dynamic negotiation) {
    final formKey = GlobalKey<FormState>();
    final qtdSacosController = TextEditingController();
    final vlrSacosController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: CustomColors().getLightGreenBackground(),
          title: const Text(
            'Fazer Contra Proposta',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Input para Quantidade de Sacos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextFormField(
                    controller: qtdSacosController,
                    decoration: customInputDecoration('Quantidade de Sacos'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a quantidade de sacos';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16), // Espaçamento entre os inputs
                // Input para Valor por Saco
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextFormField(
                    controller: vlrSacosController,
                    decoration: customInputDecoration('Valor por Saco'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o valor por saco';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: CustomColors().getCancelButtonColor()),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final qtdSacos = double.parse(qtdSacosController.text);
                  final vlrSacos = double.parse(vlrSacosController.text);

                  // Aqui você pode chamar o endpoint para enviar a proposta
                  final response = await enviarContraProposta(
                    context,
                    negotiation.id,
                    negotiation.id, // TODO
                    negotiation.compradorId,
                    negotiation.vendedorId,
                    qtdSacos,
                    vlrSacos,
                  );

                  if (response != null && response['status'] == 'success') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Contraproposta enviada com sucesso!')),
                    );
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Erro ao enviar contraproposta.')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors().getConfirmButtonColor(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: CustomColors().getDarkGreenBorder(), width: 2),
                ),
              ),
              child: const Text('Enviar Proposta'),
            ),
          ],
        );
      },
    );
  }

  void downloadContrato(int contratoId, BuildContext context) async {
    VendasCaller().downloadContrato(contratoId, context);
  }

  @override
  Widget build(BuildContext context) {
    final imageBase64 = product.foto != null
        ? decodeBase64Image(product.foto)
        : decodeBase64Image(getImagepadrao());

    // final imageBase64 = decodeBase64Image(getImagepadrao());
    final Widget image = imageBase64.isNotEmpty
        ? Image.memory(
            imageBase64,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          )
        : const Icon(Icons.image, size: 100);

    final int contratoId;

    return Card(
      margin: const EdgeInsets.all(10),
      color: CustomColors().getLightGreenBackground(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: CustomColors().getDarkGreenBorder(), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: image,
                ),
                const SizedBox(width: 6), // Espaço entre a foto e o texto
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.tipo ?? 'Sem descrição',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CustomColors().getTextColor(),
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style:
                              TextStyle(color: CustomColors().getTextColor()),
                          children: [
                            const TextSpan(
                              text: 'Lote: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: product.id!.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: CustomColors().getTextColorDesc()),
                          children: [
                            const TextSpan(
                              text: 'Quantidade: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '${product.qtdSacos} sacos',
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: CustomColors().getTextColorDesc()),
                          children: [
                            const TextSpan(
                              text: 'Data Retirada: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: product.dtRetirada,
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: CustomColors().getTextColorDesc()),
                          children: [
                            const TextSpan(
                              text: 'Descrição: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: product.descricao,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

// No seu widget
            Text('Negociações:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CustomColors().getTextColor(),
                    fontSize:
                        16)), // Aumentei o tamanho para combinar com o estilo anterior
            const SizedBox(height: 8), // Espaço após o título
            ...List.generate((product.negociacoes as List).length, (i) {
              final negotiation = product.negociacoes[i];
              final vendaId = product.id!;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                color: CustomColors().getNegotiationCardBackground(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(
                      color: CustomColors().getDarkGreenBorder(), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comprador ID
                      SizedBox(
                        width: double.infinity,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 14,
                                color: CustomColors().getTextColor()),
                            children: [
                              const TextSpan(
                                text: 'Comprador ID: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: negotiation.compradorId!.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Quantidade
                      SizedBox(
                        width: double.infinity,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 14,
                                color: CustomColors().getTextColor()),
                            children: [
                              const TextSpan(
                                text: 'Quantidade: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: negotiation.qtdSacos!.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Valor por saco
                      SizedBox(
                        width: double.infinity,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 14,
                                color: CustomColors().getTextColor()),
                            children: [
                              const TextSpan(
                                text: 'Valor por saco: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: 'R\$${negotiation.vlrSacos}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Status
                      SizedBox(
                        width: double.infinity,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 14,
                                color: CustomColors().getTextColor()),
                            children: [
                              const TextSpan(
                                text: 'Status: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    '${getStatusText(negotiation.status)} / ${getTipoText(negotiation.tipo)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Botões de ação
                      if (negotiation.tipo == 'P' ||
                          negotiation.tipo == 'C') ...[
                        // Botões para Proposta ou Contra Proposta
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  tooltip: 'Aceitarrer',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: const Color.fromARGB(
                                              255,
                                              231,
                                              247,
                                              233), // Verde claro
                                          title: const Text(
                                              'Confirmar Negociação'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Quantidade:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        '${negotiation.qtdSacos} sacos'),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Valor:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        'R\$ ${negotiation.vlrSacos!.toString()}'),
                                                  ], //'valor: ${negotiation.vlrSacos}''quantidade : ${negotiation.qtdSacos}'
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors
                                                    .red, // Botão Cancelar em vermelho
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(GridTexts.cancel),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(255, 1,
                                                        95, 15), // Verde escuro
                                              ),
                                              onPressed: () async {
                                                final response =
                                                    await finalizarNegociacao(
                                                        context,
                                                        negotiation.id!,
                                                        negotiation.qtdSacos!,
                                                        negotiation.vlrSacos!,
                                                        negotiation.id!
                                                            .toString(),
                                                        fetchProducts);

                                                if (response != null &&
                                                    response['status'] == 'A') {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Negociação aceita com sucesso!'),
                                                    ),
                                                  );
                                                  Navigator.pop(context);
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Erro ao finalizar negociação.'),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('Confirmar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                const Text(
                                  'Aceitar',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  tooltip: 'Recusar',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: const Color.fromARGB(
                                              255,
                                              231,
                                              247,
                                              233), // Verde claro
                                          title: const Text(
                                              'Confirmar Negociação'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Quantidade:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        '${negotiation.qtdSacos} sacos'),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Valor:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        'R\$ ${negotiation.vlrSacos!.toString()}'),
                                                  ], //'valor: ${negotiation.vlrSacos}''quantidade : ${negotiation.qtdSacos}'
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors
                                                    .red, // Botão Cancelar em vermelho
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(GridTexts.cancel),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color.fromARGB(255, 1,
                                                        95, 15), // Verde escuro
                                              ),
                                              onPressed: () async {
                                                final response =
                                                    await recusarNegociacao(
                                                        context,
                                                        negotiation.id!,
                                                        negotiation.qtdSacos!,
                                                        negotiation.vlrSacos!,
                                                        negotiation.id!
                                                            .toString(),
                                                        fetchProducts);

                                                if (response != null &&
                                                    response['status'] == 'A') {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Negociação aceita com sucesso!'),
                                                    ),
                                                  );
                                                  Navigator.pop(context);
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Erro ao finalizar negociação.'),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('Confirmar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                const Text(
                                  'Recusar',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.handshake,
                                      color: Colors.green),
                                  tooltip: 'Fazer Contra Proposta',
                                  onPressed: () {
                                    showContraPropostaPopup(
                                        context, negotiation);
                                  },
                                ),
                                const Text(
                                  'Fazer Contra Proposta',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ],
                            )
                          ],
                        ),
                      ] else if (negotiation.tipo == 'A') ...[
                        // Botões para Aceita
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckoutScreen(
                                        productName: 'Arroz em Casca',
                                        productValue: negotiation.vlrSacos!,
                                        productQnt: negotiation.qtdSacos!,
                                        idVenda: vendaId,
                                        negociacaoId: negotiation.id!,
                                      ),
                                    ),
                                  ),

                                  icon: const Icon(
                                    Icons.edit_document,
                                  ), // Choose an appropriate icon
                                  color: const Color.fromARGB(255, 1, 95, 15),
                                ),
                                const Text('Assinar Contrato'),
                              ],
                            ),
                            Column(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    await handleWithdraw(context, negotiation);
                                  },
                                  icon: const Icon(Icons
                                      .cancel), // Choose an appropriate icon
                                  color: Colors.red,
                                ),
                                const Text('Desistir'),
                              ],
                            ),
                          ],
                        )
                      ] else if (negotiation.tipo == 'X') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.handshake,
                                      color: Colors.green),
                                  tooltip: 'Fazer Contra Proposta',
                                  onPressed: () {
                                    showContraPropostaPopup(
                                        context, negotiation);
                                  },
                                ),
                                const Text(
                                  'Fazer Contra Proposta',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ],
                            )
                          ],
                        )
                      ] else if (negotiation.tipo == 'F') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceEvenly, // Or .spaceBetween, etc.
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download,
                                      color: Colors.green), // Download icon
                                  tooltip: 'Download Contrato',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Download do contrato iniciado...')),
                                    );
                                    downloadContrato(negotiation.id, context);
                                    // Add your download logic here
                                  },
                                ),
                                const Text(
                                  'Download Contrato',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.star,
                                      color:
                                          Colors.orange), // Rating/Review icon
                                  tooltip: 'Avaliar Vendedor/Comprador',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Abrindo tela de avaliação...'), // More appropriate message
                                      ),
                                    );
                                    // Navigate to your rating screen or logic here
                                  },
                                ),
                                const Text(
                                  'Avaliar Vendedor/Comprador',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

// Função para mapear status para texto
  String getStatusText(String status) {
    switch (status) {
      case 'A':
        return 'Aguardando';
      case 'F':
        return 'Finalizado';
      case 'P':
        return 'Pendente';
      default:
        return 'Desconhecido';
    }
  }

  // Função para mapear status para texto private String tipo; // P = Proposta, C = Contra Proposta, A Aceita, X Recusada, F Finaliado;
  String getTipoText(String status) {
    switch (status) {
      case 'P':
        return 'Proposta';
      case 'C':
        return 'Contra Proposta';
      case 'A':
        return 'Aceita';
      case 'X':
        return 'Rejeitada';
      case 'F':
        return 'Finalizado';
      default:
        return 'Desconhecido';
    }
  }

  Future<void> handleAccept(BuildContext context, dynamic negotiation) async {
    final response = await finalizarNegociacao(
      context,
      negotiation.id!,
      negotiation.qtdSacos!,
      negotiation.vlrSacos!,
      negotiation.id!.toString(),
      fetchProducts,
    );
    if (response != null && response['status'] == 'A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Negociação aceita com sucesso!')),
      );
    }
  }

  Future<void> handleReject(BuildContext context, dynamic negotiation) async {
    final response = await recusarNegociacao(
      context,
      negotiation.id!,
      negotiation.qtdSacos!,
      negotiation.vlrSacos!,
      negotiation.id!.toString(),
      fetchProducts,
    );
    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Negociação recusada com sucesso!')),
      );
    }
  }

  Future<void> handleSignContract(
      BuildContext context, dynamic negotiation) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contrato assinado com sucesso!')),
    );
  }

  Future<void> handleWithdraw(BuildContext context, dynamic negotiation) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Você desistiu da negociação.')),
    );
  }

  void main() {
    runApp(MaterialApp(
      theme: ThemeData(primarySwatch: Colors.green),
      home: WindowsNegociacaoCatalogPage(
        title: 'Produtos do Vendedor',
        apiUrl:
            '${ApiLinks.fecthItensAVenda}4',
        actionIcon: Icons.edit,
        actionTooltip: 'Editar Produto',
      ),
    ));
  }
}
