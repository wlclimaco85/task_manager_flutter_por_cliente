import 'package:flutter/material.dart';
import '../../../models/venda_model.dart';
import '../../services/vendas_caller.dart';
import '../../../utils/fotos_util.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../windows/screens/update_profile.dart';
import '../../mobile/screens/checkoutScreen.dart';
import '../../windows/screens/ProdutoDetailsScreen.dart';
import '../../../widgets/user_banners.dart';
import '../../../widgets/negotiationDialog.dart';
import '../../../widgets/negociacao_core.dart';
import '../../../models/auth_utility.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../constants/custom_colors.dart';
import '../../../widgets/freteWidget.dart';

class WindowsProductCatalog extends StatefulWidget {
  const WindowsProductCatalog({super.key});

  @override
  _ProductCatalogState createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<WindowsProductCatalog> {
  List<Produto> allProducts = [];
  List<dynamic> filteredProducts = [];
  bool isLoading = true;

  String selectedState = "Estado";
  String selectedCity = "Cidade";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> onTransporte(BuildContext context, Produto product) async {
    final Map<String, dynamic> requestBody = {"idProduto": 13, "qtdSacos": 10};

    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.insertCotacaoFrete,
        requestBody,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Solicitação enviada com sucesso!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar solicitação: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao enviar solicitação: $e")));
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await VendasCaller().fetchCotacoes(context);
      setState(() {
        allProducts = data;
        filteredProducts = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar produtos: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void applyFilters() {
    setState(() {
      filteredProducts = allProducts.where((product) {
        final stateMatch = selectedState == "Estado" ||
            (product.parceiro?.endereco?.estado?.nome.toString() ?? '') ==
                selectedState;
        final cityMatch = selectedCity == "Cidade" ||
            (product.parceiro?.endereco?.cidade?.nome.toString() ?? '') ==
                selectedCity;

        return stateMatch && cityMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final states = allProducts
        .map<String>(
          (p) =>
              p.parceiro?.endereco?.estado?.nome.toString() ??
              'Não especificado',
        )
        .toSet()
        .toList();
    states.insert(0, "Estado");

    final cities = allProducts
        .map<String>(
          (p) =>
              p.parceiro?.endereco?.cidade?.nome.toString() ??
              'Não especificado',
        )
        .toSet()
        .toList();
    cities.insert(0, "Cidade");

    return Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: "Catálogo de Grãos",
        isLoading: isLoading,
        onRefresh: _fetchProducts,
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedState,
                      onChanged: (value) {
                        setState(() {
                          selectedState = value!;
                          applyFilters();
                        });
                      },
                      items: states.map<DropdownMenuItem<String>>((state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCity,
                      onChanged: (value) {
                        setState(() {
                          selectedCity = value!;
                          applyFilters();
                        });
                      },
                      items: cities.map<DropdownMenuItem<String>>((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                      ? const Center(child: Text('Nenhum produto encontrado'))
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return ProductCard(
                              product: product,
                              onDetails: () =>
                                  showProductDetails(context, product),
                              onBuy: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutScreen(
                                    productName: 'Arroz em Casca',
                                    productValue: product.vlrSacos ?? 0.0,
                                    productQnt: product.qtdSacos ?? 0,
                                    idVenda: product.id ?? 0,
                                    negociacaoId: product.id ?? 0,
                                  ),
                                ),
                              ),
                              onNegotiate: () => showDialog(
                                context: context,
                                builder: (context) => NegotiationDialog(
                                  product: product,
                                  compradorId: AuthUtility.userInfo?.data?.id ??
                                      0, // ID do usuário logado
                                ),
                              ),
                              onTransporte: () =>
                                  onTransporte(context, product),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void showProductDetails(BuildContext context, Produto product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CustomColors().getLightGreenBackground(),
        title: Text(product.descricao ?? "SEM DESCRIÇÃO"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Safra: ${product.safra ?? "Não informado"}'),
            Text('Semente: ${product.semente ?? "Não informado"}'),
            Text('Tipo do Grão: ${product.tipoGrao ?? "Não informado"}'),
            Text(
              'Data de Retirada: ${product.dataRetirada ?? "Não informado"}',
            ),
            Text(
              'Tipo de Negociação: ${product.tipoNegociacao ?? "Não informado"}',
            ),
            Text(
              'Estado: ${product.parceiro?.endereco?.estado?.nome ?? "Não informado"}',
            ),
            Text(
              'Cidade: ${product.parceiro?.endereco?.cidade?.nome ?? "Não informado"}',
            ),
            Text('Quantidade de sacos: ${product.qtdSacos ?? 0}'),
            Text('Valor por saco: R\$${product.vlrSacos ?? 0.0}'),
            const Text('Classificação:'),
            ...product.classificacao!.map<Widget>((c) {
              return Text('${c.descricao}: ${c.valor}');
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void showBuyPopup(BuildContext context, Produto product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CustomColors().getLightGreenBackground(),
        title: Text('Comprar - ${product.descricao}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado: ${product.parceiro?.endereco?.estado?.nome ?? "Não informado"}',
            ),
            Text(
              'Cidade: ${product.parceiro?.endereco?.cidade?.nome ?? "Não informado"}',
            ),
            Text('Quantidade de sacos: ${product.qtdSacos ?? 0}'),
            Text('Valor por saco: R\$${product.vlrSacos ?? 0.0}'),
            const Text('Classificação:'),
            ...product.classificacao!.map<Widget>((c) {
              return Text('${c.descricao}: ${c.valor}');
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await RenegotiationHandler.renegotiate(
                context: context, // Contexto do widget atual
                vendaId: product.id!,
                vendedorId: product.parceiro!.id!,
                compradorId: AuthUtility.userInfo?.data?.id ??
                    0, // Substitua com ID do comprador
                qtdSacos: product.qtdSacos! ?? 0,
                vlrSacos: product.vlrSacos ?? 0.0,
                negociacaoId: product.id!, // Substitua com ID da negociação
                qtdDisponivel: product.qtdSacos!, // Quantidade disponível
              );
              Navigator.of(context).pop();
              if (response) {
                _fetchProducts(); // Refresh automático após sucesso
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao Comprar')),
                );
              }
            },
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Produto product;
  final VoidCallback onDetails;
  final VoidCallback onBuy;
  final VoidCallback onNegotiate;
  final VoidCallback onTransporte;

  const ProductCard({
    super.key,
    required this.product,
    required this.onDetails,
    required this.onBuy,
    required this.onNegotiate,
    required this.onTransporte,
  });

  Widget getFirstImageOrDefault(String photosBase64) {
    if (photosBase64.isNotEmpty) {
      try {
        final Uint8List imageBytes = base64Decode(photosBase64);
        return Image.memory(
          imageBytes,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      } catch (e) {
        debugPrint('Erro ao decodificar a imagem: $e');
      }
    }

    return const Icon(Icons.image, size: 100);
  }

  List<String> getValidImageList(Produto product) {
    if (product.listFotos != null &&
        product.listFotos!.isNotEmpty &&
        product.listFotos!.first.foto != null) {
      return [product.listFotos!.first.foto!];
    }
    return [getImagepadrao()];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      color: CustomColors().getLightGreenBackground(),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: CustomColors().getDarkGreenBorder(), width: 1),
      ),
      child: Container(
        color: Colors.white, // Define o fundo branco para todo o componente
        child: Column(
          children: [
            Column(
              children: [
                // Título acima de tudo
                Padding(
                  padding: const EdgeInsets.only(bottom: 0.0),
                  child: Text(
                    'Arroz em Casca - Lote : ${product.id.toString()}',
                    style: TextStyle(
                      color:
                          CustomColors().getDarkGreenBorder(), // Cor do título
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Conteúdo principal
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: getFirstImageOrDefault(
                        getValidImageList(product).first,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              'Estado',
                              product.parceiro?.endereco?.estado?.nome,
                            ),
                            _buildInfoRow(
                              'Cidade',
                              product.parceiro?.endereco?.cidade?.nome,
                            ),
                            _buildInfoRow(
                              'Quantidade',
                              '${product.qtdSacos} sacos',
                            ),
                            _buildInfoRow(
                              'Valor por saco',
                              'R\$${product.vlrSacos}',
                            ),
                            _buildInfoRow('Safra', product.safra),
                            _buildInfoRow('Semente', product.semente),
                            _buildInfoRow('Tipo do Grão', product.tipoGrao),
                            _buildInfoRow(
                              'Data de Retirada',
                              product.dataRetirada,
                            ),
                            _buildInfoRow(
                              'Tipo de Negociação',
                              product.tipoNegociacao,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Classificação:',
                              style: TextStyle(
                                color: Color(0xFF38180E), // Cor do label
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ...product.classificacao!.map(
                              (c) => _buildClassificationItem(c),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(
              // Divider modificado
              height: 0.5, // Altura total do espaço ocupado
              thickness: 0.5, // Espessura da linha
              color: Colors.grey,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modificação no botão original para navegação
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info, color: Colors.blue),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WindowsProdutoDetailsScreen(produtoId: product.id!),
                          ),
                        ),
                      ),
                      const Text(
                        "Detalhes",
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  if (product.tipoNegociacao !=
                      "Adicionar valor e nao aceitar proposta") ...[
                    // Condição para Negociar
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.handshake,
                            color: Colors.green,
                          ),
                          onPressed: onNegotiate,
                        ),
                        const Text(
                          "Negociar",
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (product.tipoNegociacao !=
                      "Sem valor, só negociar valor") ...[
                    // Condição para Comprar
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Colors.orange,
                          ),
                          onPressed: onBuy,
                        ),
                        const Text(
                          "Comprar",
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                  ],

                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.local_shipping,
                          color: Colors.purple,
                        ),
                        onPressed: () => FreteService.mostrarPopupFrete(
                          context: context, // ESSE CONTEXT É IMPORTANTE!
                          vendaId: product.id ?? 0,
                          compradorId: AuthUtility.userInfo?.data?.id ??
                              0, // ID do usuário logado
                          peso: product.qtdSacos ?? 0 * 60, // Peso total
                          cidadeOrigem:
                              product.parceiro?.endereco?.cidade?.nome ?? "",
                          cidadeDestino: AuthUtility
                                  .userInfo?.data?.codDadosPessoal?.cidade ??
                              "",
                          bairroOrigem:
                              product.parceiro?.endereco?.bairro ?? "",
                          bairroDestino: AuthUtility
                                  .userInfo?.data?.codDadosPessoal?.bairro ??
                              "",
                        ),
                      ),
                      const Text(
                        "Cotar Transporte",
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método auxiliar para construir linhas de informação
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF38180E), // Cor do label
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value ?? "Não informado",
              style: const TextStyle(
                color: Color(0xFF38180E), // Cor da descrição
                fontWeight: FontWeight.normal, // Descrição em negrito
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método auxiliar para itens de classificação
  Widget _buildClassificationItem(Classificacao c) {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12),
                children: [
                  TextSpan(
                    text: '${c.descricao}: ',
                    style: const TextStyle(
                      color: Color(0xFF38180E), // Cor do label
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '${c.valor}',
                    style: const TextStyle(
                      color: Colors.black, // Cor da descrição
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
