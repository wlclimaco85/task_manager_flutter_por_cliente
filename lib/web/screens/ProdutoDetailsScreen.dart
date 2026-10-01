import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../services/vendas_caller.dart';
import '../../../models/venda_model.dart';
import '../../mobile/screens/checkoutScreen.dart';
import '../../../widgets/negotiationDialog.dart';
import '../../../models/auth_utility.dart';
import '../../constants/custom_colors.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
import '../../utils/grid_texts.dart';
// Tela de Detalhes
class WebProdutoDetailsScreen extends StatefulWidget {
  final int produtoId;

  const WebProdutoDetailsScreen({super.key, required this.produtoId});

  @override
  State<WebProdutoDetailsScreen> createState() => _WebProdutoDetailsScreenState();
}

class _WebProdutoDetailsScreenState extends State<WebProdutoDetailsScreen> {
  Future<List<Produto>> _futureProduto = Future.value([]);
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProdutoDetails();
  }

  Future<void> _fetchProdutoDetails() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });
    try {
      final produto = await VendasCaller().fetchProdutoDetails(
        context,
        widget.produtoId,
      );
      setState(() {
        _futureProduto = Future.value(produto); // Assign the Produto object
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar produto: $e')));
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  void _refresh() {
    _fetchProdutoDetails(); // Call the same function for refresh
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CustomColors().getLightGreenBackground(),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Detalhes do Produto',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refresh,
          ),
        ],
      ),
      backgroundColor: CustomColors().getLightGreenBackground(),
      body: FutureBuilder<List<Produto>>(
        future: _futureProduto,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  CustomColors().getDarkGreenBorder(),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final account = snapshot.data == null
              ? Produto()
              : snapshot.data!.isNotEmpty
                  ? snapshot.data!.first
                  : Produto();
          final listFotos = (account.listFotos as List?) ?? [];

          final parceiro = account.parceiro;
          final endereco = parceiro?.endereco;

          final bairro = endereco?.bairro ?? "Bairro não informado";
          final cidade = endereco?.cidade?.nome ?? "Cidade não informada";
          final estado = endereco?.estado?.nome ?? "Estado não informado";

          final enderecoCompleto = endereco != null
              ? '$bairro, $cidade/$estado'
              : 'Endereço não disponível';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: CustomColors().getLightGreenBackground(),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CustomColors().getDarkGreenBorder(),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carrossel de Fotos
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CustomColors().getDarkGreenBorder(),
                        width: 2,
                      ),
                    ),
                    child: SizedBox(
                      height: 250,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: listFotos.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final imageData = listFotos[index]!.foto;
                              try {
                                Uint8List bytes = base64.decode(imageData);
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: MemoryImage(bytes),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                L.d('Error decoding base64 image: $e');
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.error,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios),
                                  onPressed: _previousPage,
                                ),
                                ...List.generate(
                                  listFotos.length,
                                  (index) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentPage == index
                                          ? CustomColors().getDarkGreenBorder()
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  onPressed: _nextPage,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Informações do Produto
                  _buildSectionTitle('Informações do Produto'),
                  _buildInfoItem('Descrição', account.descricao),
                  _buildInfoItem(
                    'Quantidade de Sacos',
                    account.qtdSacos.toString(),
                  ),
                  _buildInfoItem('Valor por Saco', 'R\$ ${account.vlrSacos}'),
                  _buildInfoItem('Data de Retirada', account.dataRetirada),
                  _buildInfoItem('Safra', account.safra),
                  _buildInfoItem('Semente', account.semente),
                  _buildInfoItem('Tipo de Grão', account.tipoGrao),

                  // Informações do Parceiro
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Vendedor:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  _buildInfoItem('Nome', account.parceiro?.nome ?? 'N/A'),
                  _buildInfoItem('Endereço', enderecoCompleto),

                  // Classificações
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Classificações:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (account.classificacao?.isNotEmpty ?? false)
                    Column(
                      children: account.classificacao!
                          .map<Widget>(
                            (classificacao) => _buildInfoItem(
                              classificacao.descricao ?? "Sem descrição",
                              classificacao.valor?.toString() ?? "0",
                            ),
                          )
                          .toList(),
                    )
                  else
                    const SizedBox.shrink(), // Não exibe nada
                  // Botões de Ação
                  const Divider(color: Colors.grey),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 8),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        if (account.tipoNegociacao !=
                            "Adicionar valor e nao aceitar proposta") ...[
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.handshake,
                                  color: Colors.green,
                                ),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) => NegotiationDialog(
                                    product: account,
                                    compradorId:
                                        AuthUtility.userInfo?.data?.id ??
                                            0, // ID do usuário logado
                                  ),
                                ),
                              ),
                              const Text(
                                "Negociar",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
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
                        if (account.tipoNegociacao !=
                            "Sem valor, só negociar valor") ...[
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.orange,
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutScreen(
                                      productName:
                                          account.descricao!, // Nome do produto
                                      productValue:
                                          account.vlrSacos!, // Valor do produto
                                      productQnt: account
                                          .qtdSacos!, // Quantidade do produto
                                      idVenda: account.id!, // ID da venda
                                      negociacaoId:
                                          account.id!, // ID da negociação
                                    ),
                                  ),
                                ),
                              ),
                              const Text(
                                "Comprar",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
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
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text(
                                        "Cotação de Transporte",
                                      ),
                                      content: const Text(
                                        "Vamos enviar suas informações para nossa transportadora parceira e o mais breve possível será enviado o valor do frete.",
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text(GridTexts.cancel),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        ElevatedButton(
                                          child: const Text("Confirmar"),
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            const Text(
                              "Cotar Transporte",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
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
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CustomColors().getLightGreenBackground(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CustomColors().getDarkGreenBorder(),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
