import 'package:flutter/foundation.dart';

import '../models/nfce/item_venda_model.dart';
import '../models/nfce/nfce_resultado_model.dart';
import '../models/nfce/venda_nfce_model.dart';
import '../utils/tenant_context.dart';
import 'nfce_service.dart';

/// Gerencia o estado da venda/PDV NFC-e.
/// Usado com Provider para notificar a UI sobre mudanças.
class NfceProvider extends ChangeNotifier {
  final NfceService _service;

  NfceProvider({NfceService? service}) : _service = service ?? NfceService();

  final List<ItemVendaModel> _carrinho = [];
  List<ItemVendaModel> get carrinho => List.unmodifiable(_carrinho);

  final List<PagamentoModel> _pagamentos = [];
  List<PagamentoModel> get pagamentos => List.unmodifiable(_pagamentos);

  String? clienteCpfCnpj;
  NfceResultadoModel? ultimaNfce;
  int? ultimoVendaId;
  bool emProcessamento = false;
  String? erro;

  double get subtotal =>
      _carrinho.fold(0.0, (s, i) => s + (i.precoUnitario * i.quantidade));

  double get descontoTotal =>
      _carrinho.fold(0.0, (s, i) => s + i.desconto) + _descontoGeral;

  double _descontoGeral = 0;
  double get descontoGeral => _descontoGeral;
  set descontoGeral(double v) {
    _descontoGeral = v;
    notifyListeners();
  }

  double get total => subtotal - descontoTotal;

  double get totalPago => _pagamentos.fold(0.0, (s, p) => s + p.valor);

  double get troco => totalPago > total ? totalPago - total : 0;

  void adicionarItem(Map<String, dynamic> produto, {int quantidade = 1}) {
    final id = produto['id'] as int? ?? 0;
    final existente = _carrinho.indexWhere((i) => i.produtoId == id);
    if (existente >= 0) {
      _carrinho[existente].quantidade += quantidade;
    } else {
      _carrinho.add(ItemVendaModel(
        produtoId: id,
        nomeProduto: produto['nome'] as String? ?? 'Produto',
        codigoProduto: produto['codigo'] as String?,
        precoUnitario:
            (produto['preco'] ?? produto['precoVenda'] ?? 0).toDouble(),
        quantidade: quantidade,
      ));
    }
    notifyListeners();
  }

  void removerItem(int index) {
    if (index >= 0 && index < _carrinho.length) {
      _carrinho.removeAt(index);
      notifyListeners();
    }
  }

  void atualizarQuantidade(int index, int novaQtd) {
    if (index >= 0 && index < _carrinho.length) {
      if (novaQtd <= 0) {
        removerItem(index);
      } else {
        _carrinho[index].quantidade = novaQtd;
        notifyListeners();
      }
    }
  }

  void limparCarrinho() {
    _carrinho.clear();
    _pagamentos.clear();
    clienteCpfCnpj = null;
    _descontoGeral = 0;
    ultimaNfce = null;
    ultimoVendaId = null;
    erro = null;
    notifyListeners();
  }

  void adicionarPagamento(String formaPagamento, double valor) {
    _pagamentos.add(PagamentoModel(formaPagamento: formaPagamento, valor: valor));
    notifyListeners();
  }

  void removerPagamento(int index) {
    if (index >= 0 && index < _pagamentos.length) {
      _pagamentos.removeAt(index);
      notifyListeners();
    }
  }

  void limparPagamentos() {
    _pagamentos.clear();
    notifyListeners();
  }

  Map<String, dynamic>? buildVendaJson() {
    final empresaId = TenantContext.empresaId;
    if (empresaId == null || _carrinho.isEmpty) {
      return null;
    }

    final venda = VendaNfceModel(
      empresaId: empresaId,
      itens: _carrinho,
      pagamentos: _pagamentos,
      clienteCpfCnpj: clienteCpfCnpj,
      desconto: _descontoGeral,
    );

    return venda.toJson();
  }

  Future<NfceResultadoModel?> emitirNfce() async {
    final vendaJson = buildVendaJson();
    if (vendaJson == null) {
      erro = TenantContext.empresaId == null
          ? 'Empresa não identificada. Faça login novamente.'
          : 'Carrinho vazio.';
      notifyListeners();
      return null;
    }

    emProcessamento = true;
    erro = null;
    notifyListeners();

    try {
      final vendaId = await _service.criarVenda(vendaJson);
      ultimoVendaId = vendaId;
      final resultado = await _service.emitirNfce(vendaId, vendaJson: vendaJson);
      ultimaNfce = resultado;
      return resultado;
    } on NfceException catch (e) {
      erro = e.message;
      return null;
    } catch (e) {
      erro = 'Erro inesperado: $e';
      return null;
    } finally {
      emProcessamento = false;
      notifyListeners();
    }
  }
}
