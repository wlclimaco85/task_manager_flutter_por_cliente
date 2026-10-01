import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../models/avaliacao_fisica_model.dart';
import '../../../models/treino_model.dart';
import '../../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';

/// Tela de Home Saúde do Aluno — V003 Fitness.
/// Exibe: boas-vindas, peso + IMC da avaliação mais recente,
/// último treino registrado. Dados reais do backend via GET.
class WebHomeSaudeAlunoScreen extends StatefulWidget {
  const WebHomeSaudeAlunoScreen({super.key});

  @override
  State<WebHomeSaudeAlunoScreen> createState() =>
      _WebHomeSaudeAlunoScreenState();
}

class _WebHomeSaudeAlunoScreenState extends State<WebHomeSaudeAlunoScreen> {
  bool _carregando = true;
  String? _erro;

  AvaliacaoFisica? _ultimaAvaliacao;
  Treino? _ultimoTreino;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final caller = NetworkCaller();
      final resAvaliacao =
          await caller.getRequest(ApiLinks.allAvaliacoesFisicas);
      final resTreino = await caller.getRequest(ApiLinks.allTreinos);

      AvaliacaoFisica? ultimaAvaliacao;
      Treino? ultimoTreino;

      if (resAvaliacao.isSuccess && resAvaliacao.body != null) {
        final body = resAvaliacao.body!;
        List<dynamic> itens = [];
        if (body['content'] is List) {
          itens = body['content'] as List;
        } else if (body['data'] is List) {
          itens = body['data'] as List;
        }
        if (itens.isNotEmpty) {
          final avaliacoes = itens
              .map((e) => AvaliacaoFisica.fromJson(e as Map<String, dynamic>))
              .toList();
          avaliacoes.sort((a, b) =>
              (b.dtAvaliacao ?? '').compareTo(a.dtAvaliacao ?? ''));
          ultimaAvaliacao = avaliacoes.first;
        }
      }

      if (resTreino.isSuccess && resTreino.body != null) {
        final body = resTreino.body!;
        List<dynamic> itens = [];
        if (body['content'] is List) {
          itens = body['content'] as List;
        } else if (body['data'] is List) {
          itens = body['data'] as List;
        }
        if (itens.isNotEmpty) {
          final treinos = itens
              .map((e) => Treino.fromJson(e as Map<String, dynamic>))
              .toList();
          treinos.sort((a, b) => (b.dtTreino ?? '').compareTo(a.dtTreino ?? ''));
          ultimoTreino = treinos.first;
        }
      }

      if (mounted) {
        setState(() {
          _ultimaAvaliacao = ultimaAvaliacao;
          _ultimoTreino = ultimoTreino;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Falha ao carregar dados: $e';
          _carregando = false;
        });
      }
    }
  }

  String _nomeAluno() {
    final dadosPessoal =
        AuthUtility.userInfo?.data?.codDadosPessoal;
    if (dadosPessoal?.nome != null && dadosPessoal!.nome!.isNotEmpty) {
      return dadosPessoal.nome!;
    }
    final login = AuthUtility.userInfo?.login;
    if (login?.nome != null && login!.nome!.isNotEmpty) return login.nome!;
    final data = AuthUtility.userInfo?.data;
    final firstName = data?.firstName ?? '';
    final lastName = data?.lastName ?? '';
    final nomeCompleto = '$firstName $lastName'.trim();
    if (nomeCompleto.isNotEmpty) return nomeCompleto;
    return 'Aluno';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        title: const Text(
          'Saúde do Aluno',
          style: TextStyle(color: GridColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: GridColors.textPrimary),
            onPressed: _carregarDados,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? _buildErro()
              : _buildConteudo(),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: GridColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              _erro!,
              style: const TextStyle(color: GridColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(backgroundColor: GridColors.primary),
              onPressed: _carregarDados,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Tentar novamente',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardBoasVindas(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _cardAvaliacaoFisica()),
              const SizedBox(width: 16),
              Expanded(child: _cardUltimoTreino()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardBoasVindas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [GridColors.primary, GridColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: GridColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child:
                Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${_nomeAluno()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Acompanhe sua evolução de saúde e treinos',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite, color: Colors.white54, size: 40),
        ],
      ),
    );
  }

  Widget _cardAvaliacaoFisica() {
    final avaliacao = _ultimaAvaliacao;
    return _buildCard(
      titulo: 'Última Avaliação Física',
      icone: Icons.monitor_weight,
      corIcone: GridColors.secondary,
      filho: avaliacao == null
          ? _buildVazio('Nenhuma avaliação registrada')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (avaliacao.dtAvaliacao != null)
                  _linhaInfo(
                    Icons.calendar_month,
                    'Data',
                    _formatarData(avaliacao.dtAvaliacao!),
                  ),
                if (avaliacao.peso != null)
                  _linhaInfo(
                    Icons.monitor_weight_outlined,
                    'Peso',
                    '${avaliacao.peso!.toStringAsFixed(1)} kg',
                  ),
                if (avaliacao.altura != null)
                  _linhaInfo(
                    Icons.height,
                    'Altura',
                    '${avaliacao.altura!.toStringAsFixed(2)} m',
                  ),
                if (avaliacao.imc != null) ...[
                  _linhaInfo(
                    Icons.analytics_outlined,
                    'IMC',
                    avaliacao.imc!.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 8),
                  _badgeImc(avaliacao.imc!),
                ],
                if (avaliacao.observacao != null &&
                    avaliacao.observacao!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      avaliacao.observacao!,
                      style: const TextStyle(
                          fontSize: 12, color: GridColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _cardUltimoTreino() {
    final treino = _ultimoTreino;
    return _buildCard(
      titulo: 'Último Treino',
      icone: Icons.fitness_center,
      corIcone: GridColors.primary,
      filho: treino == null
          ? _buildVazio('Nenhum treino registrado')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  treino.nome ?? 'Treino sem nome',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GridColors.textSecondary,
                  ),
                ),
                if (treino.dtTreino != null) ...[
                  const SizedBox(height: 8),
                  _linhaInfo(
                    Icons.calendar_month,
                    'Data',
                    _formatarData(treino.dtTreino!),
                  ),
                ],
                if (treino.tipo != null)
                  _linhaInfo(Icons.category_outlined, 'Tipo', treino.tipo!),
                if (treino.duracao != null)
                  _linhaInfo(
                    Icons.timer_outlined,
                    'Duração',
                    '${treino.duracao} min',
                  ),
                if (treino.descricao != null && treino.descricao!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      treino.descricao!,
                      style: const TextStyle(
                          fontSize: 12, color: GridColors.textMuted),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCard({
    required String titulo,
    required IconData icone,
    required Color corIcone,
    required Widget filho,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: corIcone, size: 22),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: GridColors.textSecondary,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: GridColors.divider),
          filho,
        ],
      ),
    );
  }

  Widget _linhaInfo(IconData icone, String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icone, size: 16, color: GridColors.textMuted),
          const SizedBox(width: 6),
          Text(
            '$rotulo: ',
            style: const TextStyle(
              fontSize: 13,
              color: GridColors.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: GridColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVazio(String mensagem) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: GridColors.textMuted, size: 18),
          const SizedBox(width: 8),
          Text(
            mensagem,
            style: const TextStyle(color: GridColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Badge de classificação do IMC seguindo tabela OMS.
  Widget _badgeImc(double imc) {
    String classificacao;
    Color cor;
    if (imc < 18.5) {
      classificacao = 'Abaixo do peso';
      cor = GridColors.info;
    } else if (imc < 25) {
      classificacao = 'Peso normal';
      cor = GridColors.success;
    } else if (imc < 30) {
      classificacao = 'Sobrepeso';
      cor = GridColors.warning;
    } else {
      classificacao = 'Obesidade';
      cor = GridColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.4)),
      ),
      child: Text(
        classificacao,
        style:
            TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Formata data ISO (yyyy-MM-dd ou yyyy-MM-ddTHH:mm:ss) para dd/MM/yyyy.
  String _formatarData(String data) {
    try {
      final dt = DateTime.parse(data);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return data;
    }
  }
}
