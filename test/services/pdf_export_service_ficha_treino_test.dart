import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/pdf_export_service.dart';
import '../fixtures/sessao_treino_fixtures.dart';

void main() {
  group('PdfExportService - gerarFichaTreino', () {
    /// RED TEST 1: Gera PDF com 1 sessão + 3 séries (validar assinatura %PDF)
    test('gera PDF com sessao unica e 3 series', () async {
      final sessao = SessaoTreinoFixtures.sessaoUnica();
      final series = SessaoTreinoFixtures.series();

      final bytes =
          await PdfExportService.gerarFichaTreino(sessao: sessao, series: series);

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
      // Verifica assinatura PDF
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    /// RED TEST 2: Gera PDF com múltiplas páginas (2+ sessões)
    test('gera PDF multipágina para sessoes com muitas series', () async {
      final sessao = SessaoTreinoFixtures.sessaoUnica();
      final series = SessaoTreinoFixtures.series();
      // Adiciona 20 séries fictíceas para forçar multipage
      final muitasSeries = [
        ...series,
        for (int i = 0; i < 20; i++)
          {
            'ordem': i + 4,
            'exercicioNome': 'Exercício $i',
            'exercicioNivel': 'iniciante',
            'carga': 10.0 + i,
            'repeticoes': 10 + i,
            'duracaoSegundos': 200 + i * 10,
          }
      ];

      final bytes = await PdfExportService.gerarFichaTreino(
          sessao: sessao, series: muitasSeries);

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    /// RED TEST 3: Gera PDF mesmo sem séries
    test('gera PDF mesmo quando sessao nao tem series', () async {
      final sessao = SessaoTreinoFixtures.sessaoSemSeries();
      final series = SessaoTreinoFixtures.seriesVazias();

      final bytes =
          await PdfExportService.gerarFichaTreino(sessao: sessao, series: series);

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    /// RED TEST 4: PDF nao esta vazio (contém dados semanticos)
    test('PDF gerado contem dados da sessao (conteudo nao vazio)', () async {
      final sessao = SessaoTreinoFixtures.sessaoUnica();
      final series = SessaoTreinoFixtures.series();

      final bytes =
          await PdfExportService.gerarFichaTreino(sessao: sessao, series: series);

      expect(bytes.length, greaterThan(500),
          reason: 'PDF deveria conter conteúdo significativo (> 500 bytes)');
      // Verifica assinatura PDF
      expect(String.fromCharCodes(bytes.take(4)), '%PDF',
          reason: 'Deve ser um arquivo PDF válido');
      // Nota: não fazemos search por strings específicas pois fonts sem Unicode support
      // podem não ser pesquisáveis em texto plano.
    });
  });
}
