import 'package:flutter/material.dart';


/// Filtro de Referência (mês de competência) e Ano da tela Mensalidades.
///
/// O Faturar gera o título com vencimento no 5º dia útil do mês SEGUINTE à competência, então a
/// referência é traduzida para a faixa de vencimento correspondente (dataVencimentoInicio/Fim,
/// já aceitos por GET /api/contas-receber).
class MensalidadeReferenciaFiltro {
  MensalidadeReferenciaFiltro._();

  static const meses = <String>[
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  /// Anos oferecidos: do ano passado -4 até o próximo.
  static List<int> anos({DateTime? agora}) {
    final ano = (agora ?? DateTime.now()).year;
    return [for (var a = ano + 1; a >= ano - 4; a--) a];
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// [mes] 1..12 e [ano] opcionais. Mês sem ano usa o ano corrente.
  static Map<String, String> paramsVencimento(
      {int? mes, int? ano, DateTime? agora}) {
    if (mes == null && ano == null) return const {};
    final anoEfetivo = ano ?? (agora ?? DateTime.now()).year;
    if (mes != null) {
      // Vencimento cai no mês seguinte à competência (DateTime normaliza o mês 13/14).
      return {
        'dataVencimentoInicio': _iso(DateTime(anoEfetivo, mes + 1, 1)),
        'dataVencimentoFim': _iso(DateTime(anoEfetivo, mes + 2, 0)),
      };
    }
    // Ano inteiro: competências jan..dez vencem de fev/ano a jan/ano+1.
    return {
      'dataVencimentoInicio': _iso(DateTime(anoEfetivo, 2, 1)),
      'dataVencimentoFim': _iso(DateTime(anoEfetivo + 1, 2, 0)),
    };
  }
}

/// Dropdowns "Referência" e "Ano" no estilo da barra de filtros do Contas a Receber.
class MensalidadeReferenciaAnoFiltros extends StatelessWidget {
  final int? mes;
  final int? ano;
  final ValueChanged<int?> onMesChanged;
  final ValueChanged<int?> onAnoChanged;

  const MensalidadeReferenciaAnoFiltros({
    super.key,
    required this.mes,
    required this.ano,
    required this.onMesChanged,
    required this.onAnoChanged,
  });

  static const _labelStyle =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 12),
        const Text('Referência:', style: _labelStyle),
        const SizedBox(width: 8),
        SizedBox(
          width: 150,
          height: 36,
          child: DropdownButtonFormField<int?>(
            key: const Key('mensalidade-filtro-referencia'),
            value: mes,
            isDense: true,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todas', style: TextStyle(fontSize: 13))),
              for (var i = 0; i < MensalidadeReferenciaFiltro.meses.length; i++)
                DropdownMenuItem<int?>(
                    value: i + 1,
                    child: Text(MensalidadeReferenciaFiltro.meses[i],
                        style: const TextStyle(fontSize: 13))),
            ],
            onChanged: onMesChanged,
          ),
        ),
        const SizedBox(width: 12),
        const Text('Ano:', style: _labelStyle),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          height: 36,
          child: DropdownButtonFormField<int?>(
            key: const Key('mensalidade-filtro-ano'),
            value: ano,
            isDense: true,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos', style: TextStyle(fontSize: 13))),
              for (final a in MensalidadeReferenciaFiltro.anos())
                DropdownMenuItem<int?>(
                    value: a,
                    child: Text('$a', style: const TextStyle(fontSize: 13))),
            ],
            onChanged: onAnoChanged,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
