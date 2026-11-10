import 'dart:convert';

/// Nomes dos meses (1-12) exibidos no popUp "Faturar" da NFS-e.
const List<String> nfseMesesPt = [
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

String nfseNomeMes(int mes) =>
    mes >= 1 && mes <= 12 ? nfseMesesPt[mes - 1] : '';

/// Competência padrão: o mês anterior ao de [hoje] (janeiro -> dezembro do ano anterior).
({int mes, int ano}) nfseCompetenciaPadrao(DateTime hoje) {
  final anterior = DateTime(hoje.year, hoje.month - 1, 1);
  return (mes: anterior.month, ano: anterior.year);
}

/// Lê um número do backend (num ou String com ponto) e devolve null se inválido.
double? nfseParseNumero(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString().trim().replaceAll(',', '.'));
}

/// Converte o texto do campo (aceita "1.097,47", "1097,47" ou "1097.47").
double? nfseParseValorDigitado(String texto) {
  var t = texto.trim();
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(t);
}

/// Formata para o campo de texto com vírgula decimal (ex.: 1097.47 -> "1097,47").
String nfseFormatarValor(double? valor) =>
    valor == null ? '' : valor.toStringAsFixed(2).replaceAll('.', ',');

/// Valor padrão do popUp: sempre o valor mensal do parceiro tomador (nunca o da última nota).
String nfseValorPadrao(Map<String, dynamic>? resumo) =>
    nfseFormatarValor(nfseParseNumero(resumo?['valorMensal']));

/// Converte "2026-02-06" em "06/02/2026"; devolve o texto original se nao for ISO.
String nfseFormatarDataIso(String iso) {
  final partes = iso.split('T').first.split('-');
  if (partes.length != 3) return iso;
  return '${partes[2]}/${partes[1]}/${partes[0]}';
}

/// Valida o valor digitado contra o limite mensal. Retorna a mensagem de erro ou null.
/// A soma das notas não canceladas do mês mais o novo valor não pode passar do valor mensal.
String? nfseValidarValorFaturar({
  required double? valor,
  required double? valorMensal,
  required double jaFaturado,
}) {
  if (valor == null || valor <= 0) return 'Informe um valor maior que zero.';
  if (valorMensal == null || valorMensal <= 0) {
    return 'Tomador sem valor mensal cadastrado.';
  }
  final saldo = (valorMensal - jaFaturado).clamp(0, double.infinity);
  // tolerancia de 1 centavo contra erro de ponto flutuante
  if (jaFaturado + valor > valorMensal + 0.005) {
    return 'Valor acima do saldo do mês: ${nfseFormatarValor(saldo.toDouble())} '
        '(mensal ${nfseFormatarValor(valorMensal)}, já faturado ${nfseFormatarValor(jaFaturado)}).';
  }
  return null;
}

/// Extrai a mensagem completa de erro do corpo de uma resposta HTTP do backend
/// (`{"message": "..."}`), com fallback para o corpo cru e para o status.
String nfseMensagemErroHttp(int statusCode, String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      for (final chave in const ['message', 'mensagem', 'error', 'erro']) {
        final valor = decoded[chave]?.toString().trim();
        if (valor != null && valor.isNotEmpty) return valor;
      }
    }
  } catch (_) {
    // corpo nao e JSON: usa texto cru abaixo
  }
  final cru = body.trim();
  return cru.isNotEmpty ? cru : 'Erro HTTP $statusCode ao faturar a NFS-e.';
}

/// Resultado do faturamento exibido no popUp de retorno.
class NfseFaturarResultado {
  final int? nfseId;
  final String? numeroNfse;
  final int? mensalidadeId;
  final int? contaPagarId;
  final int? contaReceberId;
  final int? arquivoGedId;
  final bool gedPreenchido;
  final bool pdfGerado;
  final String? dataVencimento;
  final String mensagem;

  const NfseFaturarResultado({
    this.nfseId,
    this.numeroNfse,
    this.mensalidadeId,
    this.contaPagarId,
    this.contaReceberId,
    this.arquivoGedId,
    this.gedPreenchido = false,
    this.pdfGerado = false,
    this.dataVencimento,
    this.mensagem = '',
  });

  factory NfseFaturarResultado.fromJson(Map<String, dynamic> json) {
    int? inteiro(dynamic v) => v == null ? null : int.tryParse(v.toString());
    return NfseFaturarResultado(
      nfseId: inteiro(json['nfseId']),
      numeroNfse: json['numeroNfse']?.toString(),
      mensalidadeId: inteiro(json['mensalidadeId']),
      contaPagarId: inteiro(json['contaPagarId']),
      contaReceberId: inteiro(json['contaReceberId']),
      arquivoGedId: inteiro(json['arquivoGedId']),
      gedPreenchido: json['gedPreenchido'] == true,
      pdfGerado: json['pdfGerado'] == true,
      dataVencimento: json['dataVencimento']?.toString(),
      mensagem: json['mensagem']?.toString() ?? '',
    );
  }
}
