/// Estado genérico de carregamento dos dashboards por área (Fase 171).
/// Generaliza o padrão já usado manualmente em WindowsDashboardFinanceiroScreen
/// (loading/error com "Nenhum dado encontrado") em uma classe reaproveitável
/// pelos 5 dashboards de área (Atendimento, Financeiro, Comercial, DP, Fiscal).
library;

enum DashboardAreaStatus { loading, vazio, erro, sucesso }

class DashboardAreaState<T> {
  final DashboardAreaStatus status;
  final T? dados;
  final String? mensagemErro;

  const DashboardAreaState.loading()
      : status = DashboardAreaStatus.loading,
        dados = null,
        mensagemErro = null;

  const DashboardAreaState.vazio()
      : status = DashboardAreaStatus.vazio,
        dados = null,
        mensagemErro = null;

  const DashboardAreaState.erro(String mensagem)
      : status = DashboardAreaStatus.erro,
        dados = null,
        mensagemErro = mensagem;

  const DashboardAreaState.sucesso(this.dados)
      : status = DashboardAreaStatus.sucesso,
        mensagemErro = null;
}
