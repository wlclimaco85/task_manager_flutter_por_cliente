import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../services/checkout_caller.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import '../../../models/auth_utility.dart';
import '../../../widgets/negociacao_core.dart';
import '../../../widgets/envio_contrato_core.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class WebCheckoutScreen extends StatefulWidget {
  final String productName;
  final double productValue;
  final int productQnt;
  final int idVenda;
  final int negociacaoId;

  const WebCheckoutScreen({
    super.key,
    required this.productName,
    required this.productValue,
    required this.productQnt,
    required this.idVenda,
    required this.negociacaoId,
  });

  @override
  _WebCheckoutScreenState createState() => _WebCheckoutScreenState();
}

class _WebCheckoutScreenState extends State<WebCheckoutScreen> {
  bool _termsAccepted = false;
  String _termsText = "Carregando termos...";
  final Color _fundoVerdeClaro = const Color.fromARGB(255, 240, 255, 241);
  final Color _bordaVerdeEscuro = GridColors.success;
  bool contratarFrete = false;
  double valorFrete = 50.0; // Valor estimado do frete
  Future<double> _freteFuture = Future.value(0.0);

  @override
  void initState() {
    super.initState();
    _carregarTermos();
    _freteFuture = _calcularFrete(
      widget.idVenda,
      AuthUtility.userInfo?.data!.id ?? 0,
      widget.productQnt,
    );
  }

  Future<double> _calcularFrete(int vendaId, int compradorId, int peso) async {
    Map<String, dynamic> requestBody = {
      "vendaId": vendaId,
      "compradorId": compradorId,
      "peso": peso,
      "isNegociacao": false,
    };
    try {
      return await CheckoutCaller.carregarVlrFrete(context, requestBody);
    } catch (e) {
      if (mounted) {
        setState(() {
          _termsText = "Falha ao carregar termos: ${e.toString()}";
        });
      }
      return 0.0;
    }
  }

  Future<void> _carregarTermos() async {
    try {
      final termos = await CheckoutCaller.carregarTermos();

      if (mounted) {
        setState(() {
          _termsText = termos;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _termsText = "Falha ao carregar termos: ${e.toString()}";
        });
      }
    }
  }

  void _showTermsPopup() {
    return _exibirTermos();
  }

  void _exibirTermos() {
    L.d("Starting _exibirTermos");

    if (_termsText.isEmpty) {
      L.d("_termsText is empty. Not showing dialog.");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Termos não encontrados.')));
      return;
    }

    final unescape = HtmlUnescape();
    String textoDecodificado =
        _termsText.contains('&') ? unescape.convert(_termsText) : _termsText;
    L.d("Decoded text: $textoDecodificado");

    L.d("About to show dialog");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _fundoVerdeClaro,
        title: Text(
          'Termos da Compra',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _bordaVerdeEscuro,
          ),
        ),
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Html(
              data: textoDecodificado,
              style: {
                "p": Style(
                  fontSize: FontSize(16.0),
                  lineHeight: const LineHeight(1.8),
                  margin: Margins.only(bottom: 10),
                ),
                "ul": Style(
                  margin: Margins.only(left: 20, top: 10, bottom: 10),
                ),
                "li": Style(
                  margin: Margins.only(bottom: 8),
                  display: Display.listItem,
                ),
                "hr": Style(
                  height: Height(1),
                  color: Colors.grey[400],
                  margin: Margins.symmetric(vertical: 15),
                ),
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              L.d("Closing dialog");
              Navigator.pop(context);
            },
            child: Text('Fechar', style: TextStyle(color: _bordaVerdeEscuro)),
          ),
        ],
      ),
    );
    L.d("showDialog finished");
  }

  Widget _buildCardInformacao(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _bordaVerdeEscuro.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _showFretePopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Estimativa de Frete"),
          content: const Text(
            "Este é o valor estimado de frete. Será feita uma nova cotação junto aos motoristas parceiros para verificar se conseguiremos manter o preço.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final valorTotal = widget.productQnt * widget.productValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finalização da Compra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: _fundoVerdeClaro,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Seção de Informações do Produto
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: _bordaVerdeEscuro, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    _buildCardInformacao('Produto:', widget.productName),
                    _buildCardInformacao(
                      'Quantidade:',
                      '${widget.productQnt} sacos',
                    ),
                    _buildCardInformacao(
                      'Valor Unitário:',
                      'R\$ ${widget.productValue.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _bordaVerdeEscuro),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'VALOR TOTAL:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'R\$ ${valorTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            // Seção de Termos
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _bordaVerdeEscuro.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (v) =>
                        setState(() => _termsAccepted = v ?? false),
                    activeColor: _bordaVerdeEscuro,
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text(
                          'Li e aceito os ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: _exibirTermos,
                          child: const Text(
                            'termos de compra',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green[800]!.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: contratarFrete,
                    onChanged: (bool? value) {
                      setState(() => contratarFrete = value ?? false);
                      if (contratarFrete) _showFretePopup();
                    },
                    activeColor: Colors.green[800],
                  ),
                  Expanded(
                    child: FutureBuilder<double>(
                      future: _freteFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            'Calculando frete...',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Text(
                            'Frete não disponível',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        final formatter = NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: 'R\$',
                          decimalDigits: 2,
                        );

                        return Text(
                          'Contratar Frete - ${formatter.format(snapshot.data!)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Botão Finalizar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout, size: 24),
                label: const Text(
                  'CONFIRMAR COMPRA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bordaVerdeEscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (_termsAccepted) {
                    final response = await RenegotiationHandler.renegotiate(
                      context: context, // Contexto do widget atual
                      vendaId: widget.idVenda, // ID da venda
                      vendedorId: 1,
                      compradorId: AuthUtility.userInfo?.data?.id ??
                          0, // Substitua com ID do comprador
                      qtdSacos: widget.productQnt ?? 0,
                      vlrSacos: widget.productValue ?? 0.0,
                      negociacaoId: widget.negociacaoId,
                      qtdDisponivel: widget.productQnt, // Quantidade disponível
                    );
                    Navigator.of(context).pop();
                    if (response) {
                      final response =
                          await RenegotiationMovimentoContratosHandler
                              .renegotiates(
                        context: context, // Contexto do widget atual
                        vendaId: widget.idVenda,
                        status: 'download',
                      ); // Refresh automático após sucesso
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erro ao Comprar')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
