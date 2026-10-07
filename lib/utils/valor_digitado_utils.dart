/// Converte o texto de um campo monetario (aceita "1.097,47", "1097,47" ou "1097.47").
/// So remove o ponto quando ha virgula decimal: "1097.47" vindo do backend nao pode
/// virar 109747.
double? parseValorDigitado(String texto) {
  var t = texto.trim();
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(t);
}
