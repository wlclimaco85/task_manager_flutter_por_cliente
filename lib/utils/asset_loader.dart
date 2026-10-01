import 'package:flutter/material.dart';

/// Utilitario para carregar assets de imagem com fallback visual consistente.
///
/// A chave deve ser a mesma declarada no pubspec.yaml, por exemplo
/// `assets/images/logo_contabilidade.jpg`. No Flutter web, o engine converte
/// essa chave para a URL em `/assets/assets/images/...`.
class AssetLoader {
  /// Mantem a chave original do asset.
  ///
  /// Prefixar `assets/` aqui gera URL web com `assets/assets/assets/...`.
  /// Fix WR-03: valida path traversal — bloqueia `..` e `/` absoluto.
  static String correctAssetPath(String assetPath) {
    // Validação: path não pode conter traversal de diretório
    if (assetPath.contains('..') || assetPath.startsWith('/')) {
      throw ArgumentError(
        'Invalid asset path: $assetPath. Path traversal not allowed.',
      );
    }

    var normalized = assetPath.trim().replaceAll('\\', '/');
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    while (normalized.startsWith('assets/assets/')) {
      normalized = normalized.substring('assets/'.length);
    }
    return normalized;
  }

  /// Carrega imagem com fallback sem overflow para miniaturas pequenas.
  static Widget loadImage(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    final correctedPath = correctAssetPath(assetPath);
    return Image.asset(
      correctedPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        final isSmall =
            (width != null && width < 72) || (height != null && height < 72);

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: isSmall
              ? const Icon(Icons.broken_image, color: Colors.red, size: 16)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      'Asset nao encontrado:\n$assetPath',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  ],
                ),
        );
      },
    );
  }

  /// Carrega imagem com errorBuilder customizado.
  static Widget loadImageWithCustomError(
    String assetPath, {
    required ImageErrorWidgetBuilder errorBuilder,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    final correctedPath = correctAssetPath(assetPath);
    return Image.asset(
      correctedPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: errorBuilder,
    );
  }
}
