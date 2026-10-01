import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

import 'grid_colors.dart';

/// Cor associada ao tipo (MIME) de arquivo no GED.
Color corParaTipoArquivo(String tipo) {
  if (tipo.contains('pdf')) return GridColors.fileTypePdf;
  if (tipo.startsWith('image/')) return GridColors.fileTypeImage;
  if (tipo.contains('excel') || tipo.contains('sheet') || tipo.contains('csv')) {
    return GridColors.fileTypeSheet;
  }
  if (tipo.contains('word') || tipo.contains('doc')) {
    return GridColors.fileTypeWord;
  }
  return GridColors.fileTypeDefault;
}

/// Icone associado ao tipo (MIME) de arquivo no GED.
IconData iconeParaTipoArquivo(String tipo) {
  if (tipo.contains('pdf')) return Icons.picture_as_pdf;
  if (tipo.startsWith('image/')) return Icons.image;
  if (tipo.contains('excel') || tipo.contains('sheet') || tipo.contains('csv')) {
    return Icons.table_chart;
  }
  if (tipo.contains('word') || tipo.contains('doc')) return Icons.description;
  return Icons.insert_drive_file;
}

String gedMimeTypeForFileName(String fileName) {
  return lookupMimeType(fileName) ?? 'application/octet-stream';
}
