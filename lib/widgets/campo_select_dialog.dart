import 'package:flutter/material.dart';

import '../services/menu_publicado_service.dart';
import '../utils/grid_colors.dart';
import '../utils/planilha_formula.dart';

/// Nomes (minusculos) dos parametros :nome do SELECT. Empresa e parceiro vem do login, entao ficam de fora.
List<String> parametrosDoSelect(String sql) => {
      for (final m in RegExp(r'(?<![:\w]):([A-Za-z_]\w*)').allMatches(sql)) m[1]!.toLowerCase()
    }.where((p) => p != 'empresaid' && p != 'parceiroid').toList();

/// Campo preenchido por SELECT: uma coluna da planilha e' o resultado e cada :parametro vem de outra, na mesma linha.
class CampoSelectDialog extends StatefulWidget {
  final String celula;
  final FonteModelo? editando;

  /// Letra da coluna -> titulo da linha 1, para o usuario reconhecer a coluna.
  final Map<String, String> titulos;

  const CampoSelectDialog({super.key, required this.celula, this.editando, this.titulos = const {}});

  @override
  State<CampoSelectDialog> createState() => _CampoSelectDialogState();
}

class _CampoSelectDialogState extends State<CampoSelectDialog> {
  late final _celula = TextEditingController(text: widget.editando?.celula ?? widget.celula);
  late final _sql = TextEditingController(text: widget.editando?.sql ?? '');
  late final Map<String, String> _colunas = Map.of(widget.editando?.parametros ?? const {});
  String? _erro;

  @override
  void dispose() {
    _celula.dispose();
    _sql.dispose();
    super.dispose();
  }

  void _salvar() {
    final celula = _celula.text.trim().toUpperCase();
    final alvo = posicao(celula);
    final parametros = parametrosDoSelect(_sql.text);
    String? erro;
    if (alvo == null) {
      erro = 'Informe a célula do primeiro campo, por exemplo C2.';
    } else if (parametros.isEmpty) {
      erro = 'Use ao menos um parâmetro no SELECT, por exemplo :codigo.';
    } else if (parametros.any((p) => _colunas[p] == null)) {
      erro = 'Escolha a coluna de cada parâmetro.';
    } else if (parametros.any((p) => _colunas[p] == nomeColuna(alvo.$2))) {
      erro = 'O campo não pode usar a própria coluna como parâmetro.';
    }
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.pop(
        context,
        FonteModelo(
            celula: celula,
            sql: _sql.text.trim(),
            cabecalho: false,
            parametros: {for (final p in parametros) p: _colunas[p]!}));
  }

  @override
  Widget build(BuildContext context) {
    final parametros = parametrosDoSelect(_sql.text);
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.manage_search, color: GridColors.primary),
        SizedBox(width: 8),
        Flexible(child: Text('Campo por SELECT')),
      ]),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              key: const Key('campo-celula'),
              controller: _celula,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Célula do primeiro campo',
                  helperText: 'Preenche desta linha para baixo. Escolha a primeira linha de dados, não o título.',
                  helperMaxLines: 2),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('campo-sql'),
              controller: _sql,
              minLines: 4,
              maxLines: 10,
              style: const TextStyle(fontFamily: 'monospace'),
              onChanged: (_) => setState(() => _erro = null),
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'SELECT que devolve o valor do campo',
                  hintText: 'SELECT preco FROM produto WHERE id = :codigo',
                  helperText: 'Usa a primeira coluna da primeira linha. Cada :nome vira um parâmetro abaixo. '
                      'Empresa e parceiro do login são filtrados automaticamente.',
                  helperMaxLines: 3),
            ),
            for (final p in parametros) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('param-$p'),
                initialValue: _colunas[p],
                isExpanded: true,
                menuMaxHeight: 320,
                decoration: InputDecoration(border: const OutlineInputBorder(), labelText: ':$p vem da coluna'),
                items: [
                  for (var c = 0; c < kPlanilhaMaxColunas; c++)
                    DropdownMenuItem(
                        value: nomeColuna(c),
                        child: Text(
                            (widget.titulos[nomeColuna(c)] ?? '').isEmpty
                                ? nomeColuna(c)
                                : '${nomeColuna(c)} - ${widget.titulos[nomeColuna(c)]}',
                            overflow: TextOverflow.ellipsis))
                ],
                onChanged: (v) => setState(() {
                  if (v != null) _colunas[p] = v;
                  _erro = null;
                }),
              ),
            ],
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_erro!, style: const TextStyle(color: GridColors.error)),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        FilledButton(onPressed: _salvar, child: const Text('Salvar campo')),
      ],
    );
  }
}
