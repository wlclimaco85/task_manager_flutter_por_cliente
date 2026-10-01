import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/ged_file_type.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';

void main() {
  group('corParaTipoArquivo', () {
    test('application/pdf retorna fileTypePdf', () {
      expect(corParaTipoArquivo('application/pdf'), GridColors.fileTypePdf);
    });

    test('image/png retorna fileTypeImage', () {
      expect(corParaTipoArquivo('image/png'), GridColors.fileTypeImage);
    });

    test('application/vnd.ms-excel retorna fileTypeSheet', () {
      expect(corParaTipoArquivo('application/vnd.ms-excel'),
          GridColors.fileTypeSheet);
    });

    test('text/csv retorna fileTypeSheet', () {
      expect(corParaTipoArquivo('text/csv'), GridColors.fileTypeSheet);
    });

    test('application/msword retorna fileTypeWord', () {
      expect(corParaTipoArquivo('application/msword'), GridColors.fileTypeWord);
    });

    test('tipo desconhecido retorna fileTypeDefault', () {
      expect(corParaTipoArquivo('text/plain'), GridColors.fileTypeDefault);
    });
  });

  group('iconeParaTipoArquivo', () {
    test('application/pdf retorna picture_as_pdf', () {
      expect(iconeParaTipoArquivo('application/pdf'), Icons.picture_as_pdf);
    });

    test('image/png retorna image', () {
      expect(iconeParaTipoArquivo('image/png'), Icons.image);
    });

    test('application/vnd.ms-excel retorna table_chart', () {
      expect(iconeParaTipoArquivo('application/vnd.ms-excel'), Icons.table_chart);
    });

    test('text/csv retorna table_chart', () {
      expect(iconeParaTipoArquivo('text/csv'), Icons.table_chart);
    });

    test('application/msword retorna description', () {
      expect(iconeParaTipoArquivo('application/msword'), Icons.description);
    });

    test('tipo desconhecido retorna insert_drive_file', () {
      expect(iconeParaTipoArquivo('text/plain'), Icons.insert_drive_file);
    });
  });
}
