import 'package:intl/intl.dart';

class OperacaoAcao {
  final int? id;
  final String ticker;
  final String tipo;
  final double quantidade;
  final double precoUnitario;
  final DateTime dataOperacao;
  final String? corretora;
  final double taxas;
  final String? observacao;
  final double? custoTotal;

  const OperacaoAcao({
    this.id,
    required this.ticker,
    required this.tipo,
    required this.quantidade,
    required this.precoUnitario,
    required this.dataOperacao,
    this.corretora,
    this.taxas = 0,
    this.observacao,
    this.custoTotal,
  });

  factory OperacaoAcao.fromJson(Map<String, dynamic> j) => OperacaoAcao(
        id: j['id'],
        ticker: j['ticker'] ?? '',
        tipo: j['tipo'] ?? 'COMPRA',
        quantidade: (j['quantidade'] ?? 0).toDouble(),
        precoUnitario: (j['precoUnitario'] ?? 0).toDouble(),
        dataOperacao: j['dataOperacao'] != null
            ? DateTime.parse(j['dataOperacao'])
            : DateTime.now(),
        corretora: j['corretora'],
        taxas: (j['taxas'] ?? 0).toDouble(),
        observacao: j['observacao'],
        custoTotal:
            j['custoTotal'] != null ? (j['custoTotal']).toDouble() : null,
      );

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'tipo': tipo,
        'quantidade': quantidade,
        'precoUnitario': precoUnitario,
        'dataOperacao': DateFormat('yyyy-MM-dd').format(dataOperacao),
        if (corretora != null) 'corretora': corretora,
        'taxas': taxas,
        if (observacao != null) 'observacao': observacao,
      };
}

class CorretoraInvestimento {
  final int? id;
  final String nome;
  final double saldo;
  final bool ativa;
  final String? observacao;

  const CorretoraInvestimento({
    this.id,
    required this.nome,
    required this.saldo,
    this.ativa = true,
    this.observacao,
  });

  factory CorretoraInvestimento.fromJson(Map<String, dynamic> j) =>
      CorretoraInvestimento(
        id: j['id'],
        nome: j['nome'] ?? '',
        saldo: (j['saldo'] ?? 0).toDouble(),
        ativa: j['ativa'] ?? true,
        observacao: j['observacao'],
      );
}

class PosicaoAcao {
  final String ticker;
  final String nomeAtivo;
  final double quantidade;
  final double precoMedio;
  final double precoAtual;
  final double variacaoDia;
  final double variacaoDiaPercent;
  final double valorAtual;
  final double ganhoPerda;
  final double ganhoPerdaPercent;
  final double participacaoCarteira;
  final bool cotacaoDisponivel;

  const PosicaoAcao({
    required this.ticker,
    required this.nomeAtivo,
    required this.quantidade,
    required this.precoMedio,
    required this.precoAtual,
    required this.variacaoDia,
    required this.variacaoDiaPercent,
    required this.valorAtual,
    required this.ganhoPerda,
    required this.ganhoPerdaPercent,
    required this.participacaoCarteira,
    required this.cotacaoDisponivel,
  });

  factory PosicaoAcao.fromJson(Map<String, dynamic> j) => PosicaoAcao(
        ticker: j['ticker'] ?? '',
        nomeAtivo: j['nomeAtivo'] ?? j['ticker'] ?? '',
        quantidade: (j['quantidade'] ?? 0).toDouble(),
        precoMedio: (j['precoMedio'] ?? 0).toDouble(),
        precoAtual: (j['precoAtual'] ?? 0).toDouble(),
        variacaoDia: (j['variacaoDia'] ?? 0).toDouble(),
        variacaoDiaPercent: (j['variacaoDiaPercent'] ?? 0).toDouble(),
        valorAtual: (j['valorAtual'] ?? 0).toDouble(),
        ganhoPerda: (j['ganhoPerda'] ?? 0).toDouble(),
        ganhoPerdaPercent: (j['ganhoPerdaPercent'] ?? 0).toDouble(),
        participacaoCarteira: (j['participacaoCarteira'] ?? 0).toDouble(),
        cotacaoDisponivel: j['cotacaoDisponivel'] ?? false,
      );

  bool get positivo => ganhoPerda >= 0;
  bool get variacaoDiaPositiva => variacaoDia >= 0;
}

class CarteiraResumo {
  final double totalInvestido;
  final double valorAtual;
  final double ganhoPerda;
  final double ganhoPerdaPercent;
  final double variacaoDiaTotal;
  final double variacaoDiaTotalPercent;
  final List<PosicaoAcao> posicoes;

  const CarteiraResumo({
    required this.totalInvestido,
    required this.valorAtual,
    required this.ganhoPerda,
    required this.ganhoPerdaPercent,
    required this.variacaoDiaTotal,
    required this.variacaoDiaTotalPercent,
    required this.posicoes,
  });

  factory CarteiraResumo.fromJson(Map<String, dynamic> j) {
    final raw = j['posicoes'] ?? j['data']?['posicoes'] ?? [];
    return CarteiraResumo(
      totalInvestido: (j['totalInvestido'] ?? 0).toDouble(),
      valorAtual: (j['valorAtual'] ?? 0).toDouble(),
      ganhoPerda: (j['ganhoPerda'] ?? 0).toDouble(),
      ganhoPerdaPercent: (j['ganhoPerdaPercent'] ?? 0).toDouble(),
      variacaoDiaTotal: (j['variacaoDiaTotal'] ?? 0).toDouble(),
      variacaoDiaTotalPercent: (j['variacaoDiaTotalPercent'] ?? 0).toDouble(),
      posicoes: (raw as List).map((e) => PosicaoAcao.fromJson(e)).toList(),
    );
  }

  bool get ganhoPositivo => ganhoPerda >= 0;
  bool get variacaoDiaPositiva => variacaoDiaTotal >= 0;
}
