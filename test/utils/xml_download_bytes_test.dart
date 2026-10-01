import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Bug de produção (card #503, apontado desde 31/07, reproduzido em 5
/// ciclos de QA consecutivos): download de XML de NF-e usava
/// `Uint8List.fromList(r.body.codeUnits)` em vez de `r.bodyBytes` em
/// `nfe_grid_screen.dart`/`details/nfe_detail_screen.dart` (mobile, web,
/// windows) -- corrompia qualquer caractere acentuado no XML baixado,
/// gerando um arquivo com mojibake ou, em produção real, um XML de NF-e
/// tecnicamente inválido.
///
/// Causa raiz: `http.Response.body` é a String já decodificada como UTF-8
/// pelo pacote `http`. `String.codeUnits` devolve as UNIDADES UTF-16 dessa
/// String (o encoding interno do Dart), não os bytes UTF-8 originais --
/// para qualquer caractere fora do ASCII (todo acento em português), os
/// dois divergem. `http.Response.bodyBytes` é o byte array HTTP original,
/// sempre correto independente de acentuação.
///
/// Este teste isola exatamente esse bug (sem precisar montar os widgets
/// das 6 telas afetadas): simula um corpo de resposta HTTP com
/// acentuação real de XML de NF-e e prova que `bodyBytes` preserva o
/// conteúdo original, enquanto o padrão antigo (`codeUnits`) o corrompe.
void main() {
  group('Download de XML — bytes corretos vs. bug de codeUnits', () {
    // Trecho real de tag de NF-e com acentuação, o tipo de conteúdo que
    // disparava o bug em produção.
    const xmlComAcentos =
        '<nfeProc><infAdic><infCpl>Observações: mercadoria à vista, não sujeita a substituição tributária</infCpl></infAdic></nfeProc>';

    // Content-type com charset=utf-8 explícito -- é assim que o backend
    // real responde (JSON/XML com acentuação); sem isso, o pacote http
    // assume latin1 por padrão para decodificar `.body`, o que mascara o
    // bug (round-trip byte-a-byte "por acidente" nesse caso sintético).
    const headersUtf8 = {'content-type': 'application/xml; charset=utf-8'};

    test('http.Response.bodyBytes preserva o XML original com acentos', () {
      final bytesOriginais = utf8.encode(xmlComAcentos);
      final response = http.Response.bytes(bytesOriginais, 200, headers: headersUtf8);

      // bodyBytes (fix aplicado no card #503) -- byte array HTTP original.
      final bytesBaixados = response.bodyBytes;

      expect(bytesBaixados, equals(Uint8List.fromList(bytesOriginais)));
      expect(utf8.decode(bytesBaixados), equals(xmlComAcentos));
    });

    test(
        'BUG reproduzido: Uint8List.fromList(response.body.codeUnits) corrompe '
        'o XML com acentos (padrão antigo, removido no card #503)', () {
      final bytesOriginais = utf8.encode(xmlComAcentos);
      final response = http.Response.bytes(bytesOriginais, 200, headers: headersUtf8);

      // Padrão antigo (bugado) que existia nas 6 telas antes do fix.
      final bytesComBug = Uint8List.fromList(response.body.codeUnits);

      // Prova que o bug é real: os bytes NÃO batem com o original, e
      // decodificar como UTF-8 não reproduz o texto original.
      expect(bytesComBug, isNot(equals(Uint8List.fromList(bytesOriginais))),
          reason: 'codeUnits deveria divergir do UTF-8 original quando há '
              'acentuação -- se este assert falhar, o bug pode ter deixado '
              'de existir por outro motivo (ex.: mudança no pacote http) e '
              'o teste precisa ser revisto, não apenas removido.');

      String decodificadoComBug;
      try {
        decodificadoComBug = utf8.decode(bytesComBug);
      } catch (_) {
        decodificadoComBug = '<falhou ao decodificar -- XML corrompido>';
      }
      expect(decodificadoComBug, isNot(equals(xmlComAcentos)));
    });

    test('conteúdo só-ASCII (sem acento) não expõe o bug -- por isso passou despercebido',
        () {
      const xmlSoAscii = '<nfeProc><infAdic><infCpl>Sem acentuacao</infCpl></infAdic></nfeProc>';
      final bytesOriginais = utf8.encode(xmlSoAscii);
      final response = http.Response.bytes(bytesOriginais, 200, headers: headersUtf8);

      final bytesComBug = Uint8List.fromList(response.body.codeUnits);

      // Para ASCII puro, codeUnits e UTF-8 bytes coincidem -- exatamente
      // por isso o bug sobreviveu sem ser notado em testes manuais com
      // dados de exemplo sem acentuação.
      expect(bytesComBug, equals(Uint8List.fromList(bytesOriginais)));
    });
  });
}
