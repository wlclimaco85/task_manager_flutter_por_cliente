import '../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType;

/// Mapa centralizado de field overrides por tela.
///
/// Chave = widget.telaNome (ex: 'conta_pagar', 'conta_receber').
/// Valor = lista de FieldConfigWindows — mesma semântica do fieldOverrides inline.
///
/// Regra de prioridade:
///   - Se a tela passou fieldOverrides explicitamente → usa os da tela (ignora este mapa)
///   - Se fieldOverrides == null → usa a entrada deste mapa (se existir)
///   - Se não há entrada → nenhum override aplicado (comportamento original)
///
/// Como usar durante sessão de validação:
///   Adicione uma entrada com o telaNome e liste apenas os campos que precisam mudar.
///   Exemplos de operações comuns:
///
///   Sumir do form:       FieldConfigWindows(fieldName: 'campo', label: '', isInForm: false, isInGrid: false, isVisibleByDefault: false)
///   Mudar label:         FieldConfigWindows(fieldName: 'campo', label: 'Novo Label', isInForm: true)
///   Desabilitar:         FieldConfigWindows(fieldName: 'campo', label: 'Label', isInForm: true, enabled: false)
///   Sumir da grid:       FieldConfigWindows(fieldName: 'campo', label: '', isInGrid: false, isVisibleByDefault: false)

const Map<String, List<FieldConfigWindows>> kScreenFieldOverrides = {
  // Adicione entradas abaixo durante a sessão de validação tela a tela.
  // Formato:
  //
  // 'nome_da_tela': [
  //   FieldConfigWindows(fieldName: 'campo', label: '', isInForm: false, isInGrid: false, isVisibleByDefault: false),
  // ],

  'conta_pagar': [
    // Oculta o campo legado 'parceiro' do form e da grid (substituído por parceiroDev/parceiroRec)
    FieldConfigWindows(
        fieldName: 'parceiro',
        label: '',
        isInForm: false,
        isInGrid: false,
        isVisibleByDefault: false),
    // parceiroDev: override já definido inline na tela (dropdown enum); não duplicar aqui
    // parceiroRec: requer TenantContext em runtime, não pode ser const; definido na tela
  ],
  'parceiro': [
    FieldConfigWindows(
        fieldName: 'modulo_servicos',
        label: '',
        isInForm: false,
        isInGrid: false,
        isVisibleByDefault: false),
    FieldConfigWindows(
        fieldName: 'moduloServicos',
        label: '',
        isInForm: false,
        isInGrid: false,
        isVisibleByDefault: false),
    FieldConfigWindows(
        fieldName: 'modulosServico',
        label: '',
        isInForm: false,
        isInGrid: false,
        isVisibleByDefault: false),
  ],
  'nfce': [
    FieldConfigWindows(
        label: 'Id', fieldName: 'id', isInForm: false, isFixed: true, flex: 1),
    FieldConfigWindows(
        label: 'Empresa Id',
        fieldName: 'empresaId',
        isInForm: false,
        fieldType: FieldType.number,
        flex: 1),
    FieldConfigWindows(
        label: 'Empresa', fieldName: 'empresaNome', isInForm: false, flex: 2),
    FieldConfigWindows(
        label: 'Parceiro Id',
        fieldName: 'parceiroId',
        isInForm: false,
        fieldType: FieldType.number,
        flex: 1),
    FieldConfigWindows(
        label: 'Chave Acesso',
        fieldName: 'chaveAcesso',
        isInForm: false,
        flex: 3),
    FieldConfigWindows(
        label: 'Numero',
        fieldName: 'numero',
        isInForm: false,
        fieldType: FieldType.number,
        flex: 1),
    FieldConfigWindows(
        label: 'Serie',
        fieldName: 'serie',
        isInForm: false,
        fieldType: FieldType.number,
        flex: 1),
    FieldConfigWindows(label: 'UF', fieldName: 'uf', isInForm: false, flex: 1),
    FieldConfigWindows(
        label: 'Ambiente', fieldName: 'ambiente', isInForm: false, flex: 2),
    FieldConfigWindows(
        label: 'Status Sefaz',
        fieldName: 'statusSefaz',
        isInForm: false,
        flex: 2),
    FieldConfigWindows(
        label: 'Protocolo', fieldName: 'protocolo', isInForm: false, flex: 2),
    FieldConfigWindows(
        label: 'Codigo Retorno',
        fieldName: 'codigoRetorno',
        isInForm: false,
        flex: 1),
    FieldConfigWindows(
        label: 'Motivo', fieldName: 'motivoRejeicao', isInForm: false, flex: 3),
    FieldConfigWindows(
        label: 'XML Enviado',
        fieldName: 'xmlEnviadoDisponivel',
        isInForm: false,
        fieldType: FieldType.boolean,
        flex: 1),
    FieldConfigWindows(
        label: 'XML Autorizado',
        fieldName: 'xmlAutorizadoDisponivel',
        isInForm: false,
        fieldType: FieldType.boolean,
        flex: 1),
    FieldConfigWindows(
        label: 'DANFE URL',
        fieldName: 'danfeUrl',
        isInForm: false,
        isVisibleByDefault: false,
        flex: 2),
    FieldConfigWindows(
        label: 'Venda Id',
        fieldName: 'vendaId',
        isInForm: false,
        fieldType: FieldType.number,
        flex: 1),
    FieldConfigWindows(
        label: 'Data Emissao',
        fieldName: 'dataEmissao',
        isInForm: false,
        fieldType: FieldType.date,
        flex: 2),
    FieldConfigWindows(
        label: 'Data Autorizacao',
        fieldName: 'dataAutorizacao',
        isInForm: false,
        fieldType: FieldType.date,
        flex: 2),
    FieldConfigWindows(
        label: 'Data Contingencia',
        fieldName: 'dataContingencia',
        isInForm: false,
        fieldType: FieldType.date,
        isVisibleByDefault: false,
        flex: 2),
    FieldConfigWindows(
        label: 'Tp Emis', fieldName: 'tpEmis', isInForm: false, flex: 1),
    FieldConfigWindows(
        label: 'Justificativa',
        fieldName: 'justificativaContingencia',
        isInForm: false,
        isVisibleByDefault: false,
        flex: 3),
    FieldConfigWindows(
        label: 'Recibo EPEC',
        fieldName: 'numeroReciboEpec',
        isInForm: false,
        isVisibleByDefault: false,
        flex: 2),
    FieldConfigWindows(
        label: 'Protocolo EPEC',
        fieldName: 'protocoloEpec',
        isInForm: false,
        isVisibleByDefault: false,
        flex: 2),
    FieldConfigWindows(
        label: 'Data EPEC',
        fieldName: 'dataEpec',
        isInForm: false,
        fieldType: FieldType.date,
        isVisibleByDefault: false,
        flex: 2),
    FieldConfigWindows(
        label: 'Modelo', fieldName: 'modelo', isInForm: false, flex: 1),
  ],
};
