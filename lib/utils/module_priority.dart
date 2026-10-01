/// Resolve o módulo de maior prioridade contratado pelo cliente.
///
/// Ordem de prioridade (definida pelo produto):
///   Comercial > NFS-e > Financeiro > Departamento Pessoal
///
/// Usado pelo:
///   - BottomNavBarScreen (slot dinâmico)
///   - HomeScreen (rota contextual pós-login)
///   - AppSidebar (expansão padrão)
class ModulePriority {
  ModulePriority._();

  static const _priorityOrder = [
    'Comercial',
    'NFS-e',
    'Financeiro',
    'Departamento Pessoal',
  ];

  /// Retorna o nome do módulo de maior prioridade a partir da lista de
  /// módulos contratados, ou `null` se nenhum módulo da lista estiver
  /// contratado.
  static String? highest(List<String> contratados) {
    for (final mod in _priorityOrder) {
      if (contratados.contains(mod)) return mod;
    }
    return null;
  }
}
