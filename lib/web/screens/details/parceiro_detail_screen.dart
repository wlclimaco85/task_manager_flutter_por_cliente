import 'package:flutter/material.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show SecurityCheck, FieldConfigWindows, FieldType;
import '../../../utils/dropdown_helpers.dart';
import 'package:task_manager_flutter/web/screens/certificado_empresa_screen.dart';
import '../ged_arquivos_screen.dart';
import '../login_grid_screen.dart' show WebLoginGridScreen;
import '../comunicado_componente_screen.dart'
    show WebComunicadoGridComponentesScreen;
import 'modulo_cobranca_screen.dart';
import 'filiais_parceiro_screen.dart';

import '../../../widgets/finance/cnab_config_screen.dart';
import '../../../widgets/smtp_config_tab.dart';

class WebParceiroDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;
  final String? titleOverride;

  const WebParceiroDetailScreen(
      {super.key,
      required this.item,
      required this.hasPermission,
      this.titleOverride});

  @override
  Widget build(BuildContext context) {
    final id = item['id']?.toString() ?? '';
    final parceiroId = item['id'] as int? ?? 0;
    final parceiroNome = item['nome']?.toString() ??
        item['razao_social']?.toString() ??
        'Parceiro';
    final empresaId =
        (item['empresa'] is Map ? item['empresa']['id'] : item['empresa'])
                ?.toString() ??
            '';
    final empresaIdInt = int.tryParse(empresaId);
    final empresaNome = item['empresa'] is Map
        ? (item['empresa']['nome']?.toString() ??
            item['empresa']['razao_social']?.toString() ??
            '')
        : '';

    return GenericDetailFormScreen(
      item: item,
      telaNome: 'parceiro',
      titleOverride: titleOverride,
      hasPermission: hasPermission,
      fieldOverrides: [
        FieldConfigWindows(
          label: 'Empresa',
          fieldName: 'empresa',
          displayFieldName: 'empresa.nome',
          icon: Icons.business,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () => DropdownHelpers.empresas(),
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          isInForm: true,
          isRequired: true,
        ),
        const FieldConfigWindows(
          label: 'Razão Social',
          fieldName: 'razao_social',
          icon: Icons.apartment,
          fieldType: FieldType.text,
          isInForm: true,
        ),
        FieldConfigWindows(
          label: 'Regime Tributário',
          fieldName: 'regime_tributario',
          displayFieldName: 'regime_tributario.descricao',
          icon: Icons.business_center,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () => DropdownHelpers.regimesTributarios(),
          dropdownValueField: 'id',
          dropdownDisplayField: 'descricao',
          isInForm: true,
        ),
        const FieldConfigWindows(
          label: 'Valor Mensal',
          fieldName: 'valorMensal',
          icon: Icons.attach_money,
          fieldType: FieldType.currency,
          isInForm: true,
        ),
        const FieldConfigWindows(
          label: 'Ambiente',
          fieldName: 'ambiente',
          icon: Icons.cloud_outlined,
          fieldType: FieldType.dropdown,
          dropdownOptions: [
            {'value': 'PRODUCAO', 'label': '1 - Produção'},
            {'value': 'HOMOLOGACAO', 'label': '2 - Homologação'},
          ],
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
          isInForm: true,
        ),
        FieldConfigWindows(
          label: 'Tipo Parceiros',
          fieldName: 'tipo_parceiros',
          icon: Icons.people_outline,
          fieldType: FieldType.multiselect,
          dropdownFutureBuilder: () => DropdownHelpers.tiposParceiro(),
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          isInForm: true,
        ),
        const FieldConfigWindows(
          label: 'Tipo Estabelecimento',
          fieldName: 'tipo_estabelecimento',
          icon: Icons.store,
          fieldType: FieldType.dropdown,
          dropdownOptions: [
            {'value': 'MATRIZ', 'label': 'Matriz'},
            {'value': 'FILIAL', 'label': 'Filial'},
          ],
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
          isInForm: true,
        ),
        FieldConfigWindows(
          label: 'Matriz',
          fieldName: 'matriz',
          displayFieldName: 'matriz.nome',
          icon: Icons.account_balance,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () => DropdownHelpers.parceirosMatriz(
            empresaId: empresaIdInt,
          ),
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          visibleWhen: 'tipo_estabelecimento==FILIAL',
          visibleWhenField: 'tipo_estabelecimento',
          visibleWhenValue: 'FILIAL',
          isInForm: true,
        ),
        const FieldConfigWindows(
          label: 'Parceiro',
          fieldName: 'parceiro',
          isInForm: false,
          isInGrid: false,
          isVisibleByDefault: false,
        ),
        const FieldConfigWindows(
          label: 'Módulo Serviços',
          fieldName: 'modulo_servicos',
          icon: Icons.miscellaneous_services,
          fieldType: FieldType.text,
          isInForm: true,
          enabled: false,
        ),
        const FieldConfigWindows(
          label: 'Modulo Servicos 2',
          fieldName: 'modulosServico',
          isInForm: false,
          isInGrid: false,
          isVisibleByDefault: false,
        ),
      ],
      relatedTabs: [
        RelatedGridTab(
          title: 'Filiais',
          icon: Icons.account_tree,
          customWidget: parceiroId > 0
              ? FiliaisParceiroScreen(
                  matrizId: parceiroId,
                  empresaId: empresaIdInt,
                  hasPermission: hasPermission,
                )
              : const Center(
                  child: Text('Salve o parceiro antes de ver as filiais.')),
        ),
        RelatedGridTab(
          title: 'Logins',
          icon: Icons.person,
          telaNome: 'login',
          extraParams: {'parcId': id, 'empresaId': empresaId},
          // Fix (2026-09-16): "Tipo Login" e' obrigatorio no backend
          // (LoginController rejeita com 400 "Tipo Login e obrigatorio"
          // desde o hotfix de seguranca que impediu o default silencioso
          // pra MASTER -- ver bugs.md). O campo fica isInForm: false
          // (loginHiddenFields, herdado de WebLoginGridScreen.fieldOverrides)
          // porque ninguem deve escolher isso na UI aqui dentro de Parceiro
          // -- todo login criado por esta aba e' de um CLIENTE vinculado a
          // este parceiro, entao o tipo e' sempre APP_ABRACO (id 6, o
          // mesmo tipo usado em todo o app pra login de cliente com
          // parceiro -- MASTER/APP_CONTABILIDADE sao exclusivos de login
          // interno da contabilidade, nunca criados por esta tela).
          additionalFormData: {
            ...WebLoginGridScreen.additionalFormData,
            'tipoLogin': 6,
          },
          // Fix card #427 (reincidencia): faltavam os overrides de Foto
          // (FieldType.file) e Roles (multiselect) que a tela direta
          // WebLoginGridScreen ja usa via fieldOverrides(). Sem eles o
          // form aqui dentro de Parceiro renderiza Foto como texto simples
          // e usa a config padrao (do banco) para os demais campos,
          // causando ordem/tipo diferentes e falha 400 ao salvar.
          fieldOverrides: [
            ...WebLoginGridScreen.fieldOverrides(),
            FieldConfigWindows(
              label: 'Empresa (Nome)',
              fieldName: 'empresa',
              displayFieldName: 'empresa.nome',
              icon: Icons.business,
              fieldType: FieldType.dropdown,
              dropdownOptions: empresaId.isNotEmpty
                  ? [
                      {
                        'id': empresaId,
                        'label': empresaNome.isNotEmpty
                            ? empresaNome
                            : 'Empresa #$empresaId'
                      }
                    ]
                  : [],
              dropdownValueField: 'id',
              dropdownDisplayField: 'label',
              dropdownSelectedValue: empresaId.isNotEmpty ? empresaId : null,
              isInForm: true,
              isFilterable: false,
              enabled: false,
            ),
            FieldConfigWindows(
              label: 'Parceiro',
              fieldName: 'parceiro',
              displayFieldName: 'parceiro.nome',
              icon: Icons.person_outline,
              fieldType: FieldType.dropdown,
              dropdownOptions: parceiroId > 0
                  ? [
                      {'value': parceiroId.toString(), 'label': parceiroNome}
                    ]
                  : [],
              dropdownValueField: 'value',
              dropdownDisplayField: 'label',
              dropdownSelectedValue:
                  parceiroId > 0 ? parceiroId.toString() : null,
              isInForm: true,
              isFilterable: false,
              enabled: false,
            ),
          ],
        ),
        RelatedGridTab(
          title: 'Contas a Pagar',
          icon: Icons.money_off,
          telaNome: 'conta_pagar',
          extraParams: {'parceiro': id, 'empresaId': empresaId},
        ),
        RelatedGridTab(
          title: 'Contas a Receber',
          icon: Icons.attach_money,
          telaNome: 'conta_receber',
          extraParams: {'parceiroId': id, 'empresaId': empresaId},
        ),
        RelatedGridTab(
          title: 'Chamados',
          icon: Icons.support_agent,
          telaNome: 'chamado',
          extraParams: {'parceiroId': id, 'empresaId': empresaId},
        ),
        RelatedGridTab(
          title: 'Comunicados',
          icon: Icons.campaign,
          telaNome: 'comunicado',
          extraParams: {'empId': empresaId, 'parceiroId': id},
          transformFormData:
              WebComunicadoGridComponentesScreen.transformFormData,
        ),
        RelatedGridTab(
          title: 'POP/Mail',
          icon: Icons.mail_outline,
          customWidget: parceiroId > 0
              ? SmtpConfigTab(
                  scope: SmtpConfigScope.parceiro,
                  id: parceiroId,
                  nome: parceiroNome,
                )
              : const Center(child: Text('ID do parceiro não disponível')),
        ),
        // ── Certificado Digital do Parceiro ──────────────────────────────
        RelatedGridTab(
          title: 'Certificado Digital',
          icon: Icons.security,
          customWidget: parceiroId > 0
              ? CertificadoEmpresaScreen(
                  parceiroId: parceiroId,
                  empresaNome: parceiroNome,
                )
              : const Center(child: Text('ID do parceiro não disponível')),
        ),
        // ── Séries NF-e do Parceiro ──────────────────────────────────────
        RelatedGridTab(
          title: 'Séries NF-e',
          icon: Icons.format_list_numbered,
          telaNome: 'nfe_serie',
          extraParams: {'parcId': id, 'empresaId': empresaId},
        ),
        // ── Cobrança de Módulos ───────────────────────────────────────
        RelatedGridTab(
          title: 'Cobrança de Módulos',
          icon: Icons.attach_money,
          customWidget: parceiroId > 0
              ? ModuloCobrancaScreen(
                  parceiroId: parceiroId,
                  parceiroNome: parceiroNome,
                )
              : const Center(child: Text('ID do parceiro não disponível')),
        ),
        // ── GED — documentos do parceiro (H5-21) ─────────────────────────
        RelatedGridTab(
          title: 'GED',
          icon: Icons.folder_open,
          customWidget: parceiroId > 0
              ? GedArquivosScreen(
                  moduloOrigem: 'parceiro',
                  idOrigem: parceiroId,
                  nomeOrigem: parceiroNome,
                  empresaId: empresaIdInt,
                )
              : const Center(child: Text('ID do parceiro não disponível')),
        ),
        RelatedGridTab(
          title: 'Configuração CNAB',
          icon: Icons.account_balance,
          customWidget: parceiroId > 0
              ? CnabConfigScreen(
                  empresaId: empresaIdInt,
                  parceiroId: parceiroId,
                )
              : const Center(child: Text('ID do parceiro não disponível')),
        ),
      ],
    );
  }
}
