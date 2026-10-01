import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../services/vendas_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/fotos_util.dart';
import '../../constants/custom_colors.dart';

// Define theme colors

class WindowsProductCatalogPageVendas extends StatefulWidget {
  final String title;
  final String apiUrl;
  final IconData actionIcon;
  final String actionTooltip;

  const WindowsProductCatalogPageVendas({
    super.key,
    required this.title,
    required this.apiUrl,
    required this.actionIcon,
    required this.actionTooltip,
  });

  @override
  _WindowsProductCatalogPageVendasState createState() =>
      _WindowsProductCatalogPageVendasState();
}

class _WindowsProductCatalogPageVendasState extends State<WindowsProductCatalogPageVendas> {
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
      final data = await VendasCaller().fetchItensAVenda(context);
      setState(() {
        products = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: fetchProducts,
          ),
        ],
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
                        onDelete: () {
                          setState(() {
                            products.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Produto excluído com sucesso'),
                            ),
                          );
                        },
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
            Text('Tipos: ${product.tipo ?? 'Não especificado'}'),
            Text('Quantidade de sacos: ${product.qtdSacos ?? 0}'),
            Text('Valor por saco: R\$${product.vlrSacos ?? 0.0}'),
            Text(
              'Data de retirada: ${product.dtRetirada ?? 'Não especificado'}',
            ),
            const SizedBox(height: 8),
            ...List.generate((product.negociacoes as List).length, (i) {
              final negotiation = product.negociacoes[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bairro: ${negotiation.bairroEntr}'),
                  Text('Cidade: ${negotiation.cidadeEntr}'),
                  Text('Estado: ${negotiation.estadoEntr}'),
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
                  color: CustomColors().getDarkGreenBorder(),
                  width: 2,
                ),
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
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageBase64 = product.foto != null
        ? decodeBase64Image(product.foto)
        : decodeBase64Image(getImagepadrao());

    // final imageBase64 = decodeBase64Image(getImagepadrao());
    final Widget image = imageBase64.isNotEmpty
        ? Image.memory(imageBase64, width: 100, height: 100, fit: BoxFit.cover)
        : const Icon(Icons.image, size: 100);

    return Card(
      margin: const EdgeInsets.all(10),
      color: CustomColors().getLightGreenBackground(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: CustomColors().getDarkGreenBorder(), width: 2),
      ),
      child: Column(
        children: [
          // Título do Produto
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product.tipo ?? 'Sem descrição',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Definir um tamanho fixo para evitar erro de altura indefinida
          SizedBox(
            height: 250, // Definir um limite para o conteúdo principal
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: image),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lote: ${product.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Quantidade: ${product.qtdSacos} sacos'),
                          Text('Data Retirada: ${product.dtRetirada}'),
                          Text('Descrição: ${product.descricao}'),
                          const SizedBox(height: 8),
                          const Text(
                            'Endereço Retirada:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...List.generate(
                            (product.negociacoes as List).length,
                            (i) {
                              final negotiation = product.negociacoes[i];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bairro: ${negotiation.bairroEntr}'),
                                  Text('Cidade: ${negotiation.cidadeEntr}'),
                                  Text('Estado: ${negotiation.estadoEntr}'),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Linha separadora cinza clara
          const Divider(color: Colors.grey, thickness: 1),

          // Botões centralizados na parte inferior
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1), // Espaço extra
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botão Editar
                Tooltip(
                  message: 'Editar',
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: onAction,
                      ),
                      const Text(
                        'Editar',
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40), // Espaço entre os botões
                // Botão Excluir
                Tooltip(
                  message: 'Excluir',
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: onDelete,
                      ),
                      const Text(
                        'Excluir',
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(primarySwatch: Colors.green),
      home: WindowsProductCatalogPageVendas(
        title: 'Produtos do Vendedor',
        apiUrl:
            '${ApiLinks.fecthItensAVenda}${AuthUtility.userInfo?.data?.id}',
        actionIcon: Icons.edit,
        actionTooltip: 'Editar Produto',
      ),
    ),
  );
}
