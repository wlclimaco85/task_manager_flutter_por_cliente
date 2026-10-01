import 'package:flutter/material.dart';
import '../../../models/cotacao_model.dart';
import '../../services/cotacao_caller.dart';
import '../../../widgets/user_banners.dart';
import '../../../windows/screens/update_profile.dart';
import '../../../models/dollar_model.dart';
import '../../constants/custom_colors.dart';

class WindowsCotacaoScreen extends StatefulWidget {
  const WindowsCotacaoScreen({super.key});

  @override
  _WindowsCotacaoScreenState createState() => _WindowsCotacaoScreenState();
}

class _WindowsCotacaoScreenState extends State<WindowsCotacaoScreen> {
  List<Cotacao> cotacoes = [];
  List<Dollar> dollarCotacoes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCotacoes();
    _fetchCotacoesDollares();
  }

  void refresh() {
    _fetchCotacoes();
    _fetchCotacoesDollares();
  }

  void _fetchCotacoes() {
    setState(() {
      isLoading = true;
    });
    CotacaoCaller().fetchCotacoes().then((data) {
      setState(() {
        cotacoes = data;
        isLoading = false;
      });
    });
  }

  void _fetchCotacoesDollares() {
    setState(() {
      isLoading = true;
    });
    CotacaoCaller().fetchCotacoesDollar().then((data) {
      setState(() {
        dollarCotacoes = data;
        isLoading = false;
      });
    });
  }

  Widget _buildTable(String title, List<TableRow> rows,
      {String? footer, String? source}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CABEÇALHO AZUL DA TABELA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: CustomColors().getDarkBlue(),
                child: Text(
                  title, // Texto variável pelo parâmetro
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // TABELA
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: CustomColors().getDarkGreenBorder(),
                    width: 1,
                  ),
                ),
                child: Table(
                  border: TableBorder.all(
                    color: CustomColors().getDarkGreenBorder(),
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: CustomColors().getHeaderTable(),
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Data",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Valor (R\$)",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...rows,
                  ],
                ),
              ),
              // FOOTER E FONTE
              if (footer != null) ...[
                const SizedBox(height: 8),
                Text(
                  footer,
                  style: TextStyle(
                    fontSize: 12,
                    color: CustomColors().getTextColorDesc(),
                  ),
                ),
              ],
              if (source != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Fonte: $source",
                      style: TextStyle(
                        fontSize: 12,
                        color: CustomColors().getTextColorDesc(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<TableRow> _buildCotacoesRows(List<Cotacao> cotacoes) {
    return [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Data',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors().getTextColor()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Valor (R\$)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors().getTextColor()),
            ),
          ),
        ],
      ),
      ...cotacoes.map((cotacao) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${cotacao.dtCotacao?.day}/${cotacao.dtCotacao?.month}/${cotacao.dtCotacao?.year}',
                style: TextStyle(color: CustomColors().getTextColor()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'R\$ ${cotacao.valor?.toStringAsFixed(2)}',
                style: TextStyle(color: CustomColors().getTextColor()),
              ),
            ),
          ],
        );
      }),
    ];
  }

  List<TableRow> _buildDollarRows(List<Dollar> cotacoes) {
    return [
      TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Data',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors().getTextColor()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Valor (R\$)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CustomColors().getTextColor()),
            ),
          ),
        ],
      ),
      ...cotacoes.map((cotacao) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${cotacao.date?.day}/${cotacao.date?.month}/${cotacao.date?.year}',
                style: TextStyle(color: CustomColors().getTextColor()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'R\$ ${cotacao.rate?.toStringAsFixed(2)}',
                style: TextStyle(color: CustomColors().getTextColor()),
              ),
            ),
          ],
        );
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          CustomColors().getLightGreenBackground(), // Fundo da tela
      appBar: UserBannerAppBar(
        screenTitle: "Cotações",
        isLoading: isLoading,
        onRefresh: refresh,
        onTapped: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const WindowsUpdateProfileScreen()));
        },
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTable(
                  'INDICADOR DO ARROZ EM CASCA CEPEA/IRGA-RS',
                  _buildCotacoesRows(cotacoes.take(5).toList()),
                  footer:
                      '* Nota: Reais por saca de 50 kg, tipo 1, 58/10, posto indústria Rio Grande do Sul, à vista (Prazo de Pagamento descontado pela taxa CDI/CETIP).',
                  source: 'CEPEA',
                ),
                const SizedBox(height: 20),
                _buildTable(
                  'Últimas Cotações do Dólar',
                  _buildDollarRows(dollarCotacoes),
                  source: 'Yahoo Finance',
                ),
              ],
            ),
    );
  }
}
