import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';

/// Aba customizada de gerenciamento de módulos de serviço para uma empresa.
///
/// Fix (card #472): antes exibia 4 checkboxes hardcoded (Comercial,
/// Financeiro, Departamento Pessoal, NFS-e), desatualizados em relação ao
/// catálogo real (GET /api/modulo-servico já tinha 10 módulos: também GME,
/// Service, Projetos e Precificacao). Além de faltarem módulos, a lista
/// hardcoded tinha um bug mais profundo: o id de cada módulo só era
/// preenchido pelo GET /api/empresa-modulo (que retorna só os JÁ vinculados)
/// -- um módulo nunca vinculado antes ficava com id=0 e nunca podia ser
/// marcado pela primeira vez (_toggleModulo descartava id==0).
///
/// Corrigido buscando o catálogo completo via GET /api/modulo-servico (fonte
/// real de módulos disponíveis) e usando GET /api/empresa-modulo só para
/// saber quais já estão marcados. Catálogo tem 2 duplicidades de nome
/// (Comercial e NFS-e, ids diferentes, dados de seeds em datas diferentes)
/// -- mantido só o de menor id por nome para não exibir checkbox duplicado.
class EmpresaModulosTab extends StatefulWidget {
  final int empresaId;
  final ValueChanged<List<int>>? onModulosChanged;

  const EmpresaModulosTab({
    super.key,
    required this.empresaId,
    this.onModulosChanged,
  });

  @override
  State<EmpresaModulosTab> createState() => _EmpresaModulosTabState();
}

class _ModuloCatalogo {
  final int id;
  final String nome;
  final String? descricao;
  const _ModuloCatalogo({required this.id, required this.nome, this.descricao});
}

class _EmpresaModulosTabState extends State<EmpresaModulosTab> {
  bool _carregando = true;
  String? _erroCarregamento;

  List<_ModuloCatalogo> _catalogo = [];
  late Set<int> _modulosMarcados;

  @override
  void initState() {
    super.initState();
    _modulosMarcados = {};
    _carregarModulos();
  }

  Future<void> _carregarModulos() async {
    if (!mounted) return;
    setState(() {
      _carregando = true;
      _erroCarregamento = null;
    });

    try {
      final token = AuthUtility.userInfo?.token;
      final headers = {if (token != null) 'Authorization': 'Bearer $token'};

      final respCatalogo = await http.get(
        Uri.parse('${ApiLinks.allModuloServico}?tamanho=200'),
        headers: headers,
      );
      final respVinculados = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/empresa-modulo?empresaId=${widget.empresaId}'),
        headers: headers,
      );

      if (!mounted) return;

      if (respCatalogo.statusCode != 200) {
        setState(() {
          _erroCarregamento = 'Erro ${respCatalogo.statusCode} ao carregar catálogo de módulos';
          _carregando = false;
        });
        return;
      }

      final bodyCatalogo = jsonDecode(respCatalogo.body);
      final List<dynamic> dadosCatalogo =
          (bodyCatalogo['data']?['dados'] ?? bodyCatalogo['data'] ?? []) as List<dynamic>;

      // Dedup por nome, mantendo o de menor id (catálogo tem duplicidades
      // reais de seeds diferentes, ex.: "Comercial" ids 49 e 53).
      final porNome = <String, _ModuloCatalogo>{};
      for (final item in dadosCatalogo) {
        final id = item['id'] as int?;
        final nome = item['nome'] as String?;
        if (id == null || nome == null) continue;
        final existente = porNome[nome];
        if (existente == null || id < existente.id) {
          porNome[nome] = _ModuloCatalogo(
            id: id,
            nome: nome,
            descricao: item['descricao'] as String?,
          );
        }
      }
      final catalogo = porNome.values.toList()..sort((a, b) => a.id.compareTo(b.id));

      final marcados = <int>{};
      if (respVinculados.statusCode == 200) {
        final bodyVinculados = jsonDecode(respVinculados.body);
        final List<dynamic> dadosVinculados =
            bodyVinculados is List ? bodyVinculados : (bodyVinculados['data'] ?? bodyVinculados['content'] ?? []);
        for (final item in dadosVinculados) {
          final nome = item['nome'] as String?;
          if (nome == null) continue;
          final noCatalogo = porNome[nome];
          if (noCatalogo != null) marcados.add(noCatalogo.id);
        }
      }

      setState(() {
        _catalogo = catalogo;
        _modulosMarcados = marcados;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erroCarregamento = 'Erro de conexão: $e';
          _carregando = false;
        });
      }
    }
  }

  Future<void> _salvarModulos() async {
    try {
      final token = AuthUtility.userInfo?.token;
      final resp = await http.post(
        Uri.parse('${ApiLinks.baseUrl}/api/empresa-modulo'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'empresaId': widget.empresaId,
          'moduloIds': _modulosMarcados.toList(),
        }),
      );

      if (mounted && resp.statusCode == 200) {
        widget.onModulosChanged?.call(_modulosMarcados.toList());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar módulos: $e')),
        );
      }
    }
  }

  Future<void> _toggleModulo(int moduloId, bool marcado) async {
    setState(() {
      if (marcado) {
        _modulosMarcados.add(moduloId);
      } else {
        _modulosMarcados.remove(moduloId);
      }
    });

    await _salvarModulos();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erroCarregamento != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _erroCarregamento!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: GridColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarModulos,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Módulos de Serviço Contratados',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        for (final modulo in _catalogo)
          CheckboxListTile(
            title: Text(modulo.nome),
            subtitle: modulo.descricao != null ? Text(modulo.descricao!) : null,
            value: _modulosMarcados.contains(modulo.id),
            onChanged: (v) => _toggleModulo(modulo.id, v ?? false),
          ),
      ],
    );
  }
}
