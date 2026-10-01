import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../services/network_caller.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldConfigWindows, FieldType;
import '../certificado_empresa_screen.dart';
import '../login_grid_screen.dart' show WebLoginGridScreen;
import '../comunicado_componente_screen.dart'
    show WebComunicadoGridComponentesScreen;
import 'empresa_modulos_tab.dart';

import '../../../widgets/finance/cnab_config_screen.dart';
class WebEmpresaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const WebEmpresaDetailScreen({super.key, required this.item, required this.hasPermission});

  @override
  State<WebEmpresaDetailScreen> createState() => _WebEmpresaDetailScreenState();
}

class _WebEmpresaDetailScreenState extends State<WebEmpresaDetailScreen> {
  late Map<String, dynamic> _item;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    _preCarregarModulos();
  }

  Future<void> _preCarregarModulos() async {
    final id = _item['id'];
    if (id == null) return;
    final r = await NetworkCaller().getRequest(
      '${ApiLinks.baseUrl}/api/empresa-modulo?empresaId=$id',
    );
    if (!r.isSuccess || r.body == null) return;
    final raw = r.body is List ? r.body : (r.body?['data'] ?? r.body?['content'] ?? []);
    if (raw is! List) return;
    final ids = raw.map((e) => e['id']?.toString() ?? '').where((s) => s.isNotEmpty).join(', ');
    if (mounted) setState(() => _item['modulosServico'] = ids);
  }

  static Future<List<Map<String, dynamic>>> _loadTiposParceiro() async {
    final r = await NetworkCaller().getRequest(ApiLinks.allTipoParceiro);
    if (!r.isSuccess || r.body == null) return [];
    final raw = r.body!['data']?['dados'] ?? r.body!['data'] ?? r.body!['content'] ?? r.body;
    if (raw is! List) return [];
    return raw.map<Map<String, dynamic>>((e) {
      final label = e['descricao']?.toString() ?? e['nome']?.toString() ?? e['id']?.toString() ?? '';
      return {'value': e['id']?.toString() ?? '', 'label': label};
    }).where((m) => m['value']!.isNotEmpty).toList();
  }

  static Future<List<Map<String, dynamic>>> _loadModulosServico() async {
    final r = await NetworkCaller().getRequest(ApiLinks.allModuloServico);
    if (!r.isSuccess || r.body == null) return [];
    final raw = r.body!['data']?['dados'] ?? r.body!['data'] ?? r.body!['content'] ?? r.body;
    if (raw is! List) return [];
    return raw.map<Map<String, dynamic>>((e) {
      final label = e['descricao']?.toString() ?? e['nome']?.toString() ?? e['id']?.toString() ?? '';
      return {'value': e['id']?.toString() ?? '', 'label': label};
    }).where((m) => m['value']!.isNotEmpty).toList();
  }

  static Future<Map<String, dynamic>> _prePopularModulos(Map<String, dynamic> itemMap) async {
    final parceiroId = itemMap['id'];
    if (parceiroId == null) return itemMap;
    final r = await NetworkCaller().getRequest(
      '${ApiLinks.baseUrl}/api/parceiro-modulo?parceiroId=$parceiroId',
    );
    if (!r.isSuccess || r.body == null) return itemMap;
    final body = r.body;
    final raw = body is List ? body : (body?['data'] ?? body?['content'] ?? []);
    if (raw is! List) return itemMap;
    final ids = raw.map((e) => e['id']?.toString() ?? '').where((s) => s.isNotEmpty).join(', ');
    return {...itemMap, 'modulo_servicos': ids};
  }

  /// Persiste os módulos selecionados após salvar o parceiro.
  /// Envia formato {parceiroId, modulos:[{id, valor}]} para o backend gerar
  /// ContaReceber automaticamente em módulos novos com valor > 0.
  static Future<void> _salvarModulos(Map<String, dynamic> formData, Map<String, dynamic>? item) async {
    final parceiroId = formData['id'];
    if (parceiroId == null) return;
    final raw = formData['modulo_servicos'] as String? ?? '';
    final modulos = raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .map((id) => {'id': id, 'valor': 0})
        .toList();
    await NetworkCaller().postRequest(
      '${ApiLinks.baseUrl}/api/parceiro-modulo',
      {'parceiroId': parceiroId, 'modulos': modulos},
    );
  }

  /// Persiste os módulos selecionados da EMPRESA após salvar.
  Future<void> _salvarModulosEmpresa(Map<String, dynamic> formData, Map<String, dynamic>? item) async {
    final empresaId = formData['id'];
    if (empresaId == null) return;
    final raw = formData['modulosServico'] as String? ?? '';
    final moduloIds = raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    await NetworkCaller().postRequest(
      '${ApiLinks.baseUrl}/api/empresa-modulo',
      {'empresaId': empresaId, 'moduloIds': moduloIds},
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = _item['id']?.toString() ?? '';
    final empresaId = _item['id'] as int? ?? 0;
    final empresaNome = _item['nome']?.toString() ?? _item['razaoSocial']?.toString() ?? 'Empresa';

    return GenericDetailFormScreen(
      item: _item,
      telaNome: 'empresa',
      hasPermission: widget.hasPermission,
      onAfterSave: _salvarModulosEmpresa,
      fieldOverrides: [
        // fileAttachment: dropdown FK que envia "" quando vazio → 500 no backend
        // Ocultado do formulário — upload de arquivo tem tela própria
        const FieldConfigWindows(
          label: 'File Attachments',
          fieldName: 'fileAttachment',
          isInForm: false,
          isVisibleByDefault: false,
          enabled: false,
        ),
        // Ambiente: inteiro 1=Produção / 2=Homologação — exibir label
        const FieldConfigWindows(
          label: 'Ambiente',
          fieldName: 'ambiente',
          icon: Icons.cloud_outlined,
          fieldType: FieldType.dropdown,
          dropdownOptions: [
            {'value': '1', 'label': 'Produção'},
            {'value': '2', 'label': 'Homologação'},
          ],
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
          isInForm: true,
        ),
        // Módulos de serviço contratados pela empresa (M:N via empresa_modulo)
        FieldConfigWindows(
          label: 'Modulo Servicos',
          fieldName: 'modulosServico',
          icon: Icons.settings_outlined,
          fieldType: FieldType.multiselect,
          dropdownFutureBuilder: _loadModulosServico,
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: false,
        ),
      ],
      relatedTabs: [
        RelatedGridTab(
          title: 'Parceiros',
          icon: Icons.people,
          telaNome: 'parceiro',
          extraParams: {'empresa': id},
          prefetchExtraFields: _prePopularModulos,
          onAfterSave: _salvarModulos,
          fieldOverrides: [
            // Ambiente NFS-e do parceiro: enum PRODUCAO/HOMOLOGACAO
            const FieldConfigWindows(
              label: 'Ambiente',
              fieldName: 'ambiente',
              icon: Icons.cloud_outlined,
              fieldType: FieldType.dropdown,
              dropdownOptions: [
                {'value': 'PRODUCAO', 'label': 'Produção'},
                {'value': 'HOMOLOGACAO', 'label': 'Homologação'},
              ],
              dropdownValueField: 'value',
              dropdownDisplayField: 'label',
              isInForm: true,
            ),
            // Tipos de parceiro (multiselect M:N).
            // Fix (card #466): fieldName precisa bater EXATAMENTE (normalizado)
            // com o fieldName que o backend ja retorna para a tela 'parceiro'
            // (GET /api/telas/parceiro -> 'tipo_parceiros'). Com nomes
            // diferentes (antes: 'tiposParceiro'), o campo bruto do backend e
            // este override eram tratados como dois campos distintos pela
            // logica de merge em dynamic_grid_windows_screen.dart, causando
            // duplicacao visual no formulario.
            FieldConfigWindows(
              label: 'Tipo Parceiros',
              fieldName: 'tipo_parceiros',
              icon: Icons.category_outlined,
              fieldType: FieldType.multiselect,
              dropdownFutureBuilder: _loadTiposParceiro,
              dropdownValueField: 'value',
              dropdownDisplayField: 'label',
              isInForm: true,
              isFilterable: false,
            ),
            // Módulos de serviço contratados (multiselect M:N via parceiro_modulo).
            // Fix (card #466): mesmo motivo acima -- backend retorna
            // 'modulo_servicos' para a tela 'parceiro'.
            FieldConfigWindows(
              label: 'Modulo Servicos',
              fieldName: 'modulo_servicos',
              icon: Icons.settings_outlined,
              fieldType: FieldType.multiselect,
              dropdownFutureBuilder: _loadModulosServico,
              dropdownValueField: 'value',
              dropdownDisplayField: 'label',
              isInForm: true,
              isFilterable: false,
            ),
          ],
        ),
        RelatedGridTab(
          title: 'Logins',
          icon: Icons.person,
          telaNome: 'login',
          extraParams: {'empId': id},
          deleteEndpointOverride: '${ApiLinks.baseUrl}/api/logins/:id/inativar',
          additionalFormData: WebLoginGridScreen.additionalFormData,
          fieldOverrides: WebLoginGridScreen.fieldOverrides(),
        ),
        RelatedGridTab(
          title: 'Contas a Pagar',
          icon: Icons.money_off,
          telaNome: 'conta_pagar',
          extraParams: {'empresa': id},
        ),
        RelatedGridTab(
          title: 'Contas a Receber',
          icon: Icons.attach_money,
          telaNome: 'conta_receber',
          extraParams: {'empresaId': id},
        ),
        RelatedGridTab(
          title: 'Chamados',
          icon: Icons.support_agent,
          telaNome: 'chamado',
          extraParams: {'empresaId': id},
        ),
        RelatedGridTab(
          title: 'Comunicados',
          icon: Icons.campaign,
          telaNome: 'comunicado',
          extraParams: {'empId': id},
          transformFormData: WebComunicadoGridComponentesScreen.transformFormData,
        ),
        RelatedGridTab(
          title: 'Certificado Digital',
          icon: Icons.security,
          customWidget: empresaId > 0
              ? CertificadoEmpresaScreen(
                  empresaId: empresaId,
                  empresaNome: empresaNome,
                )
              : const Center(child: Text('ID da empresa não disponível')),
        ),
        RelatedGridTab(
          title: 'Séries NF-e',
          icon: Icons.format_list_numbered,
          telaNome: 'nfe_serie',
          extraParams: {'empId': id},
        ),
        RelatedGridTab(
          title: 'Módulos',
          icon: Icons.settings,
          customWidget: EmpresaModulosTab(
            empresaId: empresaId,
            onModulosChanged: (_) {},
          ),
        ),
              RelatedGridTab(
          title: 'Configuração CNAB',
          icon: Icons.account_balance,
          customWidget: empresaId > 0
              ? CnabConfigScreen(empresaId: empresaId)
              : const Center(child: Text('ID da empresa não disponível')),
        ),
      ],
    );
  }
}
