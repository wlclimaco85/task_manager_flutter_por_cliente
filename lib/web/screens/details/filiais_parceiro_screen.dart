import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../services/network_caller.dart';

class FiliaisParceiroScreen extends StatefulWidget {
  final int matrizId;
  final int? empresaId;
  final SecurityCheck hasPermission;

  const FiliaisParceiroScreen({
    super.key,
    required this.matrizId,
    this.empresaId,
    required this.hasPermission,
  });

  @override
  State<FiliaisParceiroScreen> createState() => _FiliaisParceiroScreenState();
}

class _FiliaisParceiroScreenState extends State<FiliaisParceiroScreen> {
  Key _gridKey = UniqueKey();

  void _vincularFilial() {
    String? selectedParceiroId;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Vincular Filial Existente'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Selecione um parceiro para vincular como filial:'),
                    const SizedBox(height: 16),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: DropdownHelpers.parceirosPorEmpresa(widget.empresaId?.toString()),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('Erro ao carregar parceiros');
                        }
                        final options = snapshot.data!
                            .where((p) => p['id']?.toString() != widget.matrizId.toString())
                            .toList();
                        
                        return DropdownButtonFormField<String>(
                          // Fix (2026-09-16): sem isExpanded o valor
                          // selecionado (nome/razao social longos, ex.
                          // "Lanna Comercio de Cereais Importacao e
                          // Exportacao LTDA") nao quebra nem trunca e
                          // estoura a largura do dialog (overflow reportado
                          // pelo usuario). isExpanded + ellipsis no item
                          // resolvem sem mudar o layout do dialog.
                          isExpanded: true,
                          // itemHeight: null -- pedido do usuario (2026-09-16)
                          // "coloque o cnpj embaixo do nome" precisa de 2
                          // linhas por item; itemHeight fixo do Material
                          // DropdownButton nao comporta isso, entao usamos
                          // altura variavel (suportado desde o Flutter que
                          // este projeto usa).
                          itemHeight: null,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          value: selectedParceiroId,
                          items: options.map((e) {
                            final nome = e['nome']?.toString() ??
                                e['razaoSocial']?.toString() ??
                                '';
                            final cpfCnpj = e['cpf']?.toString().trim() ?? '';
                            return DropdownMenuItem(
                              value: e['id']?.toString(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      nome,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    if (cpfCnpj.isNotEmpty)
                                      Text(
                                        cpfCnpj,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          // Fix (2026-09-16): sem selectedItemBuilder, o
                          // item de 2 linhas (nome + cpf/cnpj) tambem era
                          // usado dentro do proprio campo fechado, que so
                          // reserva altura pra 1 linha -- "BOTTOM OVERFLOWED
                          // BY 25 PIXELS". O campo fechado mostra so o nome
                          // (1 linha); a lista aberta continua com nome +
                          // cpf/cnpj embaixo.
                          selectedItemBuilder: (context) => options.map((e) {
                            final nome = e['nome']?.toString() ??
                                e['razaoSocial']?.toString() ??
                                '';
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                nome,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => selectedParceiroId = val);
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedParceiroId == null) return;

                // Fix (2026-09-16): URL antiga era relativa e usava
                // "/api/parceiros" (plural, endpoint inexistente --
                // ParceiroController mapeia "/api/parceiro", singular).
                // Sem host nem porta, o navegador resolvia a chamada contra
                // a origem da propria pagina (o dev-server do Flutter Web),
                // que devolvia 200 com o index.html no lugar do JSON do
                // parceiro -- por isso a requisicao "nao dava em nada":
                // getResp.isSuccess vinha false (jsonDecode falhava dentro
                // de NetworkCaller.getRequest), o bloco de PUT nunca era
                // executado, o popup nao fechava e a grid nao atualizava.
                try {
                  final getResp = await NetworkCaller()
                      .getRequest('${ApiLinks.allParceiros}/$selectedParceiroId');
                  if (getResp.isSuccess && getResp.body != null) {
                    final parceiroData = getResp.body!;
                    parceiroData['matriz'] = {'id': widget.matrizId};

                    final putResp = await NetworkCaller().putRequest(
                      ApiLinks.updateParceiro(selectedParceiroId!),
                      parceiroData,
                    );

                    if (putResp.statusCode == 200 || putResp.statusCode == 201) {
                      if (mounted) Navigator.of(ctx).pop();
                      setState(() { _gridKey = UniqueKey(); });
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao vincular filial.')));
                      }
                    }
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Erro ao buscar parceiro selecionado (status ${getResp.statusCode}).')));
                  }
                } catch (e) {
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao vincular filial: $e')));
                   }
                }
              },
              child: const Text('Vincular'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen(
      key: _gridKey,
      telaNome: 'parceiro',
      hasPermission: widget.hasPermission,
      extraParams: {'matrizId': widget.matrizId, if (widget.empresaId != null) 'empresaId': widget.empresaId},
      fromJson: (json) => json,
toJson: (item) => item,
      headerActions: [
        ElevatedButton.icon(
          onPressed: _vincularFilial,
          icon: const Icon(Icons.add_link),
          label: const Text('Vincular Filial Existente'),
        ),
      ],
      showAppBar: false,
    );
  }
}
