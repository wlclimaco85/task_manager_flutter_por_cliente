import 'package:flutter/material.dart';

// Modelo para configuração dos botões
class NegotiationButton {
  final List<String> visibleForTypes;
  final IconData icon;
  final String label;
  final Color color;
  final Function(BuildContext, dynamic) onPressed;

  NegotiationButton({
    required this.visibleForTypes,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
}

class NegotiationCard extends StatelessWidget {
  final dynamic negotiation;
  final List<NegotiationButton> buttons;
  final Color cardColor;
  final Color borderColor;
  final double borderRadius;

  const NegotiationCard({
    super.key,
    required this.negotiation,
    required this.buttons,
    this.cardColor = const Color(0xFFF5FDF7),
    this.borderColor = const Color(0xFF015F0F),
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNegotiationDetails(),
            const SizedBox(height: 8),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNegotiationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem('Comprador ID: ${negotiation.compradorId}'),
        _buildDetailItem('Quantidade: ${negotiation.qtdSacos}'),
        _buildDetailItem('Valor por saco: R\$${negotiation.vlrSacos}'),
        _buildDetailItem(
          'Status: ${_getStatusText(negotiation.status)} / ${_getTipoText(negotiation.tipo)}',
        ),
      ],
    );
  }

  Widget _buildDetailItem(String text) {
    return SizedBox(
      width: double.infinity,
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final filteredButtons = buttons
        .where((btn) => btn.visibleForTypes.contains(negotiation.tipo))
        .toList();

    if (filteredButtons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:
          filteredButtons.map((btn) => _buildButton(context, btn)).toList(),
    );
  }

  Widget _buildButton(BuildContext context, NegotiationButton config) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(config.icon, color: config.color),
          onPressed: () => config.onPressed(context, negotiation),
        ),
        Text(
          config.label,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
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

  String _getTipoText(String tipo) {
    switch (tipo) {
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
}

class ProductCard extends StatelessWidget {
  final dynamic product;
  final Widget image;
  final List<NegotiationButton> negotiationButtons;
  final Color cardColor;
  final Color borderColor;
  final double borderRadius;

  const ProductCard({
    super.key,
    required this.product,
    required this.image,
    required this.negotiationButtons,
    this.cardColor = const Color(0xFFE7F7E9),
    this.borderColor = const Color(0xFF015F0F),
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductHeader(),
            const SizedBox(height: 8),
            const Text('Negociações:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ..._buildNegotiationsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Row(
      children: [
        Expanded(flex: 2, child: image),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.tipo ?? 'Sem descrição',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNegotiationsList(BuildContext context) {
    return List.generate((product.negociacoes as List).length, (i) {
      final negotiation = product.negociacoes[i];
      return NegotiationCard(
        negotiation: negotiation,
        buttons: negotiationButtons,
        cardColor: const Color(0xFFF5FDF7),
        borderColor: borderColor,
        borderRadius: borderRadius,
      );
    });
  }
}
