import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../services/network_caller.dart';
import '../models/telas_model.dart';
import '../models/login_model.dart' show LoginEnum;
import '../services/tela_caller.dart';
import '../customization/dynamic_grid_dynamic_screen.dart' as mobile_dyn;
import '../customization/dynamic_grid_windows_screen.dart' as dyn;
import 'generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType, SecurityCheck;

/// Avalia a expressão `visibleWhen` (formato "<fieldName>==<valor>") contra o
/// estado atual do formulário. Sem expressão, o campo é sempre visível.
///
/// Quando o campo referenciado não existe no estado, usa o valor padrão do
/// tipo esperado: bool ausente == false; demais tipos ausentes == null.
String _toCamelCaseStatic(String s) {
  if (!s.contains('_')) return s;
  final parts = s.split('_');
  return parts.first +
      parts
          .skip(1)
          .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
          .join();
}

String _toSnakeCaseStatic(String s) {
  return s
      .replaceAllMapped(
          RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
      .replaceFirst(RegExp(r'^_'), '');
}

bool avaliarVisibleWhen(
    String? expressao, Map<String, dynamic> estadoFormulario) {
  if (expressao == null || expressao.trim().isEmpty) return true;

  final partes = expressao.split('==');
  if (partes.length != 2) return true;

  final fieldName = partes[0].trim();
  final valorEsperadoTexto = partes[1].trim();

  dynamic valorEsperado;
  if (valorEsperadoTexto == 'true') {
    valorEsperado = true;
  } else if (valorEsperadoTexto == 'false') {
    valorEsperado = false;
  } else {
    valorEsperado = valorEsperadoTexto;
  }

  dynamic valorAtual = estadoFormulario[fieldName];
  if (valorAtual == null) {
    final camel = _toCamelCaseStatic(fieldName);
    final snake = _toSnakeCaseStatic(fieldName);
    valorAtual = estadoFormulario[camel] ?? estadoFormulario[snake];
  }
  if (valorAtual == null && !estadoFormulario.containsKey(fieldName)) {
    valorAtual = valorEsperado is bool ? false : null;
  }

  if (valorAtual is String && valorEsperado is String) {
    return valorAtual.trim().toUpperCase() == valorEsperado.trim().toUpperCase();
  }

  return valorAtual == valorEsperado;
}

// ---------------------------------------------------------------
// GenericDetailFormScreen
// ---------------------------------------------------------------
/// Explicit grid tab — shown as a full DynamicGridWindowsScreen tab.
/// [extraParamKey] is the query param name sent to the backend (e.g. 'loginId').
/// [extraParamValue] is the value (usually the parent id).
class RelatedGridTab {
  final String title;
  final IconData icon;
  final String? telaNome;
  final Map<String, dynamic>? extraParams;
  final List<FieldConfigWindows>? fieldOverrides;

  /// Sobrescreve o endpoint de exclusão do grid. Use `:id` como placeholder do
  /// id da linha. Útil quando "excluir" nesta aba deve DESVINCULAR em vez de
  /// apagar a entidade (ex.: aba Roles do login → DELETE /api/logins/{loginId}/roles/:id).
  final String? deleteEndpointOverride;

  /// Dados fixos injetados no payload ao salvar (ex.: aplicativo fixo).
  final Map<String, dynamic>? additionalFormData;

  /// Transforma o formData final antes do submit (ex.: ajustar formato de
  /// data para o tipo esperado pelo backend). Ver card #431.
  final Map<String, dynamic> Function(Map<String, dynamic> formData)?
      transformFormData;

  /// Widget customizado — quando informado, ignora telaNome e exibe este widget na aba
  final Widget? customWidget;

  /// Ver GenericGridScreen.prefetchExtraFields/onAfterSave — repassados como
  /// estão até o grid (Map<String,dynamic> porque RelatedGridTab sempre usa o
  /// grid dinâmico genérico, nunca um T tipado).
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> item)?
      prefetchExtraFields;
  final Future<void> Function(
      Map<String, dynamic> formData, Map<String, dynamic>? item)? onAfterSave;

  const RelatedGridTab({
    required this.title,
    required this.icon,
    this.telaNome,
    this.extraParams,
    this.fieldOverrides,
    this.additionalFormData,
    this.transformFormData,
    this.deleteEndpointOverride,
    this.customWidget,
    this.prefetchExtraFields,
    this.onAfterSave,
  }) : assert(telaNome != null || customWidget != null,
            'RelatedGridTab requer telaNome ou customWidget');
}

class GenericDetailFormScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String telaNome;
  final SecurityCheck hasPermission;
  final List<FieldConfigWindows>? fieldOverrides;
  final String? titleOverride;

  /// Explicit related grid tabs (e.g. roles, chamados).
  final List<RelatedGridTab>? relatedTabs;

  /// Callback após salvar o formulário principal.
  final Future<void> Function(
      Map<String, dynamic> formData, Map<String, dynamic>? item)? onAfterSave;

  /// Opcional: permite injetar um handler customizado de busca de CEP (para testes unitários).
  final Future<Map<String, dynamic>?> Function(String cep)? onBuscarCep;

  /// Opcional: permite fornecer TelaConfig pronto (evita depender de cache/rede em testes).
  final TelaConfig? telaConfig;

  const GenericDetailFormScreen({
    super.key,
    required this.item,
    required this.telaNome,
    required this.hasPermission,
    this.fieldOverrides,
    this.titleOverride,
    this.relatedTabs,
    this.onAfterSave,
    this.onBuscarCep,
    this.telaConfig,
  });

  @override
  State<GenericDetailFormScreen> createState() =>
      _GenericDetailFormScreenState();
}

class _GenericDetailFormScreenState extends State<GenericDetailFormScreen>
    with SingleTickerProviderStateMixin {
  late Future<TelaConfig> _telaFuture;
  TabController? _tabController;

  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _dropdownValues = <String, dynamic>{};
  final _multiValues = <String, List<dynamic>>{};
  final _multiValueLabels = <String, Map<String, String>>{};
  final _checkboxValues = <String, bool>{};
  final _dropdownCache = <String, List<Map<String, dynamic>>>{};
  // Memoiza o Future em andamento por campo: evita recriar a requisição HTTP
  // (e reiniciar o FutureBuilder em ConnectionState.waiting) a cada rebuild
  // do formulário enquanto o fetch ainda não terminou.
  final _dropdownFutures = <String, Future<List<Map<String, dynamic>>>>{};

  bool _saving = false;
  bool _buscandoCep = false;
  bool _initialized = false;

  Map<String, FieldConfigWindows> _overrideMap = {};
  Set<String> _suppressedFkFields = {};

  @override
  void initState() {
    super.initState();
    _buildOverrideMaps();
    _telaFuture = _loadTela();
  }

  void _buildOverrideMaps() {
    _overrideMap = {
      for (final o in (widget.fieldOverrides ?? [])) o.fieldName: o,
    };
    final dropdownNames = (widget.fieldOverrides ?? [])
        .where((o) => o.fieldType == FieldType.dropdown)
        .map((o) => o.fieldName.toLowerCase())
        .toSet();
    final suppressed = <String>{};
    for (final name in dropdownNames) {
      suppressed.add('${name}_id');
      suppressed.add('id_$name');
    }
    _suppressedFkFields = suppressed;
  }

  Future<TelaConfig> _loadTela() async {
    if (widget.telaConfig != null) {
      return widget.telaConfig!;
    }
    final svc = await _TelaServiceHelper.load(widget.telaNome);
    return svc;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _tabController?.dispose();
    super.dispose();
  }

  String _toCamelCase(String s) {
    if (!s.contains('_')) return s;
    final parts = s.split('_');
    return parts.first +
        parts
            .skip(1)
            .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
            .join();
  }

  String _toSnakeCase(String s) {
    return s
        .replaceAllMapped(
            RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  dynamic _resolveItemValue(Map<String, dynamic> item, String fn) {
    if (item.containsKey(fn) && item[fn] != null) return item[fn];

    final camel = _toCamelCase(fn);
    if (item.containsKey(camel) && item[camel] != null) return item[camel];

    final snake = _toSnakeCase(fn);
    if (item.containsKey(snake) && item[snake] != null) return item[snake];

    // Aliases explícitos
    if (fn == 'razaoSocial' || fn == 'razao_social') {
      return item['razaoSocial'] ?? item['razao_social'];
    }
    if (fn == 'valorMensal' || fn == 'valor_mensal') {
      return item['valorMensal'] ?? item['valor_mensal'];
    }
    if (fn == 'diaVencimentoMensalidade' || fn == 'dia_vencimento_mensalidade') {
      return item['diaVencimentoMensalidade'] ??
          item['dia_vencimento_mensalidade'];
    }
    if (fn == 'tiposParceiro' ||
        fn == 'tipos_parceiro' ||
        fn == 'tipo_parceiros' ||
        fn == 'tipoParceiro') {
      return item['tiposParceiro'] ??
          item['tipos_parceiro'] ??
          item['tipo_parceiros'] ??
          item['tipoParceiro'];
    }
    if (fn == 'regime' ||
        fn == 'regime_tributario' ||
        fn == 'regimeTributario') {
      return item['regime'] ??
          item['regime_tributario'] ??
          item['regimeTributario'];
    }
    if (fn == 'empresa' || fn == 'empresa_id' || fn == 'empId') {
      return item['empresa'] ?? item['empresa_id'] ?? item['empId'];
    }
    if (fn == 'ambiente') {
      return item['ambiente'];
    }
    if (fn == 'modulo_servicos' ||
        fn == 'moduloServicos' ||
        fn == 'modulosServico') {
      return item['moduloServicos'] ??
          item['modulo_servicos'] ??
          item['modulosServico'];
    }
    if (fn == 'tipoCliente' || fn == 'tipo_cliente') {
      return item['tipoCliente'] ?? item['tipo_cliente'];
    }
    if (fn == 'cpf_cnpj' || fn == 'cpfCnpj') {
      return item['cpf_cnpj'] ?? item['cpfCnpj'];
    }
    if (fn == 'tipo_login' || fn == 'tipoLogin') {
      return item['tipo_login'] ?? item['tipoLogin'];
    }
    if (fn == 'ativo' || fn == 'is_ativo' || fn == 'isAtivo') {
      return item['ativo'] ?? item['is_ativo'] ?? item['isAtivo'];
    }
    if (fn == 'parceiro' ||
        fn == 'parceiro_id' ||
        fn == 'parc_id' ||
        fn == 'parceiroId') {
      return item['parceiro'] ??
          item['parceiro_id'] ??
          item['parc_id'] ??
          item['parceiroId'];
    }
    if (fn == 'aplicativo' ||
        fn == 'aplicativo_id' ||
        fn == 'app_id' ||
        fn == 'aplicativoId') {
      return item['aplicativo'] ??
          item['aplicativo_id'] ??
          item['app_id'] ??
          item['aplicativoId'];
    }
    if (fn == 'tipoEstabelecimento' || fn == 'tipo_estabelecimento') {
      return item['tipoEstabelecimento'] ?? item['tipo_estabelecimento'] ?? 'MATRIZ';
    }
    if (fn == 'matriz' || fn == 'matriz_id' || fn == 'matrizId') {
      return item['matriz'] ?? item['matriz_id'] ?? item['matrizId'];
    }
    if (fn == 'foto' || fn == 'photo' || fn == 'avatar') {
      return item['foto'] ?? item['photo'] ?? item['avatar'];
    }

    // Endereço aninhado
    if (item['endereco'] is Map) {
      final end = item['endereco'] as Map;
      if (end.containsKey(fn) && end[fn] != null) return end[fn];
      if (end.containsKey(camel) && end[camel] != null) return end[camel];
      if (end.containsKey(snake) && end[snake] != null) return end[snake];
    }

    return null;
  }

  void _initControllers(TelaConfig tela) {
    final item = widget.item;
    for (final f in tela.fields) {
      final fn = f.fieldName;
      final fnL = fn.toLowerCase();
      if (fnL == 'dhcreatedat' ||
          fnL == 'dhupdatedat' ||
          fnL == 'dh_created_at' ||
          fnL == 'dh_updated_at') {
        continue;
      }
      final val = _resolveItemValue(item, fn);
      if (f.fieldType == TelaFieldType.boolean) {
        if (fnL == 'ativo' || fnL == 'is_ativo' || fnL == 'isativo') {
          _checkboxValues.putIfAbsent(fn, () => val == null ? true : (val == true || val == 1 || val == 'true' || val == '1'));
        } else {
          _checkboxValues.putIfAbsent(fn, () => val == true || val == 1 || val == 'true' || val == '1');
        }
      } else if (f.fieldType == TelaFieldType.dropdown) {
        if (!_dropdownValues.containsKey(fn)) {
          if (val is Map) {
            _dropdownValues[fn] = val['id']?.toString() ??
                val['value']?.toString() ??
                val['codigo']?.toString() ??
                val['name']?.toString();
          } else if (val != null) {
            _dropdownValues[fn] = val.toString();
          }
        }
      } else if (f.fieldType == TelaFieldType.multiselect) {
        _initMultiValue(
            fn,
            val,
            f.dropdownValueField.isNotEmpty ? f.dropdownValueField : 'id',
            f.dropdownDisplayField.isNotEmpty ? f.dropdownDisplayField : 'nome');
      } else {
        _controllers.putIfAbsent(
            fn, () => TextEditingController(text: _getValue(val)));
      }
    }
    // Init overrides
    for (final o in (widget.fieldOverrides ?? [])) {
      final fn = o.fieldName;
      final fnL = fn.toLowerCase();
      final val = _resolveItemValue(item, fn);
      if (o.fieldType == FieldType.boolean) {
        if (fnL == 'ativo' || fnL == 'is_ativo' || fnL == 'isativo') {
          _checkboxValues.putIfAbsent(fn, () => val == null ? true : (val == true || val == 1 || val == 'true' || val == '1'));
        } else {
          _checkboxValues.putIfAbsent(fn, () => val == true || val == 1 || val == 'true' || val == '1');
        }
      } else if (o.fieldType == FieldType.dropdown) {
        if (!_dropdownValues.containsKey(fn) || _dropdownValues[fn] == null) {
          if (val is Map) {
            _dropdownValues[fn] = val['id']?.toString() ??
                val['value']?.toString() ??
                val['codigo']?.toString() ??
                val['name']?.toString();
          } else if (val != null) {
            _dropdownValues[fn] = val.toString();
          }
        }
      } else if (o.fieldType == FieldType.multiselect) {
        _initMultiValue(fn, val, o.dropdownValueField, o.dropdownDisplayField);
      } else {
        if (!_controllers.containsKey(fn) || _controllers[fn]!.text.isEmpty) {
          _controllers[fn] = TextEditingController(text: _getValue(val));
        }
      }
    }
  }

  String _getValue(dynamic val) {
    if (val == null) return '';
    if (val is Map)
      return val['nome']?.toString() ??
          val['name']?.toString() ??
          val['id']?.toString() ??
          '';
    return val.toString();
  }

  void _initMultiValue(String fn, dynamic val, String dropdownValueField,
      [String dropdownDisplayField = '']) {
    if (_multiValues.containsKey(fn)) return;
    final vf = dropdownValueField.isNotEmpty ? dropdownValueField : 'id';
    final df = dropdownDisplayField.isNotEmpty ? dropdownDisplayField : 'nome';
    if (val is List) {
      final labels = <String, String>{};
      _multiValues[fn] = val
          .map((e) {
            if (e is Map) {
              final id = (e[vf] ?? e['id'])?.toString();
              if (id != null) {
                final label = e[df]?.toString() ??
                    e['nome']?.toString() ??
                    e['description']?.toString();
                if (label != null && label.isNotEmpty) labels[id] = label;
              }
              return id;
            }
            return e?.toString();
          })
          .whereType<String>()
          .toList();
      if (labels.isNotEmpty) _multiValueLabels[fn] = labels;
    } else {
      _multiValues[fn] = [];
    }
  }

  FieldType _telaType(TelaFieldType tft, String fieldName) {
    final fn = fieldName.toLowerCase();
    if (fn == 'foto' || fn == 'photo' || fn == 'avatar' || fn == 'imagem') {
      return FieldType.file;
    }
    if (fn == 'senha' || fn == 'password') return FieldType.password;
    if (fn == 'email') return FieldType.email;
    if (fn == 'cpf') return FieldType.cpf;
    if (fn == 'cnpj') return FieldType.cnpj;
    if (fn == 'cpfcnpj' || fn == 'cpf_cnpj') return FieldType.text;
    if (fn == 'telefone' || fn == 'celular') return FieldType.phone;
    if (fn == 'cep' || tft == TelaFieldType.cep) return FieldType.cep;
    if (tft.index < FieldType.values.length) return FieldType.values[tft.index];
    return FieldType.text;
  }

  Future<void> _save(TelaConfig tela) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{};
      final id = widget.item['id'];
      if (id != null) body['id'] = id;

      for (final entry in _controllers.entries) {
        final key = entry.key;
        final text = entry.value.text.trim();
        if (key == 'valorMensal' || key == 'valor_mensal' || key == 'valor') {
          final clean = text
              .replaceAll('R\$', '')
              .replaceAll(' ', '')
              .replaceAll('.', '')
              .replaceAll(',', '.');
          final numVal = double.tryParse(clean);
          body[key] = numVal ?? text;
        } else if (key == 'diaVencimentoMensalidade' ||
            key == 'dia_vencimento_mensalidade') {
          body[key] = int.tryParse(text) ?? text;
        } else {
          body[key] = text;
        }
      }
      for (final entry in _checkboxValues.entries) {
        body[entry.key] = entry.value;
      }
      for (final entry in _dropdownValues.entries) {
        if (entry.value == null) continue;
        final key = entry.key;
        final val = entry.value;
        final valStr = val.toString();
        final isScalar = key == 'ambiente' ||
            key == 'origem' ||
            key == 'status' ||
            key == 'tipo' ||
            key == 'tipoConta' ||
            key == 'tipo_conta' ||
            key == 'tipoCliente' ||
            key == 'tipo_cliente' ||
            key == 'tipoLogin' ||
            key == 'tipo_login' ||
            key == 'tipoEstabelecimento' ||
            key == 'tipo_estabelecimento' ||
            key == 'diaVencimentoMensalidade' ||
            key == 'dia_vencimento_mensalidade';
        if (isScalar) {
          body[key] = int.tryParse(valStr) ?? val;
        } else {
          final intVal = int.tryParse(valStr);
          body[key] = {'id': intVal ?? val};
        }
      }
      for (final entry in _multiValues.entries) {
        body[entry.key] = entry.value.map((v) {
          final intVal = int.tryParse(v.toString());
          return {'id': intVal ?? v};
        }).toList();
      }

      // Sincroniza aliases comuns no payload para compatibilidade backend
      if (body.containsKey('razaoSocial') && !body.containsKey('razao_social')) {
        body['razao_social'] = body['razaoSocial'];
      }
      if (body.containsKey('valorMensal') && !body.containsKey('valor_mensal')) {
        body['valor_mensal'] = body['valorMensal'];
      }
      if (body.containsKey('tiposParceiro') &&
          !body.containsKey('tipos_parceiro')) {
        body['tipos_parceiro'] = body['tiposParceiro'];
      }
      if (body.containsKey('regime') && !body.containsKey('regime_tributario')) {
        body['regime_tributario'] = body['regime'];
      }
      if (body.containsKey('cpf_cnpj') && !body.containsKey('cpfCnpj')) {
        body['cpfCnpj'] = body['cpf_cnpj'];
      }
      if (body.containsKey('cpfCnpj') && !body.containsKey('cpf_cnpj')) {
        body['cpf_cnpj'] = body['cpfCnpj'];
      }
      if (body.containsKey('tipo_login') && !body.containsKey('tipoLogin')) {
        body['tipoLogin'] = body['tipo_login'];
      }
      if (body.containsKey('tipoLogin') && !body.containsKey('tipo_login')) {
        body['tipo_login'] = body['tipoLogin'];
      }
      if (body.containsKey('tipo_estabelecimento') &&
          !body.containsKey('tipoEstabelecimento')) {
        body['tipoEstabelecimento'] = body['tipo_estabelecimento'];
      }
      if (body.containsKey('tipoEstabelecimento') &&
          !body.containsKey('tipo_estabelecimento')) {
        body['tipo_estabelecimento'] = body['tipoEstabelecimento'];
      }
      final tipoEst = (body['tipoEstabelecimento'] ??
              body['tipo_estabelecimento'])
          ?.toString()
          .toUpperCase();
      if (tipoEst == 'MATRIZ') {
        body['matriz'] = null;
        body['matriz_id'] = null;
        body['matrizId'] = null;
      }

      final isCreate = id == null;
      final endpoint = isCreate
          ? tela.createEndpoint
          : tela.updateEndpoint.replaceAll(':id', id?.toString() ?? '');
      final url =
          endpoint.startsWith('http') ? endpoint : ApiLinks.baseUrl + endpoint;
      final resp = isCreate
          ? await NetworkCaller().postRequest(url, body)
          : await NetworkCaller().putRequest(url, body);
      if (!mounted) return;
      if (resp.isSuccess) {
        final msg = isCreate ? 'Criado com sucesso' : 'Salvo com sucesso';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg, style: const TextStyle(color: Colors.white)),
              backgroundColor: GridColors.success),
        );
        if (widget.onAfterSave != null) {
          await widget.onAfterSave!(body, widget.item);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar: ${resp.statusCode}',
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: GridColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erro: $e', style: const TextStyle(color: Colors.white)),
              backgroundColor: GridColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<_AutoTab> _detectAutoTabs(TelaConfig tela) {
    final tabs = <_AutoTab>[];
    // Apenas relatedGrids do backend — sem auto-detect de listas do JSON
    // (evita duplicação com explicitTabs)
    for (final rg in tela.relatedGrids) {
      if (rg.gridTelaNome.isNotEmpty) {
        tabs.add(_AutoTab(
          title: rg.title,
          icon: _iconFromName(rg.icon),
          gridTelaNome: rg.gridTelaNome,
        ));
      }
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TelaConfig>(
      future: _telaFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError || !snap.hasData) {
          return Scaffold(body: Center(child: Text('Erro: ${snap.error}')));
        }
        final tela = snap.data!;
        if (!_initialized) {
          _initControllers(tela);
          _initialized = true;
        }

        // Explicit relatedTabs from widget (highest priority)
        final explicitTabs = (widget.relatedTabs ?? []).map((rt) {
          return _AutoTab(
            title: rt.title,
            icon: rt.icon,
            gridTelaNome: rt.telaNome,
            extraParams: rt.extraParams,
            fieldOverrides: rt.fieldOverrides,
            additionalFormData: rt.additionalFormData,
            transformFormData: rt.transformFormData,
            deleteEndpointOverride: rt.deleteEndpointOverride,
            customWidget: rt.customWidget,
            prefetchExtraFields: rt.prefetchExtraFields,
            onAfterSave: rt.onAfterSave,
          );
        }).toList();

        // Se há explicitTabs, usa APENAS eles — sem auto-detect do backend para evitar duplicação
        final autoTabs =
            explicitTabs.isNotEmpty ? <_AutoTab>[] : _detectAutoTabs(tela);

        final allTabs = [...explicitTabs, ...autoTabs];
        final tabCount = 1 + allTabs.length;

        if (_tabController == null || _tabController!.length != tabCount) {
          _tabController?.dispose();
          _tabController = TabController(length: tabCount, vsync: this);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FB),
          appBar: AppBar(
            title: Text(widget.titleOverride ?? tela.titulo),
            backgroundColor: GridColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              if (tabCount > 1) _buildTopTabs(allTabs),
              Expanded(
                child: tabCount > 1
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFormTab(tela),
                          for (var i = 0; i < allTabs.length; i++)
                            _LazyTab(
                              controller: _tabController!,
                              tabIndex: i + 1,
                              builder: () => _buildAutoTab(allTabs[i]),
                            ),
                        ],
                      )
                    : _buildFormTab(tela),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopTabs(List<_AutoTab> tabs) {
    return Container(
      width: double.infinity,
      color: GridColors.card,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: GridColors.primaryLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: GridColors.divider),
          ),
          labelColor: GridColors.primary,
          unselectedLabelColor: GridColors.textSecondary,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          labelPadding: const EdgeInsets.symmetric(horizontal: 10),
          tabs: [
            const Tab(
              height: 56,
              icon: Icon(Icons.edit_note, size: 16),
              text: 'Cadastro',
            ),
            ...tabs.map(
              (t) => Tab(
                height: 56,
                icon: Icon(t.icon, size: 16),
                text: t.title,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Monta o estado atual do formulário (checkbox, dropdown, multiselect,
  /// texto) para avaliação de `visibleWhen`.
  Map<String, dynamic> _estadoFormularioAtual() {
    final estado = <String, dynamic>{};
    estado.addAll(_checkboxValues);
    estado.addAll(_dropdownValues);
    estado.addAll(_multiValues);
    for (final entry in _controllers.entries) {
      estado[entry.key] = entry.value.text;
    }
    if (estado.containsKey('tipo_estabelecimento') &&
        !estado.containsKey('tipoEstabelecimento')) {
      estado['tipoEstabelecimento'] = estado['tipo_estabelecimento'];
    }
    if (estado.containsKey('tipoEstabelecimento') &&
        !estado.containsKey('tipo_estabelecimento')) {
      estado['tipo_estabelecimento'] = estado['tipoEstabelecimento'];
    }
    return estado;
  }

  Widget _buildFormTab(TelaConfig tela) {
    final effectiveFields = <_EF>[];
    final inserted = <String>{};

    // Pré-computa todos os nomes de dropdown (overrides + backend) para suprimir IDs brutos
    final allDropdownNames = <String>{
      for (final o in (widget.fieldOverrides ?? []))
        if (o.fieldType == FieldType.dropdown ||
            o.fieldType == FieldType.multiselect)
          o.fieldName.toLowerCase(),
      for (final f in tela.fields)
        if (f.dropdownEndpoint != null && f.dropdownEndpoint!.isNotEmpty)
          f.fieldName.toLowerCase(),
    };

    for (final f in tela.fields) {
      if (!f.isInForm) continue;
      final fnL = f.fieldName.toLowerCase();
      if (fnL == 'dh_created_at' ||
          fnL == 'dh_updated_at' ||
          fnL == 'dhcreatedat' ||
          fnL == 'dhupdatedat' ||
          fnL == 'password_reset_token' ||
          fnL == 'passwordresettoken' ||
          fnL == 'password_reset_expires' ||
          fnL == 'passwordresetexpires' ||
          fnL == 'must_change_password' ||
          fnL == 'mustchangepassword' ||
          fnL == 'aplicativo_empresa' ||
          fnL == 'aplicativoempresa' ||
          fnL == 'trocar_senha_proximo_login' ||
          fnL == 'trocarsenhaproximologin') {
        continue;
      }
      if (fnL == 'id') continue;

      // 1. Override explícito (por fieldName exato, camelCase ou snake_case)
      final overrideKey = _overrideMap.containsKey(f.fieldName)
          ? f.fieldName
          : _overrideMap.containsKey(_toCamelCase(f.fieldName))
              ? _toCamelCase(f.fieldName)
              : _overrideMap.containsKey(_toSnakeCase(f.fieldName))
                  ? _toSnakeCase(f.fieldName)
                  : null;
      if (overrideKey != null) {
        final ov = _overrideMap[overrideKey]!;
        if (!ov.isInForm) {
          inserted.add(f.fieldName);
          inserted.add(overrideKey);
          continue;
        }
        if (!inserted.contains(f.fieldName)) {
          effectiveFields.add(_EF.fromOverride(ov));
          inserted.add(f.fieldName);
          inserted.add(overrideKey);
        }
        continue;
      }

      // 2. Campo FK de um override (ex: empresa_id → override 'empresa')
      if (_suppressedFkFields.contains(fnL)) {
        final base = fnL.endsWith('_id')
            ? fnL.substring(0, fnL.length - 3)
            : fnL.substring(3);
        if (_overrideMap.containsKey(base)) {
          final ov = _overrideMap[base]!;
          if (!ov.isInForm) {
            inserted.add(base);
            continue;
          }
          if (!inserted.contains(base)) {
            effectiveFields.add(_EF.fromOverride(ov));
            inserted.add(base);
          }
        }
        continue;
      }

      // 3. Suprimir IDs brutos quando já existe dropdown correspondente
      if (_isRawIdField(fnL, allDropdownNames)) continue;

      // 4. Skip list fields (handled as tabs)
      final val = widget.item[f.fieldName];
      if (val is List) continue;

      // 5. Auto-dropdown: campo com dropdownEndpoint do backend
      if (f.dropdownEndpoint != null &&
          f.dropdownEndpoint!.isNotEmpty &&
          !inserted.contains(f.fieldName)) {
        final isMulti =
            f.multiSelect || f.fieldType == TelaFieldType.multiselect;
        effectiveFields.add(_EF(
          fieldName: f.fieldName,
          label: f.label,
          type: isMulti ? FieldType.multiselect : FieldType.dropdown,
          isRequired: f.isRequired,
          enabled: f.enabled,
          vField:
              f.dropdownValueField.isNotEmpty && f.dropdownValueField != 'value'
                  ? f.dropdownValueField
                  : 'id',
          dField: f.dropdownDisplayField.isNotEmpty &&
                  f.dropdownDisplayField != 'label'
              ? f.dropdownDisplayField
              : 'nome',
          dropdownEndpoint: f.dropdownEndpoint,
        ));
        inserted.add(f.fieldName);
        continue;
      }

      effectiveFields
          .add(_EF.fromTelaField(f, _telaType(f.fieldType, f.fieldName)));
      inserted.add(f.fieldName);
    }

    // Overrides não inseridos
    for (final o in (widget.fieldOverrides ?? [])) {
      if (!o.isInForm) continue;
      if (!inserted.contains(o.fieldName)) {
        effectiveFields.add(_EF.fromOverride(o));
        inserted.add(o.fieldName);
      }
    }

    // Aplica visibilidade condicional (visibleWhen) com base no estado atual
    final estadoFormulario = _estadoFormularioAtual();
    effectiveFields.removeWhere(
        (f) => !avaliarVisibleWhen(f.visibleWhen, estadoFormulario));

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            primary: false,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Container(
                  decoration: BoxDecoration(
                    color: GridColors.card,
                    border: Border.all(color: GridColors.divider),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: GridColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.edit_note,
                                color: GridColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cadastro',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: GridColors.secondary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Edite os dados principais do registro selecionado.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: GridColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: GridColors.divider),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, formConstraints) {
                            final maxWidth = formConstraints.maxWidth;
                            final columnCount = maxWidth >= 1100
                                ? 3
                                : maxWidth >= 720
                                    ? 2
                                    : 1;
                            final gap = columnCount == 1 ? 0.0 : 12.0;
                            final fieldWidth =
                                (maxWidth - ((columnCount - 1) * gap)) /
                                    columnCount;

                            return Wrap(
                              spacing: gap,
                              runSpacing: 0,
                              children: [
                                for (final field in effectiveFields)
                                  SizedBox(
                                    width: _isWideField(field)
                                        ? maxWidth
                                        : fieldWidth,
                                    child: _buildField(field),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1, color: GridColors.divider),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: constraints.maxWidth < 560
                                ? double.infinity
                                : 220,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : () => _save(tela),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _saving ? 'Salvando...' : 'Salvar alterações',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GridColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isWideField(_EF field) {
    final name = field.fieldName.toLowerCase();
    return field.type == FieldType.multiline ||
        name.contains('observacao') ||
        name.contains('descricao') ||
        name.contains('complemento');
  }

  Widget _buildAutoTab(_AutoTab tab) {
    // Widget customizado (ex: CertificadoEmpresaScreen)
    if (tab.customWidget != null) {
      return tab.customWidget!;
    }
    if (tab.gridTelaNome != null) {
      final isMobileWidth = MediaQuery.of(context).size.width < 720;
      // Quando há deleteEndpointOverride (ex.: desvincular role do login) usa
      // sempre o grid desktop, pois só ele aplica o override — evita que o grid
      // mobile faça o delete destrutivo padrão (apagar a entidade global).
      if (isMobileWidth &&
          tab.fieldOverrides == null &&
          tab.deleteEndpointOverride == null &&
          tab.prefetchExtraFields == null &&
          tab.onAfterSave == null) {
        return mobile_dyn.DynamicGridDynamicScreen(
          telaNome: tab.gridTelaNome!,
          hasPermission: widget.hasPermission,
          extraParams: tab.extraParams,
          showAppBar: false,
        );
      }
      return dyn.DynamicGridWindowsScreen<Map<String, dynamic>>(
        telaNome: tab.gridTelaNome!,
        hasPermission: widget.hasPermission,
        fromJson: (json) => json,
        toJson: (obj) => obj,
        extraParams: tab.extraParams,
        fieldOverrides: tab.fieldOverrides,
        additionalFormData: tab.additionalFormData,
        transformFormData: tab.transformFormData,
        deleteEndpointOverride: tab.deleteEndpointOverride,
        showAppBar: false,
        prefetchExtraFields: tab.prefetchExtraFields,
        onAfterSave: tab.onAfterSave,
      );
    }
    final rows = tab.listData ?? [];
    if (rows.isEmpty) {
      return const Center(
          child: Text('Nenhum item', style: TextStyle(color: Colors.grey)));
    }
    final cols = rows.first.keys.where((k) {
      final v = rows.first[k];
      return v is! Map && v is! List;
    }).toList();
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        primary: false,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(GridColors.primary),
          headingTextStyle:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          columns: cols
              .map((c) => DataColumn(label: Text(_toTitleCase(c))))
              .toList(),
          rows: rows
              .map((row) => DataRow(
                    cells: cols
                        .map((c) => DataCell(
                              Text(row[c]?.toString() ?? '',
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildField(_EF ef) {
    switch (ef.type) {
      case FieldType.boolean:
        return _buildCheckbox(ef);
      case FieldType.dropdown:
        return _buildDropdown(ef);
      case FieldType.multiselect:
        return _buildMultiSelect(ef);
      case FieldType.date:
        return _buildDate(ef);
      case FieldType.password:
        return _buildPassword(ef);
      case FieldType.file:
        return _buildPhotoField(ef);
      case FieldType.email:
        return _buildText(ef,
            keyboardType: TextInputType.emailAddress,
            prefix: const Icon(Icons.email_outlined));
      case FieldType.phone:
        return _buildText(ef,
            keyboardType: TextInputType.phone,
            prefix: const Icon(Icons.phone_outlined));
      case FieldType.cpf:
      case FieldType.cnpj:
        return _buildText(ef,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly]);
      case FieldType.number:
        return _buildText(ef,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly]);
      case FieldType.currency:
        return _buildText(ef,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Icon(Icons.attach_money));
      case FieldType.multiline:
        return _buildText(ef,
            maxLines: 4, keyboardType: TextInputType.multiline);
      case FieldType.cep:
        return _buildCepField(ef);
      default:
        if (ef.fieldName.toLowerCase() == 'cep') {
          return _buildCepField(ef);
        }
        return _buildText(ef);
    }
  }

  InputDecoration _dec(String label,
          {Widget? prefix,
          Widget? suffix,
          bool req = false,
          bool enabled = true}) =>
      InputDecoration(
        labelText: label + (req ? ' *' : ''),
        filled: true,
        fillColor: enabled ? const Color(0xFFFBFCFE) : const Color(0xFFF1F3F5),
        labelStyle: TextStyle(
          color: enabled ? GridColors.textSecondary : Colors.grey.shade600,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: GridColors.divider)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: GridColors.primary, width: 1.5)),
        prefixIcon: prefix,
        suffixIcon: suffix,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      );

  Widget _buildText(_EF ef,
      {TextInputType? keyboardType,
      List<TextInputFormatter>? formatters,
      Widget? prefix,
      int? maxLines}) {
    _controllers.putIfAbsent(ef.fieldName, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[ef.fieldName],
        enabled: ef.enabled,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLines: maxLines ?? 1,
        decoration: _dec(ef.label, prefix: prefix, req: ef.isRequired, enabled: ef.enabled),
        validator: ef.isRequired
            ? (v) => (v == null || v.trim().isEmpty)
                ? '${ef.label} é obrigatório'
                : null
            : null,
      ),
    );
  }

  Widget _buildCepField(_EF ef) {
    _controllers.putIfAbsent(ef.fieldName, () => TextEditingController());
    final ctrl = _controllers[ef.fieldName]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: ctrl,
              enabled: ef.enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: _dec(
                ef.label,
                prefix: const Icon(Icons.location_on_outlined),
                req: ef.isRequired,
                enabled: ef.enabled,
              ).copyWith(
                hintText: '00000-000',
              ),
              validator: ef.isRequired
                  ? (v) => (v == null || v.trim().isEmpty)
                      ? '${ef.label} é obrigatório'
                      : null
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (_buscandoCep || !ef.enabled)
                  ? null
                  : () => _buscarCepEPreencher(ctrl.text),
              icon: _buscandoCep
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search, size: 18),
              label: Text(_buscandoCep ? 'Buscando...' : 'Buscar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buscarCepEPreencher(String rawCep) async {
    final cep = rawCep.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CEP deve ter 8 dígitos',
                style: TextStyle(color: Colors.white)),
            backgroundColor: GridColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _buscandoCep = true);
    try {
      Map<String, dynamic>? data;
      if (widget.onBuscarCep != null) {
        data = await widget.onBuscarCep!(cep);
      } else {
        final resp =
            await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        }
      }

      if (data == null || data['erro'] == true || data['erro'] == 'true') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CEP não encontrado',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: GridColors.warning,
            ),
          );
        }
        return;
      }

      void setCampo(List<String> aliases, String? valor) {
        if (valor == null || valor.trim().isEmpty) return;
        final v = valor.trim();
        for (final alias in aliases) {
          if (_controllers.containsKey(alias)) {
            _controllers[alias]!.text = v;
            return;
          }
          final camel = _toCamelCase(alias);
          if (_controllers.containsKey(camel)) {
            _controllers[camel]!.text = v;
            return;
          }
          final snake = _toSnakeCase(alias);
          if (_controllers.containsKey(snake)) {
            _controllers[snake]!.text = v;
            return;
          }
        }
      }

      setState(() {
        setCampo([
          'rua',
          'logradouro',
          'endereco_rua',
          'enderecoRua'
        ], data!['logradouro']?.toString());
        setCampo([
          'bairro',
          'endereco_bairro',
          'enderecoBairro'
        ], data['bairro']?.toString());
        setCampo([
          'cidade',
          'localidade',
          'municipio',
          'endereco_cidade',
          'enderecoCidade'
        ], data['localidade']?.toString());
        setCampo([
          'estado',
          'uf',
          'sigla_uf',
          'endereco_estado',
          'enderecoEstado'
        ], data['uf']?.toString());
        final compl = data['complemento']?.toString();
        if (compl != null && compl.trim().isNotEmpty) {
          setCampo([
            'complemento',
            'endereco_complemento',
            'enderecoComplemento'
          ], compl);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CEP encontrado: ${data['logradouro'] ?? ''}, ${data['localidade'] ?? ''}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: GridColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao consultar CEP: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: GridColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _buscandoCep = false);
      }
    }
  }

  Widget _buildPhotoField(_EF ef) {
    _controllers.putIfAbsent(ef.fieldName, () => TextEditingController());
    final ctrl = _controllers[ef.fieldName]!;
    final photoRaw = ctrl.text.trim();

    ImageProvider? imageProvider;
    if (photoRaw.isNotEmpty) {
      try {
        if (photoRaw.startsWith('http://') || photoRaw.startsWith('https://')) {
          imageProvider = NetworkImage(photoRaw);
        } else {
          String cleanBase64 = photoRaw;
          if (cleanBase64.contains(',')) {
            cleanBase64 = cleanBase64.split(',').last;
          }
          cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(cleanBase64);
          imageProvider = MemoryImage(bytes);
        }
      } catch (_) {
        imageProvider = null;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ef.enabled ? const Color(0xFFFBFCFE) : const Color(0xFFF1F3F5),
          border: Border.all(color: GridColors.divider),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: GridColors.primaryLight,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person, size: 34, color: GridColors.primary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ef.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: GridColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    photoRaw.isNotEmpty
                        ? 'Foto selecionada'
                        : 'Nenhuma foto selecionada',
                    style: TextStyle(
                      fontSize: 12,
                      color: photoRaw.isNotEmpty
                          ? GridColors.success
                          : GridColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (ef.enabled) ...[
              OutlinedButton.icon(
                onPressed: () => _pickPhoto(ef),
                icon: const Icon(Icons.photo_camera_outlined, size: 16),
                label: const Text('Alterar', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GridColors.primary,
                  side: const BorderSide(color: GridColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
              if (photoRaw.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remover foto',
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      ctrl.text = '';
                    });
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(_EF ef) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final b64 = base64Encode(file.bytes!);
          setState(() {
            _controllers[ef.fieldName]?.text = b64;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPassword(_EF ef) {
    _controllers.putIfAbsent(ef.fieldName, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _PasswordField(
          controller: _controllers[ef.fieldName]!,
          label: ef.label,
          isRequired: ef.isRequired),
    );
  }

  Widget _buildDate(_EF ef) {
    _controllers.putIfAbsent(ef.fieldName, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[ef.fieldName],
        readOnly: true,
        enabled: ef.enabled,
        decoration: _dec(ef.label,
            prefix: const Icon(Icons.calendar_today_outlined),
            suffix: ef.enabled ? const Icon(Icons.arrow_drop_down) : null,
            req: ef.isRequired,
            enabled: ef.enabled),
        onTap: ef.enabled
            ? () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.tryParse(_controllers[ef.fieldName]?.text ?? '') ??
                          DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  _controllers[ef.fieldName]?.text =
                      '${picked.year.toString().padLeft(4, '0')}-'
                      '${picked.month.toString().padLeft(2, '0')}-'
                      '${picked.day.toString().padLeft(2, '0')}';
                }
              }
            : null,
      ),
    );
  }

  Widget _buildCheckbox(_EF ef) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: ef.enabled ? const Color(0xFFFBFCFE) : const Color(0xFFF1F3F5),
            border: Border.all(color: GridColors.divider),
            borderRadius: BorderRadius.circular(6),
          ),
          child: CheckboxListTile(
            title: Text(ef.label),
            value: _checkboxValues[ef.fieldName] ?? false,
            activeColor: GridColors.primary,
            onChanged: ef.enabled
                ? (v) =>
                    setState(() => _checkboxValues[ef.fieldName] = v ?? false)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      );

  Widget _buildDropdown(_EF ef) {
    if (_dropdownCache.containsKey(ef.fieldName)) {
      return _dropdownWidget(ef, _dropdownCache[ef.fieldName]!);
    }
    final future = _dropdownFutures.putIfAbsent(
      ef.fieldName,
      () => ef.dropdownFutureBuilder != null
          ? ef.dropdownFutureBuilder!()
          : ef.dropdownEndpoint != null
              ? _loadEndpoint(ef.dropdownEndpoint!)
              : Future.value(ef.dropdownOptions ?? <Map<String, dynamic>>[]),
    );
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InputDecorator(
                  decoration: _dec(ef.label, enabled: ef.enabled),
                  child: const LinearProgressIndicator()));
        }
        final opts = snap.data ?? [];
        _dropdownCache[ef.fieldName] = opts;
        return _dropdownWidget(ef, opts);
      },
    );
  }

  Widget _dropdownWidget(_EF ef, List<Map<String, dynamic>> options) {
    final vf = ef.vField;
    final df = ef.dField;
    dynamic current = _dropdownValues[ef.fieldName];
    String? fallbackLabel;

    if (current != null) {
      final currentStr = current.toString().trim();
      final seen = <dynamic>{};
      final uniqueInitial = options.where((o) {
        final k = o[vf];
        return k != null && seen.add(k.toString());
      }).toList();

      if (!uniqueInitial.any((o) => o[vf]?.toString() == currentStr)) {
        if (ef.fieldName == 'ambiente') {
          if (currentStr == '1' || currentStr.toUpperCase() == 'PRODUCAO') {
            final match = uniqueInitial.firstWhere(
                (o) =>
                    o[vf]?.toString() == 'PRODUCAO' ||
                    o[vf]?.toString() == '1',
                orElse: () => {});
            if (match.isNotEmpty) current = match[vf];
          } else if (currentStr == '2' ||
              currentStr.toUpperCase() == 'HOMOLOGACAO') {
            final match = uniqueInitial.firstWhere(
                (o) =>
                    o[vf]?.toString() == 'HOMOLOGACAO' ||
                    o[vf]?.toString() == '2',
                orElse: () => {});
            if (match.isNotEmpty) current = match[vf];
          }
        } else if (ef.fieldName == 'tipo_login' ||
            ef.fieldName == 'tipoLogin') {
          final match = uniqueInitial.firstWhere((o) {
            final vStr = o[vf]?.toString().toUpperCase();
            final dStr = o[df]?.toString().toUpperCase();
            final cStr = currentStr.toUpperCase();
            return vStr == cStr || dStr == cStr;
          }, orElse: () => {});
          if (match.isNotEmpty) {
            current = match[vf];
          }
        }
      }

      final rawVal = widget.item[ef.fieldName] ??
          widget.item[_toCamelCase(ef.fieldName)] ??
          widget.item[_toSnakeCase(ef.fieldName)];
      if (rawVal is Map) {
        fallbackLabel = rawVal[df]?.toString() ??
            rawVal['nome']?.toString() ??
            rawVal['razaoSocial']?.toString() ??
            rawVal['razao_social']?.toString() ??
            rawVal['descricao']?.toString() ??
            rawVal['description']?.toString();
      } else if (ef.fieldName == 'tipo_login' ||
          ef.fieldName == 'tipoLogin') {
        final loginEnum = LoginEnum.fromBackend(current);
        fallbackLabel = '${loginEnum.name} (${loginEnum.label})';
      }
    }

    final unique = resolveDropdownOptions(
      loadedOptions: options,
      currentValue: current,
      valueField: vf,
      displayField: df,
      fallbackLabel: fallbackLabel,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<dynamic>(
        value: current?.toString(),
        decoration: _dec(ef.label, req: ef.isRequired, enabled: ef.enabled),
        isExpanded: true,
        menuMaxHeight: 300,
        items: unique
            .map((o) => DropdownMenuItem(
                  value: o[vf]?.toString(),
                  child: Text(o[df]?.toString() ?? o[vf].toString(),
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: ef.enabled
            ? (val) => setState(() {
                  _dropdownValues[ef.fieldName] = val;
                  if (ef.fieldName == 'tipo_estabelecimento') {
                    _dropdownValues['tipoEstabelecimento'] = val;
                  } else if (ef.fieldName == 'tipoEstabelecimento') {
                    _dropdownValues['tipo_estabelecimento'] = val;
                  }
                })
            : null,
        validator: ef.isRequired
            ? (v) => v == null ? '${ef.label} é obrigatório' : null
            : null,
      ),
    );
  }

  Widget _buildMultiSelect(_EF ef) {
    final cacheKey = '${ef.fieldName}_ms';
    if (_dropdownCache.containsKey(cacheKey)) {
      return _multiWidget(ef, _dropdownCache[cacheKey]!);
    }
    final future = _dropdownFutures.putIfAbsent(
      cacheKey,
      () => ef.dropdownFutureBuilder != null
          ? ef.dropdownFutureBuilder!()
          : ef.dropdownEndpoint != null
              ? _loadEndpoint(ef.dropdownEndpoint!)
              : Future.value(ef.dropdownOptions ?? <Map<String, dynamic>>[]),
    );
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InputDecorator(
                  decoration: _dec(ef.label, enabled: ef.enabled),
                  child: const LinearProgressIndicator()));
        }
        final opts = snap.data ?? [];
        _dropdownCache[cacheKey] = opts;
        return _multiWidget(ef, opts);
      },
    );
  }

  Widget _multiWidget(_EF ef, List<Map<String, dynamic>> options) {
    final vf = ef.vField;
    final df = ef.dField;
    final selected = _multiValues[ef.fieldName] ?? [];
    final savedLabels = _multiValueLabels[ef.fieldName] ?? {};

    final chips = selected.map((s) {
      final sStr = s.toString();
      final label = resolveMultiSelectChipLabel(
        selectedId: sStr,
        loadedOptions: options,
        valueField: vf,
        displayField: df,
        savedLabels: savedLabels,
      );
      return Container(
        margin: const EdgeInsets.only(right: 4, bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: GridColors.secondary,
            borderRadius: BorderRadius.circular(12)),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: ef.enabled ? () => _openMultiDialog(ef, options, vf, df) : null,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: _dec(ef.label,
              suffix: ef.enabled ? const Icon(Icons.arrow_drop_down) : null,
              req: ef.isRequired,
              enabled: ef.enabled),
          child: chips.isEmpty
              ? Text('Selecione...',
                  style: TextStyle(color: Colors.grey.shade500))
              : Wrap(spacing: 4, runSpacing: 4, children: chips),
        ),
      ),
    );
  }

  Future<void> _openMultiDialog(
      _EF ef, List<Map<String, dynamic>> options, String vf, String df) async {
    final savedLabels = _multiValueLabels[ef.fieldName] ?? {};
    final selected = _multiValues[ef.fieldName] ?? [];

    final mergedOptions = List<Map<String, dynamic>>.from(options);
    for (final s in selected) {
      final sStr = s.toString();
      if (!mergedOptions.any((o) => o[vf]?.toString() == sStr)) {
        final label = savedLabels[sStr] ?? sStr;
        mergedOptions.insert(0, {vf: sStr, df: label});
      }
    }

    final result = await showDialog<List<dynamic>>(
      context: context,
      builder: (ctx) => _MultiSelectDialog(
        title: ef.label,
        options: mergedOptions,
        valueField: vf,
        displayField: df,
        initialSelected: List.from(selected),
      ),
    );
    if (result != null) setState(() => _multiValues[ef.fieldName] = result);
  }

  Future<List<Map<String, dynamic>>> _loadEndpoint(String endpoint) async {
    final url =
        endpoint.startsWith('http') ? endpoint : ApiLinks.baseUrl + endpoint;
    final resp = await NetworkCaller().getRequest(url);
    if (!resp.isSuccess || resp.body == null) return [];
    dynamic raw = resp.body;
    List lista = [];
    if (raw is List) {
      lista = raw;
    } else if (raw is Map) {
      final d = raw['data'] ?? raw['dados'] ?? raw['items'] ?? raw['content'];
      if (d is List) {
        lista = d;
      } else if (d is Map && d['dados'] is List) {
        lista = d['dados'];
      }
    }
    return lista
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  IconData _iconFromName(String? name) {
    switch (name) {
      case 'people':
        return Icons.people;
      case 'support_agent':
        return Icons.support_agent;
      case 'account_balance':
        return Icons.account_balance;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'inventory':
        return Icons.inventory;
      case 'receipt':
        return Icons.receipt;
      case 'description':
        return Icons.description;
      case 'person':
        return Icons.person;
      case 'location_on':
        return Icons.location_on;
      case 'security':
        return Icons.security;
      case 'roles':
        return Icons.security;
      case 'chamados':
        return Icons.support_agent;
      default:
        return Icons.list;
    }
  }

  String _toTitleCase(String text) => text
      .split(RegExp(r'[_\s]+'))
      .map((w) =>
          w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  /// Suprime campos que são IDs brutos de FK quando já existe dropdown correspondente
  static bool _isRawIdField(String fnLower, Set<String> allDropdownNames) {
    const alwaysHide = {
      'file_id',
      'foto_id',
      'foto_perfil_id',
      'academia_id',
      'cod_personal',
      'cod_produtor',
      'parent_id',
      'user_id',
      'audit_id',
    };
    if (alwaysHide.contains(fnLower)) return true;

    final isIdPattern = (fnLower.endsWith('_id') && fnLower != 'id') ||
        fnLower.startsWith('id_') ||
        fnLower.startsWith('cod_');
    if (!isIdPattern) return false;

    String base;
    if (fnLower.endsWith('_id')) {
      base = fnLower.substring(0, fnLower.length - 3);
    } else if (fnLower.startsWith('id_'))
      base = fnLower.substring(3);
    else
      base = fnLower.substring(4); // cod_

    if (base.length < 2) return false;

    for (final name in allDropdownNames) {
      if (name == base || name.contains(base) || base.contains(name))
        return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------
// Helper to load TelaConfig — uses SharedPreferences cache (same as DynamicGridWindowsScreen)
// ---------------------------------------------------------------
class _TelaServiceHelper {
  static Future<TelaConfig> load(String telaNome) async {
    final tela =
        await TelaService(networkCaller: NetworkCaller()).getTelaFromCache(
      telaNome,
      empId: TenantContext.empresaId,
      clienteId: TenantContext.parceiroId,
    );
    if (tela == null) throw Exception('Tela $telaNome não encontrada no cache');
    return tela;
  }
}

// ---------------------------------------------------------------
// Lazy tab — só constrói (e dispara fetch) o conteúdo da aba quando ela é
// selecionada pela primeira vez. Evita que TODAS as abas relacionadas
// (Parceiros, Logins, Contas a Pagar, etc.) disparem requisições HTTP ao
// montar a tela de detalhe — TabBarView constrói todos os children de
// imediato, então sem essa proteção cada DynamicGridWindowsScreen chamaria
// initState/fetch simultaneamente, causando lentidão e loaders concorrentes.
// Uma vez construída, a aba permanece viva (AutomaticKeepAlive) para não
// recarregar ao trocar de aba.
// ---------------------------------------------------------------
class _LazyTab extends StatefulWidget {
  final TabController controller;
  final int tabIndex;
  final WidgetBuilder0 builder;

  const _LazyTab({
    required this.controller,
    required this.tabIndex,
    required this.builder,
  });

  @override
  State<_LazyTab> createState() => _LazyTabState();
}

typedef WidgetBuilder0 = Widget Function();

class _LazyTabState extends State<_LazyTab> with AutomaticKeepAliveClientMixin {
  bool _activated = false;

  @override
  bool get wantKeepAlive => _activated;

  @override
  void initState() {
    super.initState();
    _checkActive();
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant _LazyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTabChanged);
      widget.controller.addListener(_onTabChanged);
      _checkActive();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() => _checkActive();

  void _checkActive() {
    final isActive = widget.controller.index == widget.tabIndex;
    if (isActive && !_activated) {
      setState(() => _activated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_activated) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.builder();
  }
}

// ---------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------
class _AutoTab {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>>? listData;
  final String? gridTelaNome;
  final Map<String, dynamic>? extraParams;
  final List<FieldConfigWindows>? fieldOverrides;
  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic> formData)?
      transformFormData;
  final String? deleteEndpointOverride;
  final Widget? customWidget;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> item)?
      prefetchExtraFields;
  final Future<void> Function(
      Map<String, dynamic> formData, Map<String, dynamic>? item)? onAfterSave;
  _AutoTab(
      {required this.title,
      required this.icon,
      this.listData,
      this.gridTelaNome,
      this.extraParams,
      this.fieldOverrides,
      this.additionalFormData,
      this.transformFormData,
      this.deleteEndpointOverride,
      this.customWidget,
      this.prefetchExtraFields,
      this.onAfterSave});
}

class _EF {
  final String fieldName;
  final String label;
  final FieldType type;
  final bool isRequired;
  final bool enabled;
  final String vField;
  final String dField;
  final String? dropdownEndpoint;
  final Future<List<Map<String, dynamic>>> Function()? dropdownFutureBuilder;
  final List<Map<String, dynamic>>? dropdownOptions;
  final String? visibleWhen;

  _EF(
      {required this.fieldName,
      required this.label,
      required this.type,
      this.isRequired = false,
      this.enabled = true,
      this.vField = 'id',
      this.dField = 'nome',
      this.dropdownEndpoint,
      this.dropdownFutureBuilder,
      this.dropdownOptions,
      this.visibleWhen});

  factory _EF.fromTelaField(TelaField f, FieldType type) => _EF(
        fieldName: f.fieldName,
        label: f.label,
        type: type,
        isRequired: f.isRequired,
        enabled: f.enabled,
        vField: f.dropdownValueField.isNotEmpty ? f.dropdownValueField : 'id',
        dField:
            f.dropdownDisplayField.isNotEmpty ? f.dropdownDisplayField : 'nome',
        dropdownEndpoint: f.dropdownEndpoint,
        dropdownOptions: f.dropdownOptions
            .map((e) => <String, dynamic>{
                  'id': e.optionValue,
                  'nome': e.optionLabel ?? e.optionValue.toString()
                })
            .toList(),
        visibleWhen: f.visibleWhen,
      );

  factory _EF.fromOverride(FieldConfigWindows o) => _EF(
        fieldName: o.fieldName,
        label: o.label,
        type: o.fieldType,
        isRequired: o.isRequired,
        enabled: o.enabled,
        vField: o.dropdownValueField.isNotEmpty ? o.dropdownValueField : 'id',
        dField:
            o.dropdownDisplayField.isNotEmpty ? o.dropdownDisplayField : 'nome',
        dropdownFutureBuilder: o.dropdownFutureBuilder,
        dropdownOptions: o.dropdownOptions
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        visibleWhen: o.visibleWhen ??
            (o.visibleWhenField != null && o.visibleWhenValue != null
                ? '${o.visibleWhenField}==${o.visibleWhenValue}'
                : null),
      );
}

// ---------------------------------------------------------------
// Password field widget
// ---------------------------------------------------------------
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  const _PasswordField(
      {required this.controller,
      required this.label,
      required this.isRequired});
  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      decoration: InputDecoration(
        labelText: widget.label + (widget.isRequired ? ' *' : ''),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: GridColors.primary, width: 1.5)),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _visible = !_visible),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      validator: widget.isRequired
          ? (v) => (v == null || v.trim().isEmpty)
              ? '${widget.label} é obrigatório'
              : null
          : null,
    );
  }
}

// ---------------------------------------------------------------
// MultiSelect dialog
// ---------------------------------------------------------------
class _MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final String valueField;
  final String displayField;
  final List<dynamic> initialSelected;
  const _MultiSelectDialog(
      {required this.title,
      required this.options,
      required this.valueField,
      required this.displayField,
      required this.initialSelected});
  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late List<dynamic> _selected;
  late List<Map<String, dynamic>> _filtered;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _filtered = widget.options;
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.options
            : widget.options
                .where((o) =>
                    o[widget.displayField]
                        ?.toString()
                        .toLowerCase()
                        .contains(q) ??
                    false)
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _isSel(dynamic val) =>
      _selected.any((s) => s.toString() == val?.toString());
  void _toggle(dynamic val) {
    setState(() {
      if (_isSel(val)) {
        _selected.removeWhere((s) => s.toString() == val?.toString());
      } else {
        _selected.add(val);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 420),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: GridColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.checklist, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))),
              Text('${_selected.length} selecionado(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search, color: GridColors.primary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: GridColors.primary, width: 1.5)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
              child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final opt = _filtered[i];
              final val = opt[widget.valueField];
              final label =
                  opt[widget.displayField]?.toString() ?? val.toString();
              return CheckboxListTile(
                title: Text(label, style: const TextStyle(fontSize: 14)),
                value: _isSel(val),
                activeColor: GridColors.primary,
                checkColor: Colors.white,
                onChanged: (_) => _toggle(val),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          )),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('CONFIRMAR'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Helper puro para resolução de visibilidade de campos com suporte a overrides.
bool resolveFieldVisibility({
  required bool backendIsInForm,
  FieldConfigWindows? override,
}) {
  if (override != null) {
    return override.isInForm;
  }
  return backendIsInForm;
}

/// Helper puro para resolução de rótulo em multiselect chips.
String resolveMultiSelectChipLabel({
  required String selectedId,
  required List<Map<String, dynamic>> loadedOptions,
  required String valueField,
  required String displayField,
  required Map<String, String> savedLabels,
}) {
  final match = loadedOptions.firstWhere(
    (opt) => opt[valueField]?.toString() == selectedId,
    orElse: () => <String, dynamic>{},
  );
  if (match.isNotEmpty && match[displayField] != null) {
    return match[displayField].toString();
  }
  if (savedLabels.containsKey(selectedId)) {
    return savedLabels[selectedId]!;
  }
  return '#$selectedId';
}

/// Helper puro para resolução de opções de dropdown com preservação de item atual
/// mesmo quando fora da página inicial carregada (evita current = null / sumir).
List<Map<String, dynamic>> resolveDropdownOptions({
  required List<Map<String, dynamic>> loadedOptions,
  required dynamic currentValue,
  required String valueField,
  required String displayField,
  String? fallbackLabel,
}) {
  final seen = <dynamic>{};
  final unique = loadedOptions.where((o) {
    final k = o[valueField];
    return k != null && seen.add(k.toString());
  }).toList();

  if (currentValue != null) {
    final currentStr = currentValue.toString().trim();
    if (currentStr.isNotEmpty &&
        !unique.any((o) => o[valueField]?.toString() == currentStr)) {
      unique.insert(0, {
        valueField: currentStr,
        displayField: fallbackLabel ?? currentStr,
      });
    }
  }
  return unique;
}


