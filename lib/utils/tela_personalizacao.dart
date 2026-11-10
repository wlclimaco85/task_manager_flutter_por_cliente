import '../models/telas_model.dart';
import '../services/dicionario_campo_service.dart';

/// Aplica sobre a tela os rotulos e ligacoes (FK) que a empresa definiu no Dicionario de Dados.
/// Funcao pura: devolve uma NOVA tela; a original (compartilhada, vinda do servidor) nao e alterada.
/// - rotulo: troca so o `label` do campo (tipo e nome nunca mudam);
/// - ligacao: o campo vira lista de busca (dropdown) no endpoint da ligacao.
TelaConfig aplicarPersonalizacaoTela(TelaConfig tela, PersonalizacaoTela p) {
  if (p.vazia) return tela;
  final ligacoes = {for (final l in p.ligacoes) l.campo.toLowerCase(): l};
  final campos = [
    for (final f in tela.fields)
      _personalizar(f, p.labels[f.fieldName.toLowerCase()], ligacoes[f.fieldName.toLowerCase()]),
  ];
  return TelaConfig(
    id: tela.id,
    nome: tela.nome,
    titulo: tela.titulo,
    fetchEndpoint: tela.fetchEndpoint,
    createEndpoint: tela.createEndpoint,
    updateEndpoint: tela.updateEndpoint,
    deleteEndpoint: tela.deleteEndpoint,
    fields: campos,
    idFieldName: tela.idFieldName,
    dateFieldName: tela.dateFieldName,
    storageKey: tela.storageKey,
    enableSearch: tela.enableSearch,
    enableDebugMode: tela.enableDebugMode,
    useUserBannerAppBar: tela.useUserBannerAppBar,
    actions: tela.actions,
    relatedGrids: tela.relatedGrids,
  );
}

TelaField _personalizar(TelaField f, String? label, LigacaoCampo? ligacao) {
  if (label == null && ligacao == null) return f;
  return TelaField(
    label: label ?? f.label,
    fieldName: f.fieldName,
    displayFieldName: f.displayFieldName,
    isFilterable: f.isFilterable,
    isInForm: f.isInForm,
    showInInsert: f.showInInsert,
    showInUpdate: f.showInUpdate,
    isSortable: f.isSortable,
    flex: f.flex,
    maxLines: f.maxLines,
    icon: f.icon,
    iconData: f.iconData,
    fieldType: ligacao != null ? TelaFieldType.dropdown : f.fieldType,
    dropdownOptions: ligacao != null ? const [] : f.dropdownOptions,
    dropdownEndpoint: ligacao?.endpoint ?? f.dropdownEndpoint,
    dropdownValueField: ligacao?.campoChave ?? f.dropdownValueField,
    dropdownDisplayField: ligacao?.campoExibicao ?? f.dropdownDisplayField,
    dateFormat: f.dateFormat,
    firstDate: f.firstDate,
    lastDate: f.lastDate,
    defaultValue: f.defaultValue,
    dropdownSelectedValue: f.dropdownSelectedValue,
    isRequired: f.isRequired,
    isVisibleByDefault: f.isVisibleByDefault,
    isFixed: f.isFixed,
    enabled: f.enabled,
    allowedExtensions: f.allowedExtensions,
    allowMultipleFiles: f.allowMultipleFiles,
    maxFileSize: f.maxFileSize,
    fileFieldName: f.fileFieldName,
    showInCard: f.showInCard,
    multiSelect: f.multiSelect,
    fieldOrder: f.fieldOrder,
    visibleWhen: f.visibleWhen,
  );
}

/// Busca a personalizacao da tela e a aplica; qualquer falha devolve a tela original (a grid nunca quebra por isso).
Future<TelaConfig> telaComPersonalizacao(
  TelaConfig tela,
  Future<PersonalizacaoTela> Function(String telaNome) buscar,
) async {
  try {
    return aplicarPersonalizacaoTela(tela, await buscar(tela.nome));
  } catch (_) {
    return tela;
  }
}
