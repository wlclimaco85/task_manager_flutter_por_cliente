import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NFS-e Web bloqueia tomador da sessao e normaliza series de NFS-e', () {
    final source = File('lib/web/screens/details/nfse_detail_screen.dart')
        .readAsStringSync();

    expect(source, contains('_tomadorNome'));
    expect(source, contains('_parceiroEmissorId'));
    expect(source, contains("replaceAll('_', '-').toUpperCase()"));
    expect(source, contains("normalizado == 'NFS-E'"));
    expect(source, contains("serie['numeroAtual'] ?? serie['numero_atual']"));
    expect(
        source,
        contains(
            "if (_statusAtual == 'RASCUNHO' || _statusAtual == 'PENDENTE' || _statusAtual == 'REJEITADA' || _statusAtual == 'DIGITACAO' || _statusAtual == 'CRIADA')"));
    expect(source, contains("if (_statusAtual == 'CONFIRMADA' || _statusAtual == 'REJEITADA')"));
    expect(source, contains('ApiLinks.confirmarNfse(_nfseId)'));
    expect(source, contains('ApiLinks.emitirNfseNacional(_nfseId)'));
    expect(source, contains("'observacao': _observacaoCtrl.text"));
    expect(source, contains('_textArea(\'Observação\', _observacaoCtrl)'));
    expect(source, contains('_carregarDadosEmpresa()'));
    expect(source,
        contains('Adicione e salve ao menos um servico antes de confirmar.'));
    expect(source, contains('final salvo = await _salvarCabecalho'));
    expect(source, contains("label: const Text('Salvar'"));
    expect(source, contains("status = _isNovo ? 'RASCUNHO'"));
    expect(source, contains('DateTime.now()'));
  });

  test('cliente NFS-e preserva o ID no cancelamento quando informado', () {
    final source = File('lib/services/nfse_caller.dart').readAsStringSync();

    expect(source, contains('int? nfseId'));
    expect(source, contains("if (nfseId != null) 'nfseId': nfseId"));
  });
}
