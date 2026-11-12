import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import 'mdfe_emissao_view.dart' show listaMdfeDe;

/// Busca de parceiros/servicos/NF-e cadastrados para o formulario do CT-e.
/// Funcoes puras (parse/calculo) ficam separadas da rede para serem testadas sem Flutter.

String _txt(dynamic v) => (v ?? '').toString().trim();

String _soDigitos(String v) => v.replaceAll(RegExp(r'[^0-9]'), '');

num _num(dynamic v) => v is num ? v : (num.tryParse(_txt(v).replaceAll(',', '.')) ?? 0);

/// Campos de uma parte do CT-e (remetente, destinatario...) tirados de um parceiro cadastrado.
/// Campo sem dado no cadastro vem vazio (o formulario deixa esse campo editavel).
class ParteDoParceiro {
  final String documento;
  final String nome;
  final String ie;
  final String telefone;
  final String cep;
  final String logradouro;
  final String numero;
  final String bairro;
  final String ibge;
  final String municipio;
  final String uf;

  const ParteDoParceiro({
    this.documento = '',
    this.nome = '',
    this.ie = '',
    this.telefone = '',
    this.cep = '',
    this.logradouro = '',
    this.numero = '',
    this.bairro = '',
    this.ibge = '',
    this.municipio = '',
    this.uf = '',
  });
}

ParteDoParceiro parteDoParceiro(Map<String, dynamic> p) {
  final end = p['endereco'] is Map ? Map<String, dynamic>.from(p['endereco']) : <String, dynamic>{};
  final cidade = end['cidade'] is Map ? Map<String, dynamic>.from(end['cidade']) : <String, dynamic>{};
  final estadoCidade = cidade['estado'] is Map ? Map<String, dynamic>.from(cidade['estado']) : <String, dynamic>{};
  final estado = end['estado'] is Map ? Map<String, dynamic>.from(end['estado']) : <String, dynamic>{};
  final razao = _txt(p['razaoSocial']);
  final ibge = _txt(cidade['ibge']);
  return ParteDoParceiro(
    documento: _soDigitos(_txt(p['cpf'] ?? p['cnpj'])),
    nome: razao.isNotEmpty ? razao : _txt(p['nome']),
    ie: _txt(p['ie']),
    telefone: _txt(p['telefone1']),
    cep: _soDigitos(_txt(end['cep'])),
    logradouro: _txt(end['rua'] ?? end['logradouro']),
    numero: _txt(end['numero']),
    bairro: _txt(end['bairro']),
    ibge: ibge.length == 7 ? ibge : '',
    municipio: ibge.length == 7 ? _txt(cidade['nome']) : '',
    uf: _txt(estado['uf'] ?? estadoCidade['uf']),
  );
}

/// Parceiros da empresa/tenant por nome, razao social ou documento (busca remota, 20 por vez).
Future<List<Map<String, dynamic>>> buscarParceirosCte(String termo) async {
  try {
    final r = await NetworkCaller().getRequest(
        '${ApiLinks.allParceiros}?pagina=0&tamanho=20&busca=${Uri.encodeQueryComponent(termo.trim())}');
    if (!r.isSuccess) {
      AppLogger.i.warn('buscarParceirosCte: HTTP ${r.statusCode}');
      return [];
    }
    return [
      for (final p in listaMdfeDe(r.body))
        if (_txt(p['id']).isNotEmpty)
          {
            'id': _txt(p['id']),
            'nome': _rotuloParceiro(p),
            'raw': p,
          }
    ];
  } catch (e, st) {
    AppLogger.i.error('buscarParceirosCte: erro: $e', st);
    return [];
  }
}

String _rotuloParceiro(Map<String, dynamic> p) {
  final razao = _txt(p['razaoSocial']);
  final nome = razao.isNotEmpty ? razao : _txt(p['nome']);
  final doc = _txt(p['cpf'] ?? p['cnpj']);
  return doc.isEmpty ? nome : '$nome - $doc';
}

/// Produtos do tipo servico por nome (o backend devolve `isServico`; filtra aqui).
Future<List<Map<String, dynamic>>> buscarServicosCte(String termo) async {
  try {
    final r = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/produto?nome=${Uri.encodeQueryComponent(termo.trim())}&size=50');
    if (!r.isSuccess) {
      AppLogger.i.warn('buscarServicosCte: HTTP ${r.statusCode}');
      return [];
    }
    final dados = r.body?['data'];
    if (dados is! List) return [];
    return [
      for (final e in dados.whereType<Map>())
        if (e['isServico'] == true)
          {
            'id': _txt(e['id']),
            'nome': _txt(e['nome']),
            'preco': _num(e['preco']),
          }
    ];
  } catch (e, st) {
    AppLogger.i.error('buscarServicosCte: erro: $e', st);
    return [];
  }
}

/// Resultado de buscar uma NF-e pela chave: `dados` (resumo + itens), `naoCadastrada` (404) ou `erro`.
class BuscaNfeCte {
  final Map<String, dynamic>? dados;
  final bool naoCadastrada;
  final String? erro;
  const BuscaNfeCte({this.dados, this.naoCadastrada = false, this.erro});
}

Future<BuscaNfeCte> buscarNfePorChave(String chave) async {
  try {
    final r = await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/nfe/por-chave/$chave');
    if (r.isSuccess) {
      final lista = listaMdfeDe(r.body);
      return lista.isEmpty ? const BuscaNfeCte(naoCadastrada: true) : BuscaNfeCte(dados: lista.first);
    }
    if (r.statusCode == 404) return const BuscaNfeCte(naoCadastrada: true);
    AppLogger.i.warn('buscarNfePorChave: HTTP ${r.statusCode}');
    return BuscaNfeCte(erro: 'HTTP ${r.statusCode}');
  } catch (e, st) {
    AppLogger.i.error('buscarNfePorChave: erro: $e', st);
    return BuscaNfeCte(erro: '$e');
  }
}

/// Valor da carga e produto predominante calculados a partir das NF-e cadastradas.
class CargaCalculadaCte {
  final num valor;
  final String? produto;
  const CargaCalculadaCte(this.valor, this.produto);
}

/// Soma o valor dos itens que NAO sao servico; o produto predominante e o de maior quantidade
/// (itens com a mesma descricao somam a quantidade).
CargaCalculadaCte calcularCargaCte(List<Map<String, dynamic>> nfes) {
  num valor = 0;
  final quantidades = <String, num>{};
  for (final nfe in nfes) {
    final itens = nfe['itens'];
    if (itens is! List) continue;
    for (final i in itens.whereType<Map>()) {
      if (i['isServico'] == true) continue;
      valor += _num(i['valor']);
      final nome = _txt(i['descricao']);
      if (nome.isNotEmpty) quantidades[nome] = (quantidades[nome] ?? 0) + _num(i['quantidade']);
    }
  }
  String? produto;
  num maior = -1;
  quantidades.forEach((nome, q) {
    if (q > maior) {
      maior = q;
      produto = nome;
    }
  });
  return CargaCalculadaCte(valor, produto);
}
