import 'package:flutter/material.dart';
import '../../widgets/user_banners.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import '../../../utils/security_matrix.dart';
import 'chamado_grid_screen.dart';
import '../../services/network_caller.dart';
import '../../models/network_response.dart';
import '../../widgets/chamado_detalhe_screen.dart';
import '../../models/chamado_model.dart' as chamado_model;
import '../../models/auth_utility.dart';
import '../../services/chat_caller.dart';
import 'chatMessageListScreen.dart';

class ChamadosScreenDinamic extends StatefulWidget {
  const ChamadosScreenDinamic({super.key});

  @override
  State<ChamadosScreenDinamic> createState() => _ChamadosScreenDinamicState();
}

class _ChamadosScreenDinamicState extends State<ChamadosScreenDinamic> {
  List<Chamado> chamados = [];
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChamados();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _hasPermission(String permission) {
    final sec = SecurityMatrix.current();
    final lower = permission.toLowerCase();
    if (lower.contains('create') || lower.contains('insert')) {
      return sec.canInsert(AppScreen.chamados);
    }
    if (lower.contains('edit') || lower.contains('update')) {
      return sec.canUpdate(AppScreen.chamados);
    }
    if (lower.contains('delete') || lower.contains('remove')) {
      return sec.canDelete(AppScreen.chamados);
    }
    return sec.canView(AppScreen.chamados);
  }

  Future<void> _loadChamados() async {
    setState(() => isLoading = true);
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.allChamados);

      if (response.statusCode == 200 && response.body != null) {
        final responseData = response.body!['data'];
        final List<dynamic> data = responseData is Map
            ? responseData['dados'] ?? []
            : responseData ?? [];

        final List<Chamado> loaded = data
            .map((json) => Chamado.fromJson(Map<String, dynamic>.from(json)))
            .toList();

        setState(() {
          chamados = loaded;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar chamados: $e')),
        );
      }
    }
  }

  Map<String, List<Chamado>> _groupBySector() {
    final grouped = <String, List<Chamado>>{};
    for (final chamado in chamados) {
      final setorNome = chamado.setor?.nome ?? 'Sem setor';
      grouped.putIfAbsent(setorNome, () => []).add(chamado);
    }
    return grouped;
  }

  Color _getStatusColor(StatusChamadoEnum status) {
    switch (status) {
      case StatusChamadoEnum.ABERTO:
        return GridColors.secondary;
      case StatusChamadoEnum.EM_ANDAMENTO:
        return const Color(0xFFFFA500);
      case StatusChamadoEnum.FECHADO:
        return GridColors.primary;
      case StatusChamadoEnum.CANCELADO:
        return GridColors.divider;
    }
  }

  Color _getPriorityColor(PrioridadeChamadoEnum prioridade) {
    switch (prioridade) {
      case PrioridadeChamadoEnum.ALTA:
        return const Color(0xFFEF4444);
      case PrioridadeChamadoEnum.MEDIA:
        return const Color(0xFFFACC15);
      case PrioridadeChamadoEnum.BAIXA:
        return const Color(0xFF3B82F6);
      default:
        return GridColors.divider;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupBySector();

    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: UserBannerAppBar(
        screenTitle: 'Solicitações / Chamados',
        onRefresh: _loadChamados,
      ),
      floatingActionButton: _hasPermission('create')
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Implementar novo chamado
              },
              backgroundColor: GridColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar chamados...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Lista agrupada por setor
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator.adaptive(
                    onRefresh: _loadChamados,
                    child: grouped.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: GridColors.divider,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhum chamado encontrado',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: grouped.length,
                            itemBuilder: (context, index) {
                              final setorNome =
                                  grouped.keys.elementAt(index);
                              final chamadosDoSetor =
                                  grouped[setorNome]!;

                              return _buildSectorExpansion(
                                setorNome,
                                chamadosDoSetor,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorExpansion(
    String setorNome,
    List<Chamado> setorChamados,
  ) {
    final filtrados = _searchController.text.isEmpty
        ? setorChamados
        : setorChamados
            .where((c) => c.titulo
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();

    if (filtrados.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        elevation: 2,
        color: GridColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(
                Icons.build,
                color: GridColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  setorNome,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: GridColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filtrados.length}',
                  style: TextStyle(
                    color: GridColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: filtrados
                    .map((chamado) => _buildChamadoTile(chamado))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirDetalheChamado(Chamado chamado) {
    // A tela dinâmica mobile usa a classe Chamado local (duplicada) —
    // convertemos para o model canônico (lib/models/chamado_model.dart)
    // via toJson/fromJson, que é o tipo esperado por ChamadoDetalheScreen.
    final chamadoModel = chamado_model.Chamado.fromJson(chamado.toJson());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChamadoDetalheScreen(
          chamado: chamadoModel,
          // Fix (card #473): navega para a tela real de Chat/Atendimento
          // já com a conversa deste chamado selecionada.
          onAbrirChat: (context, chamado) {
            final chatId = buildChamadoChatId(chamado.empresa.id ?? 0,
                chamado.parceiro!.id ?? 0, chamado.id ?? 0);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatListScreen(
                  userName: AuthUtility.userInfo?.login?.email ??
                      AuthUtility.userInfo?.data?.email ??
                      '',
                  initialChatId: chatId,
                  initialSector: chamado.setor?.nome,
                ),
              ),
            );
          },
        ),
      ),
    ).then((_) => _loadChamados());
  }

  Widget _buildChamadoTile(Chamado chamado) {
    return InkWell(
      onTap: () => _abrirDetalheChamado(chamado),
      borderRadius: BorderRadius.circular(8),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GridColors.pageBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GridColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + ID + Badges de status e prioridade
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${chamado.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chamado.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badges de status e prioridade
              Column(
                children: [
                  _buildStatusBadge(chamado.status),
                  const SizedBox(height: 4),
                  _buildPriorityBadge(chamado.prioridade),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Descrição
          Text(
            chamado.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          // Data de abertura e usuário
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _formatDate(chamado.dataAbertura),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              if (chamado.usuarioAbertura != null)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          chamado.usuarioAbertura!.nome ?? chamado.usuarioAbertura!.email ?? 'Sem nome',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatusBadge(StatusChamadoEnum status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1,
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(PrioridadeChamadoEnum prioridade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor(prioridade).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getPriorityColor(prioridade),
          width: 1,
        ),
      ),
      child: Text(
        prioridade.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _getPriorityColor(prioridade),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
