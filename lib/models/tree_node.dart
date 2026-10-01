/// Nó genérico para representar estruturas hierárquicas (árvores)
class TreeNode<T> {
  final String name;
  final List<T> items;
  final List<TreeNode<T>> children;

  TreeNode({
    required this.name,
    this.items = const [],
    this.children = const [],
  });

  /// Conta total de itens (inclui filhos recursivamente)
  int get totalItems {
    int count = items.length;
    for (final child in children) {
      count += child.totalItems;
    }
    return count;
  }

  /// Verifica se nó está vazio (sem itens e filhos)
  bool get isEmpty => items.isEmpty && children.isEmpty;

  /// Expande todos os nós recursivamente
  void expandAll() {
    for (final child in children) {
      child.expandAll();
    }
  }
}
