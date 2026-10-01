class ApiLinks {
  ApiLinks._();

  // URL do backend
  // Dev local: flutter run usa base efetiva http://127.0.0.1:9001/boletobancos
  // Producao Railway: flutter run --dart-define=BACKEND_URL=https://appacademia-production-be7e.up.railway.app
  // String.fromEnvironment SO funciona como const constructor — declarar
  // como "final" quebra em runtime no DDC (debug web) com
  // "Unsupported operation: String.fromEnvironment can only be used as a
  // const constructor". Precisa ficar const mesmo com o resto da cadeia
  // (_baseIp em diante) sendo final.
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:9001',
  );

  // Context-path do backend: server.servlet.context-path=/boletobancos em
  // TODOS os perfis (application.properties, que se aplica sempre, e
  // application-prod.properties desde o commit fced12a3 de 2026-08-13
  // "fix: corrigir context-path e schema de contrato em producao" —
  // LegacyBoletobancosPathFilter so agiria se o context-path estivesse
  // vazio, o que nao e mais o caso). Por isso o prefixo e SEMPRE anexado,
  // independente de dev local ou producao.
  //
  // HISTORICO (nao repetir o erro): entre 2026-08-13 e 2026-08-14 esse
  // prefixo virou condicional (so para backend "local", detectado por nao
  // comecar com "https://") com base num comentario que dizia "em producao
  // o context-path e vazio" — verdade so ANTES do commit fced12a3 do mesmo
  // dia 08-13. Isso quebrou TODA chamada de API em producao (login incluido)
  // silenciosamente por 8 dias: a URL final ficava sem /boletobancos, o
  // Tomcat devolvia 404 fora do context-path (sem passar pelo CorsFilter do
  // Spring, que so roda dentro do context-path), e o navegador reportava
  // isso como bloqueio de CORS (mensagem generica do Chrome para qualquer
  // fetch cross-origin sem resposta), mascarando a causa real. Ver incidente
  // P0 2026-08-21 (escritorio-contabil-production.up.railway.app).
  //
  // String.fromEnvironment SO funciona como const constructor (mesmo motivo
  // de _backendUrl acima) — manter const, nunca converter para final.
  static const String _backendContextPath = String.fromEnvironment(
    'BACKEND_CONTEXT_PATH',
    defaultValue: '/boletobancos',
  );
  static final String _baseIp = '$_backendUrl$_backendContextPath';

  // WebSocket: converte http→ws e https→wss
  static String get _wsUrl => _backendUrl
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://');

  // _chatId usado apenas por chatStart (WebSocket) — derivada do host do
  // backend. Mesmo context-path configurado para as chamadas HTTP.
  static final String _chatId = '$_wsUrl$_backendContextPath';
  static final String _baseUrl = 'https://task.teamrabbil.com/api/v1';
  static final String _baseUrlNew = _baseIp;
  static final String allPersonal = '$_baseUrlNew/personal/findAll';
  static final String allAcademia = '$_baseUrlNew/academia/findAll';
  static final String allModalidade = '$_baseUrlNew/modalidade/findAll';
  static final String allTipoRefeicao = '$_baseUrlNew/dieta/findByRefeicao';
  static final String allUniMeds = '$_baseUrlNew/unidade/findAll';
  static final String insertPersonal = '$_baseUrlNew/personal/inserir';
  static final String insertSuplemento = '$_baseUrlNew/suplemento/insert';
  static final String insertAcademia = '$_baseUrlNew/academia/inserir';
  static final String allSuplementoAluno =
      '$_baseUrlNew/suplemento/findByIdAluno';
  static final String insertAluno = '$_baseUrlNew/rest/auth/inserirAluno';
  static final String insertExame = '$_baseUrlNew/exame/inserir';
  static final String findByIdAluno = '$_baseUrlNew/exame/findByParceiros';
  static final String insertMedicamento = '$_baseUrlNew/medicamento/inserir';
  static final String findByAlunoByMedicamento =
      '$_baseUrlNew/medicamento/findByParceiros';
  static final String findByAlunoByDieta = '$_baseUrlNew/dieta/findByParceiros';
  // static String login = '$_baseUrl/login';
  // static String login = '$_baseUrl/rest/auth/login';

  static String login = '$_baseUrlNew/rest/auth/login';
  static String get solicitacaoAcesso => '$_baseUrlNew/api/solicitacao-acesso';
  static String get solicitacaoAcessoPendentes =>
      '$_baseUrlNew/api/solicitacao-acesso/pendentes';
  static String solicitacaoAcessoAprovar(int id) =>
      '$_baseUrlNew/api/solicitacao-acesso/$id/aprovar';
  static String solicitacaoAcessoRejeitar(int id) =>
      '$_baseUrlNew/api/solicitacao-acesso/$id/rejeitar';
  static String get loginEmpresasAcesso =>
      '$_baseUrlNew/api/login/me/empresas-acesso';
  static String get loginEmpresasAcessoSolicitar =>
      '$_baseUrlNew/api/login/me/empresas-acesso/solicitar';
  static String loginEmpresasAcessoDoLogin(int loginId) =>
      '$_baseUrlNew/api/login/$loginId/empresas-acesso';
  static String loginEmpresasDisponiveisDoLogin(int loginId) =>
      '$_baseUrlNew/api/login/$loginId/empresas-acesso/empresas-disponiveis';
  static String loginEmpresasAcessoDoLoginSolicitar(int loginId) =>
      '$_baseUrlNew/api/login/$loginId/empresas-acesso/solicitar';
  static String get loginEmpresaAtiva =>
      '$_baseUrlNew/api/login/me/empresa-ativa';
  static String get loginEmpresaAcessoPendentes =>
      '$_baseUrlNew/api/login-empresa-acesso/pendentes';
  static String loginEmpresaAcessoAprovar(int id) =>
      '$_baseUrlNew/api/login-empresa-acesso/$id/aprovar';
  static String loginEmpresaAcessoNegar(int id) =>
      '$_baseUrlNew/api/login-empresa-acesso/$id/negar';

  // Controle de Sessao (bug de producao 2026-09-11): Sistema > Sessoes --
  // listar/matar sessoes ativas. Replicado igual em task_manager_admin_panel.
  static String get sessoesAtivas => '$_baseUrlNew/api/sessoes';
  static String matarSessao(int loginId) =>
      '$_baseUrlNew/api/sessoes/$loginId/matar';
  static String get matarTodasAsSessoes =>
      '$_baseUrlNew/api/sessoes/matar-todas';
  static String get matarSessoesOciosas =>
      '$_baseUrlNew/api/sessoes/matar-ociosas';

  static String recoverVerifyEmail(String email) =>
      '$_baseUrl/RecoverVerifyEmail/$email';
  static String recoverVerifyOTP(String email, String otp) =>
      '$_baseUrl/RecoverVerifyOTP/$email/$otp';
  static String recoverResetPassword = '$_baseUrl/RecoverResetPass';

  static String createTask = '$_baseUrl/createTask';
  static String newTaskStatus = '$_baseUrl/listTaskByStatus/New';

  static String completedTaskStatus = '$_baseUrl/listTaskByStatus/Completed';
  static String inProgressTaskStatus = '$_baseUrl/listTaskByStatus/Progress';
  static String cancelledTaskStatus = '$_baseUrl/listTaskByStatus/Canceled';
  static String updateTask(String id, String status) =>
      '$_baseUrl/updateTaskStatus/$id/$status';
  static String taskStatusCount = '$_baseUrl/listTaskByStatus/taskStatusCount';
  static String get statusCounts => '$_baseUrlNew/api/task/status-count';
  static String get baseProdUrl => _baseUrlNew;
  static String deleteTask(String taskId) => '$_baseUrl/deleteTask/$taskId';
  static String allNoticias = '$_baseUrlNew/api/noticias';
  static String get noticiasPublicas =>
      '$_baseUrlNew/api/noticias/public/recentes';
  static String telaAjudaPorTela(String telaNome) =>
      '$_baseUrlNew/api/tela-ajuda/por-tela/${Uri.encodeComponent(telaNome)}';
  static const String _windowsDownloadUrl = String.fromEnvironment(
    'WINDOWS_DOWNLOAD_URL',
    defaultValue: '',
  );
  static String get windowsDownloadUrl => _windowsDownloadUrl.isNotEmpty
      ? _windowsDownloadUrl
      : '$_baseUrlNew/api/downloads/windows';
  static String get createNoticia => '$_baseUrlNew/api/noticias';
  static String updateNoticia(String id) => '$_baseUrlNew/api/noticias/$id';
  static String deleteNoticia(String id) => '$_baseUrlNew/api/noticias/$id';
  static String allCotacoes = '$_baseUrlNew/api/cotacoes';
  static String allVendas = '$_baseUrlNew/api/produtos';
  static String insertNegociacao = '$_baseUrlNew/api/negociacao';
  static String allClassificacao = '$_baseUrlNew/api/classificacoes';
  static String parceiroById = '$_baseUrlNew/api/parceiro/parceiro';
  static String insertProduto = '$_baseUrlNew/api/produtos';
  static String fecthItensAVenda = '$_baseUrlNew/api/produtos/vendedor/';
  static String fecthItensACompra = '$_baseUrlNew/api/produtos/comprador/';
  static String fecthItensANegociar = '$_baseUrlNew/api/produtos/negociacoes/';
  static String insertCotacaoFrete = '$_baseUrlNew/api/cotacaofrete';
  static String allAlerts = '$_baseUrlNew/api/alert';
  static String alertFindByUser = '$_baseUrlNew/api/alert/byUser/';
  static String get alertasManuais => '$_baseUrlNew/api/alert/manual';
  static String get alertasManuaisDisparar =>
      '$_baseUrlNew/api/alert/manual/disparar';
  static String deviceToken = '$_baseUrlNew/api/device-token';
  static String compradorFindByUser = '$_baseUrlNew/api/produtos/comprador/';
  static String vendedorFindByUser = '$_baseUrlNew/api/produtos/vendedor/';
  static String negociacaoFindByUser = '$_baseUrlNew/produtos/negociacoes/';
  static String insertParceiro = '$_baseUrlNew/api/parceiro/insert';
  static String fecthAllCotacaoDollar = '$_baseUrlNew/api/cotacoes/dollar';
  static String confirmarNegociacao = '$_baseUrlNew/api/negociacao/finalizar';
  static String confirmarRecusar = '$_baseUrlNew/api/negociacao/recusar';
  static String contraProposta = '$_baseUrlNew/api/negociacao/contraposta';
  static String downloadContrato = '$_baseUrlNew/api/contrato/download';
  static String upLoadContrato = '$_baseUrlNew/api/contrato/upload';
  static String fecthUltimoTermo = '$_baseUrlNew/api/termos';
  static String fecthProdutosById = '$_baseUrlNew/api/produtos/';
  static String fecthAllPaises = '$_baseUrlNew/api/paises';
  static String fecthEstadoByPais = '$_baseUrlNew/api/estados/by-pais/';
  static String fecthCidadeByEstado = '$_baseUrlNew/api/cidade/by-estado/';
  static String fecthCalcFrete = '$_baseUrlNew/api/rota/calcular';
  static String fecthChats = '$_baseUrlNew/api/chat/user';
  // Fix: backend so tem GET /api/chat/{chatId} (path variable, ver
  // ChatController.findByChatIdByOrderByTimestampDesc), nao um endpoint
  // /messages com query param chatId=. A URL antiga concatenada com o
  // chatId real (ver ChatCaller.fetchChatsById) virava
  // /api/chat/messages?chatId=<uuid-real> -- o Spring casava "messages"
  // (literal) como o path variable {chatId} e IGNORAVA a query string,
  // sempre buscando um chatId inexistente "messages" -> 0 resultados,
  // sempre "Conversa vazia" mesmo com mensagens persistidas no banco
  // (confirmado ao vivo: endpoint correto retorna os dados, esta URL errada
  // retorna sempre {"dados":[],"totalElements":0}).
  static String fecthChatById = '$_baseUrlNew/api/chat/';
  static String getCategorias = '$_baseUrlNew/api/setor';

  // Comunicado
  static String allComunicados = '$_baseUrlNew/api/comunicado';
  static String createComunicado = '$_baseUrlNew/api/comunicado';
  static String updateComunicado(String taskId) =>
      '$_baseUrlNew/api/comunicado/$taskId';
  static String deleteComunicado(String taskId) =>
      '$_baseUrlNew/api/comunicado/$taskId';

  // Alimento
  static String allAlimentos = '$_baseUrlNew/api/alimentos';
  static String createAlimento = '$_baseUrlNew/api/alimentos';
  static String updateAlimento(String id) => '$_baseUrlNew/api/alimentos/$id';
  static String deleteAlimento(String id) => '$_baseUrlNew/api/alimentos/$id';

  // Dieta
  static String allDietas = '$_baseUrlNew/api/dietas';
  static String createDieta = '$_baseUrlNew/api/dietas/insert';
  static String updateDieta(String id) => '$_baseUrlNew/api/dietas/update/$id';
  static String deleteDieta(String id) => '$_baseUrlNew/api/dietas/delete/$id';

  // Empresa
  static String allEmpresas = '$_baseUrlNew/api/empresa';
  static String createEmpresa = '$_baseUrlNew/api/empresa';
  static String updateEmpresa(String id) =>
      '$_baseUrlNew/api/empresa/update/$id'; // controller tem /update/{id}
  static String deleteEmpresa(String id) => '$_baseUrlNew/api/empresa/$id';
  static String empresaById(String id) => '$_baseUrlNew/api/empresa/$id';
  static String smtpConfigEmpresa(int empresaId) =>
      '$_baseUrlNew/api/smtp-config/empresa/$empresaId';
  static String smtpConfigParceiro(int parceiroId) =>
      '$_baseUrlNew/api/smtp-config/parceiro/$parceiroId';
  static String atualizarDadosPessoais(dynamic id) =>
      '$_baseUrlNew/api/dadospessoais/$id';

  // Exame
  static String allExames = '$_baseUrlNew/api/exames';
  static String createExame = '$_baseUrlNew/api/exames';
  static String updateExame(String id) => '$_baseUrlNew/api/exames/$id';
  static String deleteExame(String id) => '$_baseUrlNew/api/exames/$id';

  // Exercicio
  static String allExercicios = '$_baseUrlNew/api/exercicios';
  static String createExercicio = '$_baseUrlNew/api/exercicios';
  static String updateExercicio(String id) => '$_baseUrlNew/api/exercicios/$id';
  static String deleteExercicio(String id) => '$_baseUrlNew/api/exercicios/$id';

  // Grupo Muscular
  static String allGruposMusculares = '$_baseUrlNew/api/grupos-musculares';
  static String createGrupoMuscular = '$_baseUrlNew/api/grupos-musculares';
  static String updateGrupoMuscular(String id) =>
      '$_baseUrlNew/api/grupos-musculares/$id';
  static String deleteGrupoMuscular(String id) =>
      '$_baseUrlNew/api/grupos-musculares/$id';

  // Medicamento
  static String allMedicamentos = '$_baseUrlNew/api/medicamentos';
  static String createMedicamento = '$_baseUrlNew/api/medicamentos/insert';
  static String updateMedicamento(String id) =>
      '$_baseUrlNew/api/medicamentos/update/$id';
  static String deleteMedicamento(String id) =>
      '$_baseUrlNew/api/medicamentos/delete/$id';

  // Mensalidade
  static String allMensalidades = '$_baseUrlNew/api/mensalidades';
  static String createMensalidade = '$_baseUrlNew/api/mensalidades/insert';
  static String updateMensalidade(String id) =>
      '$_baseUrlNew/api/mensalidades/update/$id';
  static String deleteMensalidade(String id) =>
      '$_baseUrlNew/api/mensalidades/delete/$id';
  static String registrarBaixaMensalidade(String id) =>
      '$_baseUrlNew/api/mensalidades/$id/baixa';

  // Modalidade
  static String allModalidades = '$_baseUrlNew/api/modalidades';
  static String createModalidade = '$_baseUrlNew/api/modalidades/insert';
  static String updateModalidade(String id) =>
      '$_baseUrlNew/api/modalidades/update/$id';
  static String deleteModalidade(String id) =>
      '$_baseUrlNew/api/modalidades/delete/$id';

  // Objetivo
  static String allObjetivos = '$_baseUrlNew/api/objetivos';
  static String createObjetivo = '$_baseUrlNew/api/objetivos/insert';
  static String updateObjetivo(String id) =>
      '$_baseUrlNew/api/objetivos/update/$id';
  static String deleteObjetivo(String id) =>
      '$_baseUrlNew/api/objetivos/delete/$id';

  // Parceiro
  static String allParceiros = '$_baseUrlNew/api/parceiro';
  static String createParceiro = '$_baseUrlNew/api/parceiro/insert';
  static String updateParceiro(String id) =>
      '$_baseUrlNew/api/parceiro/update/$id';
  static String deleteParceiro(String id) =>
      '$_baseUrlNew/api/parceiro/delete/$id';

  static String allParceirosPorEmp(String id) =>
      '$_baseUrlNew/api/parceiro/empresa/$id';

  // Fornecedor
  static String allFornecedores = '$_baseUrlNew/api/cadastros/fornecedores';
  static String createFornecedor = '$_baseUrlNew/api/cadastros/fornecedores';
  static String updateFornecedor(String id) =>
      '$_baseUrlNew/api/cadastros/fornecedores/$id';
  static String deleteFornecedor(String id) =>
      '$_baseUrlNew/api/cadastros/fornecedores/$id';

  // Personal
  static String allPersonais =
      '$_baseUrlNew/api/personal'; // controller: /api/personal
  static String createPersonal =
      '$_baseUrlNew/api/personal'; // @PostMapping root
  static String updatePersonal(String id) =>
      '$_baseUrlNew/api/personal/$id'; // @PutMapping("/{id}")
  static String deletePersonal(String id) =>
      '$_baseUrlNew/api/personal/$id'; // @DeleteMapping("/{id}")

  // Plano
  static String allPlanos = '$_baseUrlNew/api/planos';
  static String createPlano = '$_baseUrlNew/api/planos';
  static String updatePlano(String id) => '$_baseUrlNew/api/planos/$id';
  static String deletePlano(String id) => '$_baseUrlNew/api/planos/$id';

  // Role
  static String allRoles = '$_baseUrlNew/api/role';
  static String createRole = '$_baseUrlNew/api/role';
  static String updateRole(String id) => '$_baseUrlNew/api/role/$id';
  static String deleteRole(String id) => '$_baseUrlNew/api/roles/delete/$id';

  // Setor
  static String allSetores = '$_baseUrlNew/api/setor';
  static String createSetor = '$_baseUrlNew/api/setor';
  static String updateSetor(String id) => '$_baseUrlNew/api/setor/update/$id';
  static String deleteSetor(String id) => '$_baseUrlNew/api/setor/delete/$id';

  // Suplemento
  static String allSuplementos = '$_baseUrlNew/api/suplementos';
  static String createSuplemento = '$_baseUrlNew/api/suplementos/insert';
  static String updateSuplemento(String id) =>
      '$_baseUrlNew/api/suplementos/$id';
  static String deleteSuplemento(String id) =>
      '$_baseUrlNew/api/suplementos/$id';

  // Suplemento
  static String allAplicativos = '$_baseUrlNew/api/aplicativos';
  static String createAplicativo = '$_baseUrlNew/api/aplicativos';
  static String updateAplicativo(String id) =>
      '$_baseUrlNew/api/aplicativos/update/$id';
  static String deleteAplicativo(String id) =>
      '$_baseUrlNew/api/aplicativos/delete/$id';

  // Regime
  static String allRegimetributario = '$_baseUrlNew/api/regimetributario';
  static String createRegimetributario = '$_baseUrlNew/api/regimetributario';
  static String updateRegimetributario(String id) =>
      '$_baseUrlNew/api/regimetributario/update/$id';
  static String deleteRegimetributario(String id) =>
      '$_baseUrlNew/api/regimetributario/delete/$id';

  // Add these endpoints to your ApiLinks class
  static String get allLogins => '$_baseUrlNew/api/logins';
  static String get createLogin => '$_baseUrlNew/api/logins';
  static String updateLogin(String id) => '$_baseUrlNew/api/logins/$id';
  static String deleteLogin(String id) => '$_baseUrlNew/api/logins/$id';
  static String get allTipoParceiros => '$_baseUrlNew/api/tipo_parceiro';

  // Importacao CSV
  static String get importacaoContaPagar =>
      '$_baseUrlNew/api/importacao/conta-pagar';
  static String get importacaoContaReceber =>
      '$_baseUrlNew/api/importacao/conta-receber';
  static String get importacaoBoletos => '$_baseUrlNew/api/importacao/boletos';
  static String get importacaoPreview => '$_baseUrlNew/api/importacao/preview';

  // Contas a Pagar
  static String get allContasPagar => '$_baseUrlNew/api/conta_pagar';
  static String get createContaPagar => '$_baseUrlNew/api/conta_pagar';
  static String updateContaPagar(String id) =>
      '$_baseUrlNew/api/conta_pagar/$id';
  static String deleteContaPagar(String id) =>
      '$_baseUrlNew/api/conta_pagar/$id';
  static String registrarBaixaContaPagar(String id) =>
      '$_baseUrlNew/api/conta_pagar/$id/baixa';
  static String desfazerContaPagar(String id) =>
      '$_baseUrlNew/api/conta_pagar/desfazer/$id';
  static String contaPagarRecorrencia(String id) =>
      '$_baseUrlNew/api/conta_pagar/$id/recorrencia';
  static String contaPagarParcelar(String id) =>
      '$_baseUrlNew/api/conta_pagar/$id/parcelar';
  static String contaPagarRenegociar(String id) =>
      '$_baseUrlNew/api/conta_pagar/$id/renegociar';
  static String contaPagarBaixaParcial(String id) =>
      '$_baseUrlNew/api/conta_pagar/$id/baixa-parcial';
  static String contaPagarHistorico(String id) =>
      '$_baseUrlNew/api/conta_pagar/$id/historico';

  // Baixa em Lote
  static String get baixaLotePagar => '$_baseUrlNew/api/conta_pagar/baixa-lote';
  static String get baixaLoteReceber =>
      '$_baseUrlNew/api/conta_receber/baixa-lote';

  // Contas a Receber
  static String get allContasReceber => '$_baseUrlNew/api/conta_receber';
  static String get createContaReceber => '$_baseUrlNew/api/conta_receber';
  static String updateContaReceber(String id) =>
      '$_baseUrlNew/api/conta_receber/$id';
  static String deleteContaReceber(String id) =>
      '$_baseUrlNew/api/conta_receber/$id';
  static String registrarBaixaContaReceber(String id) =>
      '$_baseUrlNew/api/conta_receber/$id/baixa';
  static String desfazerContaReceber(String id) =>
      '$_baseUrlNew/api/conta_receber/desfazer/$id';
  static String contaReceberRecorrencia(String id) =>
      '$_baseUrlNew/api/conta_receber/$id/recorrencia';
  static String contaReceberParcelar(String id) =>
      '$_baseUrlNew/api/conta_receber/$id/parcelar';
  static String contaReceberRenegociar(String id) =>
      '$_baseUrlNew/api/conta_receber/$id/renegociar';
  static String contaReceberBaixaParcial(String id) =>
      '$_baseUrlNew/api/conta_receber/$id/baixa-parcial';
  static String contaReceberHistorico(String id) =>
      '$_baseUrlNew/api/conta_receber/$id/historico';

  // Contas BancÃ¡rias
  static final String contasBancarias = '$_baseUrlNew/api/contas-bancaria';
  static final String allContasBancarias = '$_baseUrlNew/api/contas/saldos';
  static final String createContaBancaria = contasBancarias;
  static String updateContaBancaria(String id) => '$contasBancarias/$id';
  static String deleteContaBancaria(String id) => '$contasBancarias/$id';

  // Defaults financeiros por empresa (importacao SINTEGRA/SPED) — card E2l56E5h
  static String defaultsImportacao(String empresaId) =>
      '$_baseUrlNew/api/defaults-importacao/$empresaId';

  // Ponto
  static String pontoRegistrar = '$_baseUrlNew/api/pontos/registrar';
  static String pontoListar = '$_baseUrlNew/api/pontos/listar';
  static String pontoPdf = '$_baseUrlNew/api/pontos/pdf';
  static String pontoBancoHoras = '$_baseUrlNew/api/pontos/banco-horas';

  // PaÃ­ses / Estados / Cidades
  static final String buscarPaises = '$_baseUrlNew/api/pais';
  static String buscarEstados(String paisId) =>
      '$_baseUrlNew/api/estado/pais/$paisId';
  static String buscarCidades(String estadoId) =>
      '$_baseUrlNew/api/cidade/estado/$estadoId';

  // Chamados
  static String get allChamados => '$_baseUrlNew/api/chamados';
  static String get createChamado => '$_baseUrlNew/api/chamados';
  static String updateChamado(String id) => '$_baseUrlNew/api/chamados/$id';
  static String deleteChamado(String id) => '$_baseUrlNew/api/chamados/$id';
  static String updateStatusChamado(String id) =>
      '$_baseUrlNew/api/chamados/$id/status';

  // Formas de Pagamento
  static String get allFormasPagamento => '$_baseUrlNew/api/forma_pagamento';
  static String get createFormaPagamento => '$_baseUrlNew/api/forma_pagamento';
  static String updateFormaPagamento(String id) =>
      '$_baseUrlNew/api/forma_pagamento/$id';
  static String deleteFormaPagamento(String id) =>
      '$_baseUrlNew/api/forma_pagamento/$id';
  static String formasPagamentoByEmpresa(String empresaId) =>
      '$_baseUrlNew/api/forma_pagamento/empresa/$empresaId';

  // CobranÃ§as de contas a receber
  static String contaReceberCobrancas(String contaReceberId) =>
      '$_baseUrlNew/api/conta_receber/$contaReceberId/cobrancas';
  static String contaReceberCobranca(String cobrancaId) =>
      '$_baseUrlNew/api/conta_receber/cobrancas/$cobrancaId';
  static String contaReceberCobrancaById(String cobrancaId) =>
      contaReceberCobranca(cobrancaId);
  static String reprocessarContaReceberCobranca(String cobrancaId) =>
      '$_baseUrlNew/api/conta_receber/cobrancas/$cobrancaId/reprocessar';
  static String cancelarContaReceberCobranca(String cobrancaId) =>
      '$_baseUrlNew/api/conta_receber/cobrancas/$cobrancaId/cancelar';
  static String get contaReceberCobrancasReguaPendentes =>
      '$_baseUrlNew/api/conta_receber/cobrancas/regua/pendentes';
  static String marcarEnvioReguaContaReceberCobranca(String cobrancaId) =>
      '$_baseUrlNew/api/conta_receber/cobrancas/$cobrancaId/regua/marcar-envio';

  // Cobrança (inadimplência e régua)
  static String get cobrancaVencidos => '$_baseUrlNew/api/cobranca/vencidos';
  static String get cobrancaExecutarRegua =>
      '$_baseUrlNew/api/cobranca/executar-regua';
  static String get cobrancaAcoes => '$_baseUrlNew/api/cobranca/acoes';
  static String cobrancaAcoesCliente(int clienteId) =>
      '$_baseUrlNew/api/cobranca/clientes/$clienteId/acoes';
  static String get cobrancaRegras => '$_baseUrlNew/api/cobranca/regras';
  static String cobrancaRegra(String id) =>
      '$_baseUrlNew/api/cobranca/regras/$id';

  // Banking / CobranÃ§as legadas
  static String get bankingImport => '$_baseUrlNew/api/banking/import';
  static String get bankingImports => '$_baseUrlNew/api/banking/imports';
  static String bankingReconcile({
    required String importId,
    required String ruleName,
    String textSearch = '',
    double tolerance = 0.01,
  }) =>
      '$_baseUrlNew/api/banking/reconcile?importId=${Uri.encodeComponent(importId)}&ruleName=${Uri.encodeComponent(ruleName)}&textSearch=${Uri.encodeComponent(textSearch)}&tolerance=$tolerance';
  static String get bankingBilling => '$_baseUrlNew/api/banking/billing';

  // DiretÃ³rios
  static String get allDiretorios => '$_baseUrlNew/api/diretorios';
  static String get createDiretorio => '$_baseUrlNew/api/diretorios';
  static String updateDiretorio(String id) => '$_baseUrlNew/api/diretorios/$id';
  static String deleteDiretorio(String id) => '$_baseUrlNew/api/diretorios/$id';

  // Arquivos / GED
  static String get allArquivos => '$_baseUrlNew/api/arquivos';
  static String get createArquivo => '$_baseUrlNew/api/arquivos';
  static String updateArquivo(String id) => '$_baseUrlNew/api/arquivos/$id';
  static String deleteArquivo(String id) => '$_baseUrlNew/api/arquivos/$id';
  static String get uploadArquivo => '$_baseUrlNew/api/arquivos/upload';
  static String downloadArquivo(String id) =>
      '$_baseUrlNew/api/arquivos/download/$id';
  static String arquivosPorDiretorio(String diretorioId) =>
      '$_baseUrlNew/api/arquivos/diretorio/$diretorioId';

  /// Lista arquivos filtrando por empresa (obrigatÃ³rio), parceiro (opcional),
  /// mÃ³dulo de origem (ex: 'funcionario', 'produto', 'parceiro', 'alvara') e
  /// idOrigem (opcional) para o filtro automÃ¡tico do H5 (idShort 21).
  static String arquivosPorEmpresa(int empresaId,
      {int? parceiroId, String? modulo, int? idOrigem}) {
    final params = <String, String>{'empresaId': empresaId.toString()};
    if (parceiroId != null) params['parceiroId'] = parceiroId.toString();
    if (modulo != null) params['modulo'] = modulo;
    if (idOrigem != null) params['idOrigem'] = idOrigem.toString();
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$_baseUrlNew/api/arquivos?$query';
  }

  static String get fecthAllDocumentos => '$_baseUrlNew/api/documentos';

  static String get fecthAllAlerts => '$_baseUrlNew/api/alert';

  static String get fecthAUpload => '$_baseUrlNew/api/files/upload';

  // Arquivos
  static String get allObrigacaoFiscal => '$_baseUrlNew/api/obrigacoes-fiscais';
  static String get createObrigacaoFiscal =>
      '$_baseUrlNew/api/obrigacoes-fiscais';
  static String updateObrigacaoFiscal(String id) =>
      '$_baseUrlNew/api/obrigacoes-fiscais/$id';
  static String deleteObrigacaoFiscal(String id) =>
      '$_baseUrlNew/api/obrigacoes-fiscais/$id';
  static String enviarObrigacaoFiscal(String id) =>
      '$_baseUrlNew/api/obrigacoes-fiscais/$id/enviar';
  static String atualizarStatusEnvioObrigacaoFiscal(String id) =>
      '$_baseUrlNew/api/obrigacoes-fiscais/$id/status-envio';
  static String get lembretesPendentesObrigacaoFiscal =>
      '$_baseUrlNew/api/obrigacoes-fiscais/lembretes/pendentes';

  static String chatStart(String id, String setor) =>
      '$_chatId/ws-chat?user=$id&sector=$setor';

  static String chatStartfetch(String id) => '$_baseUrlNew/api/chat/$id';

  static String downloadFile(dynamic id) =>
      '$_baseUrlNew/api/files/download/$id';

  static String getFile(dynamic id) => '$_baseUrlNew/api/files/$id';

  static String get uploadFile => '$_baseUrlNew/api/files/upload';

  static String chatFinalize(dynamic id) => '$_baseUrlNew/api/chat/$id';
  static String chatDelete(dynamic id) => '$_baseUrlNew/api/chat/$id';
  // Fix card #430: finaliza a conversa inteira por chatId (String), distinto
  // de chatFinalize acima (que atualiza uma ChatMessage especifica por id
  // Integer, usado pelo Kanban).
  static String chatFinalizarConversa(String chatId,
      {String? satisfacao, int? nota}) {
    final base = '$_baseUrlNew/api/chat/finalizar/$chatId';
    if (satisfacao == null || nota == null) return base;
    return '$base?satisfacao=${Uri.encodeComponent(satisfacao)}&nota=$nota';
  }

  // Chat Kanban
  static String get chatKanban => '$_baseUrlNew/api/chat/kanban';
  static String chatTransfer(dynamic id) =>
      '$_baseUrlNew/api/chat/$id/transferir';
  static String chatMarkAsRead(dynamic id) => '$_baseUrlNew/api/chat/$id/ler';
  static String get chatUsuariosSetor => '$_baseUrlNew/api/chat/usuarios-setor';
  // Card #448 Fase 1: funcionario "pega" atendimento aguardando no setor.
  static String chatPickup(String chatId, int usuarioId) =>
      '$_baseUrlNew/api/chat/$chatId/pickup?usuarioId=$usuarioId';
  // Bug de producao: upload de anexo no Chat usava o endpoint generico
  // /api/files/upload, que exige @PreAuthorize("hasAnyRole('ROLE_EDITOR',
  // 'ROLE_CONTABILIDADE')") -- authorities dadas so' pra MASTER/Contabilidade
  // (LoginServiceImpl.loadUserByUsername), NUNCA pra Cliente. Cliente
  // anexando arquivo na PROPRIA conversa de chat sempre levava 403. O
  // backend ja tinha um endpoint dedicado sem essa restricao (card #429,
  // ChatController.uploadFileToChat) -- so nunca foi usado pelo app.
  static String chatUpload(String chatId) =>
      '$_baseUrlNew/api/chat/$chatId/upload';

  static String getAllTelas(String nome, {int? empId, int? clienteId}) {
    final params = <String, String>{};
    if (empId != null) params['empId'] = empId.toString();
    if (clienteId != null) params['clienteId'] = clienteId.toString();
    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';
    return '$_baseUrlNew/api/telas/$nome$query';
  }

  static String getAllpreferencias(String id, String setor) =>
      ('$_baseUrlNew/api/$id/user-preferences/$setor');

  // Caso seu backend tambÃ©m sirva link pÃºblico direto:
  static String publicFileUrl(int fileId) =>
      '$_baseUrlNew/files/public/$fileId';

  static String atualizarUsuario(int fileId) =>
      '$_baseUrlNew/api/parceiro/atualizar/$fileId';

  static String updateArquivoLido(int fileId) =>
      '$_baseUrlNew/api/parceiro/atualizar/$fileId';

  static String get getFinance => '$_baseUrlNew/api/dashboard/finance/series';
  static String get chatDaily => '$_baseUrlNew/api/dashboard/chats/daily';

  static String get chatDailys => '$_baseUrlNew/api/dashboard/chats/dailys';

  static String get quarterlyComparison =>
      '$_baseUrlNew/api/dashboard/finance/quarterlyComparison';

  static String get overdue =>
      '$_baseUrlNew/api/dashboard/finance/alerts/overdue';

  static String get dueSoon =>
      '$_baseUrlNew/api/dashboard/finance/alerts/dueSoon';

  static String get kpis => '$_baseUrlNew/api/dashboard/kpis';
  static String get portalClienteResumo =>
      '$_baseUrlNew/api/portal-cliente/resumo';
  static String get marketOverview => '$_baseUrlNew/api/cotacoes/mercado';
  static String get marketCollectorOverview =>
      '$_baseUrlNew/api/market/overview';
  static String get marketCollectorSnapshots => '$_baseUrlNew/api/market-data';
  static List<String> get marketOverviewCandidates => [
        marketCollectorOverview,
        marketCollectorSnapshots,
        marketOverview,
      ];

  // Jobs Monitor
  static String get allJobs => '$_baseUrlNew/api/admin/jobs';

  // Tipo Parceiro
  static String get allTipoParceiro => '$_baseUrlNew/api/tipo-parceiro';
  static String get createTipoParceiro => '$_baseUrlNew/api/tipo-parceiro';
  static String updateTipoParceiro(String id) =>
      '$_baseUrlNew/api/tipo-parceiro/$id';
  static String deleteTipoParceiro(String id) =>
      '$_baseUrlNew/api/tipo-parceiro/$id';

  // Servico Contratado
  static String get allServicoContratado =>
      '$_baseUrlNew/api/servico-contratado';
  static String get createServicoContratado =>
      '$_baseUrlNew/api/servico-contratado';
  static String updateServicoContratado(String id) =>
      '$_baseUrlNew/api/servico-contratado/$id';
  static String deleteServicoContratado(String id) =>
      '$_baseUrlNew/api/servico-contratado/$id';

  // Modulo Servico
  static String get allModuloServico => '$_baseUrlNew/api/modulo-servico';
  static String get createModuloServico => '$_baseUrlNew/api/modulo-servico';
  static String updateModuloServico(String id) =>
      '$_baseUrlNew/api/modulo-servico/$id';
  static String deleteModuloServico(String id) =>
      '$_baseUrlNew/api/modulo-servico/$id';
  static String jobHistorico(String nome) =>
      '$_baseUrlNew/api/admin/jobs/$nome/historico';
  static String jobExecutar(String nome) =>
      '$_baseUrlNew/api/admin/jobs/$nome/executar';

  static String get clientDistribution =>
      '$_baseUrlNew/api/dashboard/finance/clientDistribution';

  static String get trend => '$_baseUrlNew/api/dashboard/finance/trend';

  static String get ticketsTrend => '$_baseUrlNew/api/dashboard/tickets/trend';

  static String get financeFluxoDiario =>
      '$_baseUrlNew/api/dashboard/finance/fluxo-diario';

  static String get financeFluxoDiarioSaldo =>
      '$_baseUrlNew/api/contas-bancaria/saldos';

  static String financeFluxoEvolucao(int fileId) =>
      '$_baseUrlNew/api/contas-bancaria/$fileId/evolucao';

  static String get financeFluxoDiarioPdf =>
      '$_baseUrlNew/api/contas-bancaria/extrato/pdf';

  static String get financeExtratoOperacional =>
      '$_baseUrlNew/api/dashboard/finance/extrato-operacional';

  static String get baseUrl => _baseUrlNew;
  static String get limparBasePreservarEmpresas =>
      '$_baseUrlNew/api/admin/limpar-base-preservar-empresas';

  /// Proxia imagens externas (ex.: CDN do Instagram) pelo backend para
  /// contornar o bloqueio de CORS no Flutter Web. Devolve a url original
  /// se ela estiver vazia ou ja apontar para o proprio proxy.
  static String imageProxy(String url) {
    if (url.isEmpty || url.contains('/api/image-proxy')) return url;
    return '$_baseUrlNew/api/image-proxy?url=${Uri.encodeComponent(url)}';
  }

  // Certificado Digital
  static String certificadosByEmpresa(int empresaId) =>
      '$_baseUrlNew/api/certificados?empresaId=$empresaId';
  static String get uploadCertificado => '$_baseUrlNew/api/certificados/upload';
  static String deleteCertificado(int id) =>
      '$_baseUrlNew/api/certificados/$id';
  static String get alertasCertificados =>
      '$_baseUrlNew/api/certificados/alertas';

  static String getRolesLoginId(int loginId) =>
      '$_baseUrlNew/api/login/$loginId/roles';
  static String updateRolesLoginId(int loginId) =>
      '$_baseUrlNew/api/login/$loginId/roles';
  static String getAllRoles =
      '$_baseUrlNew/api/role?size=1000'; // Aumentamos o size para pegar todas as roles

  /// GET /api/role/disponiveis — roles filtradas por módulos contratados
  static String get rolesDisponiveis => '$_baseUrlNew/api/role/disponiveis';

  static String associateRoleToLogin(int loginId, int roleId) {
    return '$_baseUrlNew/api/login/$loginId/roles/$roleId';
  }

  static String removeRoleFromLogin(int loginId, int roleId) {
    return '$_baseUrlNew/api/login/$loginId/roles/$roleId';
  }

  // Setores de um login (roteamento de alertas)
  static String getSetoresLoginId(int loginId) =>
      '$_baseUrlNew/api/login/$loginId/setores';

  static String associateSetorToLogin(int loginId, int setorId) =>
      '$_baseUrlNew/api/login/$loginId/setores/$setorId';

  static String removeSetorFromLogin(int loginId, int setorId) =>
      '$_baseUrlNew/api/login/$loginId/setores/$setorId';

  static String updateSetoresLoginId(int loginId) =>
      '$_baseUrlNew/api/login/$loginId/setores';

  static String fecharChamados(String id) => "$_baseUrlNew/chamados/$id/fechar";

  static String chatByEmpesaId(String id) => '$_baseUrlNew/api/chat/chat/$id';

  static String clienteByEmpresaId(String id) =>
      '$_baseUrlNew/api/parceiro/parceiro/$id';

  static String chamadoByEmpresaId(String id) =>
      '$_baseUrlNew/api/chamados/chamado/$id';

  static final String workflowChamados = '$_baseUrlNew/api/workflow/chamados';

  static String getAllChamados(String id) =>
      '$_baseUrlNew/api/workflow/chamados/$id/historico';

  // Ticket
  static String get allTickets => '$_baseUrlNew/api/ticket';
  static String get createTicket => '$_baseUrlNew/api/ticket';
  static String updateTicket(String id) => '$_baseUrlNew/api/ticket/$id';
  static String deleteTicket(String id) => '$_baseUrlNew/api/ticket/$id';

  // Order
  static String get allOrders => '$_baseUrlNew/api/order';
  static String get createOrder => '$_baseUrlNew/api/order';
  static String updateOrder(String id) => '$_baseUrlNew/api/order/$id';
  static String deleteOrder(String id) => '$_baseUrlNew/api/order/$id';

  // Dividendo
  static String get allDividendos => '$_baseUrlNew/api/dividendos';
  static String get createDividendo => '$_baseUrlNew/api/dividendos';
  static String updateDividendo(String id) => '$_baseUrlNew/api/dividendos/$id';
  static String deleteDividendo(String id) => '$_baseUrlNew/api/dividendos/$id';

  // CotaÃ§Ã£o Frete
  static String get allCotacoesFrete => '$_baseUrlNew/api/cotacaofrete';
  static String get createCotacaoFrete => '$_baseUrlNew/api/cotacaofrete';
  static String updateCotacaoFrete(String id) =>
      '$_baseUrlNew/api/cotacaofrete/$id';
  static String deleteCotacaoFrete(String id) =>
      '$_baseUrlNew/api/cotacaofrete/$id';

  // Pedido
  static String get allPedidos => '$_baseUrlNew/api/pedidos';
  static String get createPedido => '$_baseUrlNew/api/pedidos';
  static String updatePedido(String id) => '$_baseUrlNew/api/pedidos/$id';
  static String deletePedido(String id) => '$_baseUrlNew/api/pedidos/$id';

  // CalendÃ¡rio Guias
  static String get allCalendariosGuias => '$_baseUrlNew/api/calendarios-guias';
  static String get createCalendarioGuias =>
      '$_baseUrlNew/api/calendarios-guias';
  static String updateCalendarioGuias(String id) =>
      '$_baseUrlNew/api/calendarios-guias/$id';
  static String deleteCalendarioGuias(String id) =>
      '$_baseUrlNew/api/calendarios-guias/$id';
  static String get calendarioFinanceiro =>
      '$_baseUrlNew/api/calendario-financeiro';

  // Cargo
  static String get allCargos => '$_baseUrlNew/api/cargo';
  static String get createCargo => '$_baseUrlNew/api/cargo';
  static String updateCargo(String id) => '$_baseUrlNew/api/cargo/$id';
  static String deleteCargo(String id) => '$_baseUrlNew/api/cargo/$id';

  // Centro de Custo
  static String get allCentrosCusto => '$_baseUrlNew/api/centro-custo';
  static String get createCentroCusto => '$_baseUrlNew/api/centro-custo';
  static String updateCentroCusto(String id) =>
      '$_baseUrlNew/api/centro-custo/$id';
  static String deleteCentroCusto(String id) =>
      '$_baseUrlNew/api/centro-custo/$id';

  // Categoria Financeira
  static String get allCategoriasFinanceiras =>
      '$_baseUrlNew/api/categoria-financeira';
  static String get createCategoriaFinanceira =>
      '$_baseUrlNew/api/categoria-financeira';
  static String updateCategoriaFinanceira(String id) =>
      '$_baseUrlNew/api/categoria-financeira/$id';
  static String deleteCategoriaFinanceira(String id) =>
      '$_baseUrlNew/api/categoria-financeira/$id';

  // Departamento
  static String get allDepartamentos => '$_baseUrlNew/api/departamento';
  static String get createDepartamento => '$_baseUrlNew/api/departamento';
  static String updateDepartamento(String id) =>
      '$_baseUrlNew/api/departamento/$id';
  static String deleteDepartamento(String id) =>
      '$_baseUrlNew/api/departamento/$id';

  // Feriado
  static String get allFeriados => '$_baseUrlNew/api/feriado';
  static String get createFeriado => '$_baseUrlNew/api/feriado';
  static String updateFeriado(String id) => '$_baseUrlNew/api/feriado/$id';
  static String deleteFeriado(String id) => '$_baseUrlNew/api/feriado/$id';

  // Orçamento Comercial
  static final String orcamentos = '$_baseUrlNew/api/comercial/orcamentos';
  static String orcamentoById(String id) =>
      '$_baseUrlNew/api/comercial/orcamentos/$id';
  static String aprovarOrcamento(String id) =>
      '$_baseUrlNew/api/comercial/orcamentos/$id/aprovar';
  static String reprovarOrcamento(String id) =>
      '$_baseUrlNew/api/comercial/orcamentos/$id/reprovar';
  static String converterOrcamento(String id) =>
      '$_baseUrlNew/api/comercial/orcamentos/$id/converter';
  static String novaVersaoOrcamento(String id) =>
      '$_baseUrlNew/api/comercial/orcamentos/$id/nova-versao';
  static String cancelarOrcamento(String id) =>
      '$_baseUrlNew/api/comercial/orcamentos/$id/cancelar';

  // Pedido de Venda
  static final String pedidosVenda = '$_baseUrlNew/api/comercial/pedidos-venda';
  static String pedidoVendaById(String id) =>
      '$_baseUrlNew/api/comercial/pedidos-venda/$id';
  static String aprovarPedidoVenda(String id) =>
      '$_baseUrlNew/api/comercial/pedidos-venda/$id/aprovar';
  static String rejeitarPedidoVenda(String id) =>
      '$_baseUrlNew/api/comercial/pedidos-venda/$id/rejeitar';
  static String faturarParcialPedidoVenda(String id) =>
      '$_baseUrlNew/api/comercial/pedidos-venda/$id/faturar-parcial';
  static String faturarTotalPedidoVenda(String id) =>
      '$_baseUrlNew/api/comercial/pedidos-venda/$id/faturar-total';
  static String cancelarPedidoVenda(String id) =>
      '$_baseUrlNew/api/comercial/pedidos-venda/$id/cancelar';
  static String criarPedidoVendaDeOrcamento(String orcamentoId) =>
      '$_baseUrlNew/api/comercial/pedidos-venda/criar-de-orcamento/$orcamentoId';
  static String pedidoVendaItens(int id) =>
      '$_baseUrlNew/api/comercial/pedidos-venda/$id/itens';
  static String pedidoVendaHistorico(int id) =>
      '$_baseUrlNew/api/comercial/pedidos-venda/$id/historico';

  // Pedido de Compra
  static final String pedidosCompra = '$_baseUrlNew/api/compras/pedidos';
  static String pedidoCompraById(String id) =>
      '$_baseUrlNew/api/compras/pedidos/$id';
  static String emitirPedidoCompra(String id) =>
      '$_baseUrlNew/api/compras/pedidos/$id/emitir';
  static String aprovarPedidoCompra(String id) =>
      '$_baseUrlNew/api/compras/pedidos/$id/aprovar';
  static String receberParcialPedidoCompra(String id) =>
      '$_baseUrlNew/api/compras/pedidos/$id/receber-parcial';
  static String receberTotalPedidoCompra(String id) =>
      '$_baseUrlNew/api/compras/pedidos/$id/receber-total';
  static String cancelarPedidoCompra(String id) =>
      '$_baseUrlNew/api/compras/pedidos/$id/cancelar';

  // Aprovação de Compras
  static final String aprovacaoCompraFila =
      '$_baseUrlNew/api/compras/aprovacao/fila';
  static String aprovacaoCompraSolicitar(dynamic pedidoCompraId) =>
      '$_baseUrlNew/api/compras/aprovacao/$pedidoCompraId/solicitar';
  static String aprovacaoCompraAprovar(dynamic aprovacaoId) =>
      '$_baseUrlNew/api/compras/aprovacao/$aprovacaoId/aprovar';
  static String aprovacaoCompraReprovar(dynamic aprovacaoId) =>
      '$_baseUrlNew/api/compras/aprovacao/$aprovacaoId/reprovar';
  static String aprovacaoCompraPedido(dynamic pedidoCompraId) =>
      '$_baseUrlNew/api/compras/aprovacao/pedido/$pedidoCompraId';

  // Tabela de Preços e Descontos
  static final String tabelasPreco = '$_baseUrlNew/api/comercial/tabelas-preco';
  static String tabelaPrecoById(String id) =>
      '$_baseUrlNew/api/comercial/tabelas-preco/$id';
  static String itensTabelaPreco(String tabelaId) =>
      '$_baseUrlNew/api/comercial/tabelas-preco/$tabelaId/itens';
  static String salvarItemTabelaPreco(String tabelaId) =>
      '$_baseUrlNew/api/comercial/tabelas-preco/$tabelaId/itens';
  static String deletarItemTabelaPreco(String tabelaId, String itemId) =>
      '$_baseUrlNew/api/comercial/tabelas-preco/$tabelaId/itens/$itemId';
  static final String descontos = '$_baseUrlNew/api/comercial/descontos';
  static String descontoById(String id) =>
      '$_baseUrlNew/api/comercial/descontos/$id';

  // Devolução Comercial
  static final String devolucoes = '$_baseUrlNew/api/comercial/devolucoes';
  static String devolucaoById(String id) =>
      '$_baseUrlNew/api/comercial/devolucoes/$id';
  static String devolucaoConcluir(String id) =>
      '$_baseUrlNew/api/comercial/devolucoes/$id/concluir';

  // Reserva de Estoque
  static String reservasPorPedido(int pedidoId) =>
      '$_baseUrlNew/api/estoque/reservas/pedido/$pedidoId';
  static String disponivelProduto(int produtoId) =>
      '$_baseUrlNew/api/estoque/reservas/produto/$produtoId/disponivel';
  static String reservarEstoque(int pedidoId) =>
      '$_baseUrlNew/api/estoque/reservas/pedido/$pedidoId/reservar';
  static String liberarEstoque(int pedidoId) =>
      '$_baseUrlNew/api/estoque/reservas/pedido/$pedidoId/liberar';

  // Multi-depósito e localização
  static final String depositos = '$_baseUrlNew/api/estoque/depositos';
  static String depositoPorId(int id) =>
      '$_baseUrlNew/api/estoque/depositos/$id';
  static String localizacoesPorDeposito(int depositoId) =>
      '$_baseUrlNew/api/estoque/depositos/$depositoId/localizacoes';
  static String criarLocalizacao(int depositoId) =>
      '$_baseUrlNew/api/estoque/depositos/$depositoId/localizacoes';
  static String saldoPorProduto(int produtoId) =>
      '$_baseUrlNew/api/estoque/depositos/saldo?produtoId=$produtoId';
  static final String transferirDeposito =
      '$_baseUrlNew/api/estoque/depositos/transferir';
  static final String ajustarEstoque =
      '$_baseUrlNew/api/estoque/depositos/ajustar';

  // Alerta Aluno
  static String get allAlertasAluno => '$_baseUrlNew/api/alertas-aluno';

  // FuncionÃ¡rio
  static String get allFuncionarios => '$_baseUrlNew/api/funcionario';
  static String get createFuncionario => '$_baseUrlNew/api/funcionario';
  static String updateFuncionario(String id) =>
      '$_baseUrlNew/api/funcionario/$id';
  static String deleteFuncionario(String id) =>
      '$_baseUrlNew/api/funcionario/$id';
  static String registrarPontoFuncionario(String id) =>
      '$_baseUrlNew/api/funcionario/$id/ponto';
  static String pontosFuncionario(String id) =>
      '$_baseUrlNew/api/funcionario/$id/pontos';
  static String acertoPontoFuncionario(String id) =>
      '$_baseUrlNew/api/funcionario/$id/acerto-ponto';
  static String pdfPontoFuncionario(String id) =>
      '$_baseUrlNew/api/funcionario/$id/ponto/pdf';
  static String get createAlertaAluno => '$_baseUrlNew/api/alertas-aluno';
  static String updateAlertaAluno(String id) =>
      '$_baseUrlNew/api/alertas-aluno/$id';
  static String deleteAlertaAluno(String id) =>
      '$_baseUrlNew/api/alertas-aluno/$id';

  // AvaliaÃ§Ã£o FÃ­sica
  static String get allAvaliacoesFisicas =>
      '$_baseUrlNew/api/avaliacoes-fisicas';
  static String get createAvaliacaoFisica =>
      '$_baseUrlNew/api/avaliacoes-fisicas';
  static String updateAvaliacaoFisica(String id) =>
      '$_baseUrlNew/api/avaliacoes-fisicas/$id';
  static String deleteAvaliacaoFisica(String id) =>
      '$_baseUrlNew/api/avaliacoes-fisicas/$id';

  // ClassificaÃ§Ã£o
  static String get allClassificacoes => '$_baseUrlNew/api/classificacoes';
  static String get createClassificacao => '$_baseUrlNew/api/classificacoes';
  static String updateClassificacao(String id) =>
      '$_baseUrlNew/api/classificacoes/$id';
  static String deleteClassificacao(String id) =>
      '$_baseUrlNew/api/classificacoes/$id';

  // Treino
  static String get allTreinos => '$_baseUrlNew/api/treinos';
  static String get createTreino => '$_baseUrlNew/api/treinos';
  static String updateTreino(String id) => '$_baseUrlNew/api/treinos/$id';
  static String deleteTreino(String id) => '$_baseUrlNew/api/treinos/$id';

  // Hidratacao
  static String get hidratacaoResumo => '$_baseUrlNew/api/hidratacao/resumo';
  static String get hidratacaoRegistros =>
      '$_baseUrlNew/api/hidratacao/registros';
  static String hidratacaoRegistro(int id) =>
      '$_baseUrlNew/api/hidratacao/registros/$id';
  static String get hidratacaoMeta => '$_baseUrlNew/api/hidratacao/meta';
  static String get hidratacaoHistorico =>
      '$_baseUrlNew/api/hidratacao/historico';

  // Diario nutricional
  static String diarioNutricionalResumo(String data) =>
      '$_baseUrlNew/api/diario-nutricional/resumo?data=$data';
  static String get diarioNutricionalRefeicoes =>
      '$_baseUrlNew/api/diario-nutricional/refeicoes';
  static String get diarioNutricionalItens =>
      '$_baseUrlNew/api/diario-nutricional/itens';
  static String diarioNutricionalItem(int id) =>
      '$_baseUrlNew/api/diario-nutricional/itens/$id';

  // Nota Fiscal Entrada
  static String get allNotasFiscaisEntrada =>
      '$_baseUrlNew/api/notas-fiscais-entrada';
  static String get createNotaFiscalEntrada =>
      '$_baseUrlNew/api/notas-fiscais-entrada';
  static String updateNotaFiscalEntrada(String id) =>
      '$_baseUrlNew/api/notas-fiscais-entrada/$id';
  static String deleteNotaFiscalEntrada(String id) =>
      '$_baseUrlNew/api/notas-fiscais-entrada/$id';

  // Nota Fiscal SaÃ­da
  static String get allNotasFiscaisSaida =>
      '$_baseUrlNew/api/notas-fiscais-saida';
  static String get createNotaFiscalSaida =>
      '$_baseUrlNew/api/notas-fiscais-saida';
  static String updateNotaFiscalSaida(String id) =>
      '$_baseUrlNew/api/notas-fiscais-saida/$id';
  static String deleteNotaFiscalSaida(String id) =>
      '$_baseUrlNew/api/notas-fiscais-saida/$id';

  // HorÃ¡rio FuncionÃ¡rio
  static String get allHorariosFunc => '$_baseUrlNew/api/horarioFunc';
  static String get createHorarioFunc => '$_baseUrlNew/api/horarioFunc';
  static String updateHorarioFunc(String id) =>
      '$_baseUrlNew/api/horarioFunc/$id';
  static String deleteHorarioFunc(String id) =>
      '$_baseUrlNew/api/horarioFunc/$id';

  // Tipo Produto
  static String get allTiposProduto => '$_baseUrlNew/api/tipoProdutos';
  static String get createTipoProduto => '$_baseUrlNew/api/tipoProdutos';
  static String updateTipoProduto(String id) =>
      '$_baseUrlNew/api/tipoProdutos/$id';
  static String deleteTipoProduto(String id) =>
      '$_baseUrlNew/api/tipoProdutos/$id';

  // NF-e â€” NF08: EmissÃ£o real com XML (POST /api/nfe/{id}/emitir)
  static String emitirNfe(String nfeId) => '$_baseUrlNew/api/nfe/$nfeId/emitir';
  static String cancelarNfe(String nfeId) =>
      '$_baseUrlNew/api/nfe/$nfeId/cancelar';
  static String danfeNfe(String nfeId) => '$_baseUrlNew/api/nfe/$nfeId/danfe';
  static String xmlNfe(String nfeId) => '$_baseUrlNew/api/nfe/$nfeId/xml';
  static String emitirNfseNacional(String nfseId) =>
      '$_baseUrlNew/api/nfse/$nfseId/emitir-nacional';

  static String confirmarNfse(String nfseId) =>
      '$_baseUrlNew/api/nfse/$nfseId/confirmar';
  static String danfseNfse(String nfseId) =>
      '$_baseUrlNew/api/nfse/$nfseId/danfse';
  static String aceitarNfe(String nfeId) =>
      '$_baseUrlNew/api/nfe/$nfeId/aceitar';
  static String recusarNfe(String nfeId) =>
      '$_baseUrlNew/api/nfe/$nfeId/recusar';
  // Busca parceiro por CNPJ/CPF (usado pelo filtro de NF-e por parceiro/destinatario)
  static String buscarParceiroPorCnpj(String cpfCnpj) =>
      '$_baseUrlNew/api/parceiro?cpfCnpj=$cpfCnpj&tamanho=1';
  static String get importarNfeCsv => '$_baseUrlNew/api/nfe/importar-csv';
  static String get allNfe => '$_baseUrlNew/api/nfe';
  static String get createNfe => '$_baseUrlNew/api/nfe';
  static String nfeById(String id) => '$_baseUrlNew/api/nfe/$id';
  static String updateNfe(String id) => '$_baseUrlNew/api/nfe/$id';
  static String get allNfeTipoOperacao => '$_baseUrlNew/api/nfe-tipo-operacao';

  // NFe XML Import
  // Bug de producao: apontava para '/api/fiscal/nfe-importacao/...', rota
  // que nunca existiu no backend -- NfeImportController (real) expoe
  // '/api/nfe-import/importacao-xml/...'. Toda chamada retornava 404
  // ("Recurso nao encontrado: api/fiscal/nfe-importacao/preview").
  static String get nfeImportacaoPreview =>
      '$_baseUrlNew/api/nfe-import/importacao-xml/preview';
  static String get nfeImportacaoConfirmar =>
      '$_baseUrlNew/api/nfe-import/importacao-xml/confirmar';
  static String get nfeImportacaoListar =>
      '$_baseUrlNew/api/nfe-import/importacao-xml';
  static String get nfeImportacaoSintegra =>
      '$_baseUrlNew/api/nfe-import/importacao-sintegra';
  // Card cUlANCTt - importacao de arquivo SPED (EFD ICMS/IPI).
  static String get nfeImportacaoSped =>
      '$_baseUrlNew/api/nfe-import/importacao-sped';
  // Pedido explicito do usuario: identificar o parceiro do arquivo (pelo
  // CNPJ) ANTES de processar, pra filtrar os combos de conta bancaria pelo
  // parceiro certo (nao todos da empresa).
  static String get nfeImportacaoSintegraIdentificarParceiro =>
      '$_baseUrlNew/api/nfe-import/importacao-sintegra/identificar-parceiro';
  static String get nfeImportacaoSpedIdentificarParceiro =>
      '$_baseUrlNew/api/nfe-import/importacao-sped/identificar-parceiro';
  // Pedido explicito do usuario: confirmar a NF-e Entrada e um passo
  // separado da importacao (RASCUNHO_IMPORTACAO -> AUTORIZADA). Enquanto
  // nao confirmado, o registro pode ser excluido via deleteNfe/nfeById
  // (DELETE /api/nfe/{id}) normalmente.
  static String nfeImportacaoConfirmarEntrada(String id) =>
      '$_baseUrlNew/api/nfe-import/importacao-xml/$id/confirmar-entrada';

  // NFS-e / Nota Fiscal de ServiÃ§o
  static String get nfseIssue => '$_baseUrlNew/api/nfse/issue';
  static String nfseStatusUrl(String municipalityCode, String nfseNumber) =>
      '$_baseUrlNew/api/nfse/status?municipalityCode=${Uri.encodeComponent(municipalityCode)}&nfseNumber=${Uri.encodeComponent(nfseNumber)}';
  static String get nfseCancel => '$_baseUrlNew/api/nfse/cancel';
  static String get nfseContingency => '$_baseUrlNew/api/nfse/contingency';
  static String get nfseAudit => '$_baseUrlNew/api/nfse/audit';
  // NFSe (fiscal/nfse)
  static String get nfseEmitir => '$_baseUrlNew/api/fiscal/nfse/emitir';
  static String nfseStatusNumero(String numero) =>
      '$_baseUrlNew/api/fiscal/nfse/status/$numero';
  static String get nfseCancelar => '$_baseUrlNew/api/fiscal/nfse/cancelar';
  static String get nfseAuditoria => '$_baseUrlNew/api/fiscal/nfse/auditoria';
  // NFS-e grid (consulta CRUD) e series
  static String get allNfse => '$_baseUrlNew/api/nfse';
  static String nfse(String id) => '$_baseUrlNew/api/nfse/$id';
  static String get allNfseSerie => '$_baseUrlNew/api/nfse_serie';
  static String nfseSerie(String id) => '$_baseUrlNew/api/nfse_serie/$id';
  // NFS-e config
  static String nfseConfig(int empresaId) =>
      '$_baseUrlNew/api/nfse-config?empresaId=$empresaId';
  static String get nfseConfigSalvar => '$_baseUrlNew/api/nfse-config';

  // NFS-e XML Import -- analogo a nfeImportacaoPreview/Confirmar/Listar
  // acima, mesmo padrao preview -> confirmar (NfseImportController).
  static String get nfseImportacaoPreview =>
      '$_baseUrlNew/api/nfse-import/importacao-xml/preview';
  static String get nfseImportacaoConfirmar =>
      '$_baseUrlNew/api/nfse-import/importacao-xml/confirmar';
  static String get nfseImportacaoListar =>
      '$_baseUrlNew/api/nfse-import/importacao-xml';

  // Dashboard de mensalidades/modulos (pago/atrasado/pendente) + relatorio PDF
  static String get mensalidadeDashboard =>
      '$_baseUrlNew/api/financeiro/mensalidade-dashboard';
  static String get mensalidadeDashboardPdf =>
      '$_baseUrlNew/api/financeiro/mensalidade-dashboard/relatorio-pdf';

  // Vinculo Parceiro x Modulo de Servico (ParceiroModuloController)
  static String get parceiroModulo => '$_baseUrlNew/api/parceiro-modulo';

  // CRM / RecorrÃªncias e Faturas
  static String get allRecurringContracts => '$_baseUrlNew/api/crm/contracts';
  static String get createRecurringContract => '$_baseUrlNew/api/crm/contracts';
  static String get allInvoiceRecords => '$_baseUrlNew/api/crm/invoices';
  static String get generateInvoice => '$_baseUrlNew/api/crm/invoices';
  static String get allReminderNotifications =>
      '$_baseUrlNew/api/crm/reminders';
  static String get sendReminder => '$_baseUrlNew/api/crm/reminders';
  static String get allCrmDeals => '$_baseUrlNew/api/crm/deals';
  static String get createCrmDeal => '$_baseUrlNew/api/crm/deals';
  static String updateCrmDealStage(String id) =>
      '$_baseUrlNew/api/crm/deals/$id/stage';
  static String get importMarketplaceOrder =>
      '$_baseUrlNew/api/crm/deals/import-marketplace';

  // IA assistiva para chat/GED
  static String get aiChatSummarize => '$_baseUrlNew/api/ai/chat/summarize';
  static String get aiTextCorrect => '$_baseUrlNew/api/ai/text/correct';
  static String get aiGedClassify => '$_baseUrlNew/api/ai/ged/classify';

  // NFC-e / PDV (Card 8)
  static String emitirNfce(int vendaId) =>
      '$_baseUrlNew/api/v1/vendas/$vendaId/emitir-nfce';
  static String nfceStatus(int nfceId) =>
      '$_baseUrlNew/api/v1/nfce/$nfceId/status';
  static String nfceDanfe(int nfceId) =>
      '$_baseUrlNew/api/v1/nfce/$nfceId/danfe.pdf';
  static String nfceXml(int nfceId) => '$_baseUrlNew/api/v1/nfce/$nfceId/xml';
  static String nfceQrCode(int nfceId, {int size = 200}) =>
      '$_baseUrlNew/api/v1/nfce/$nfceId/qrcode.png?size=$size';
  static String cancelarNfce(int nfceId) =>
      '$_baseUrlNew/api/v1/nfce/$nfceId/cancelar';
  static String reenviarContingenciaNfce(int nfceId) =>
      '$_baseUrlNew/api/v1/nfce/$nfceId/reenviar-contingencia';
  static String enviarEmailNfce(int nfceId) =>
      '$_baseUrlNew/api/v1/nfce/$nfceId/enviar-email';
  static String inutilizarNfce() => '$_baseUrlNew/api/v1/nfce/inutilizar';
  static String statusSefaz(String uf, {String ambiente = 'HOMOLOGACAO'}) =>
      '$_baseUrlNew/api/v1/fiscal/sefaz/status?uf=$uf&ambiente=$ambiente';
  static String nfceHealth(int empresaId, String uf,
          {String ambiente = 'HOMOLOGACAO'}) =>
      '$_baseUrlNew/api/v1/fiscal/nfce/health?empresaId=$empresaId&uf=$uf&ambiente=$ambiente';
  static String uploadCertificadoNfce() =>
      '$_baseUrlNew/api/v1/fiscal/nfce/certificado';
  static String configFiscal(int empresaId, {int? parceiroId}) => parceiroId ==
          null
      ? '$_baseUrlNew/api/v1/fiscal/nfce/config/$empresaId'
      : '$_baseUrlNew/api/v1/fiscal/nfce/config/$empresaId?parceiroId=$parceiroId';
  static String updateConfigFiscal(int configId) =>
      '$_baseUrlNew/api/v1/fiscal/nfce/config/$configId';
  static String createConfigFiscal() =>
      '$_baseUrlNew/api/v1/fiscal/nfce/config';
  static String produtosBusca(String nome, int empresaId) =>
      '$_baseUrlNew/api/produto?nome=${Uri.encodeComponent(nome)}&empresa=$empresaId&page=0&size=20';

  // Trading â€” Watchlist e Alertas
  static String get tradingWatchlist => '$_baseUrlNew/api/trading/watchlist';
  static String tradingWatchlistItem(String id) =>
      '$_baseUrlNew/api/trading/watchlist/$id';
  static String get tradingAlertas => '$_baseUrlNew/api/trading/alertas';
  static String tradingAlerta(String id) =>
      '$_baseUrlNew/api/trading/alertas/$id';

  // Trading â€” OperaÃ§Ãµes Assistidas
  static String get tradingOperacoes =>
      '$_baseUrlNew/api/trading/operacao-assistida';
  static String tradingOperacaoStatus(String id) =>
      '$_baseUrlNew/api/trading/operacao-assistida/$id/status';
  static String tradingOperacao(String id) =>
      '$_baseUrlNew/api/trading/operacao-assistida/$id';

  static String get tradingCarteira => '$_baseUrlNew/api/trading/carteira';
  static String get tradingCarteiraOperacoes =>
      '$_baseUrlNew/api/trading/carteira/operacoes';
  static String tradingCarteiraOperacao(String id) =>
      '$_baseUrlNew/api/trading/carteira/operacao/$id';
  static String get tradingCarteiraCorretoras =>
      '$_baseUrlNew/api/trading/carteira/corretoras';
  static String get tradingCarteiraCorretoraMovimento =>
      '$_baseUrlNew/api/trading/carteira/corretoras/movimento';
  // Departamento Pessoal profissional
  static String get dpDashboard => '$_baseUrlNew/api/dp/dashboard';
  static String get dpDashboardKpi => '$_baseUrlNew/api/dp/dashboard/kpi';
  static String get dpRelatorioResumo =>
      '$_baseUrlNew/api/dp/relatorios/resumo';
  static String dpExportDominio(String competencia) =>
      '$_baseUrlNew/api/dp/export/dominio?competencia=${Uri.encodeComponent(competencia)}';
  static String dpPortal(String funcionarioId) =>
      '$_baseUrlNew/api/dp/portal/$funcionarioId';
  static String get dpEsocialImportar => '$_baseUrlNew/api/dp/esocial/importar';
  static String get dpFolhaCompetencias =>
      '$_baseUrlNew/api/dp/folha/competencias';
  static String dpFolhaProcessar(int id) =>
      '$_baseUrlNew/api/dp/folha/competencias/$id/processar';
  static String dpFolhaHolerites(int id) =>
      '$_baseUrlNew/api/dp/folha/competencias/$id/holerites';
  static String dpFolhaHoleritePdf(int id) =>
      '$_baseUrlNew/api/dp/folha/holerite/$id/pdf';
  static String dpFolhaCnab240(int id) =>
      '$_baseUrlNew/api/dp/folha/competencias/$id/cnab240';
  static String get dpPontoAfdImportar =>
      '$_baseUrlNew/api/dp/ponto/afd/importar';
  static String dpPontoEspelhoPdf(int funcId, String inicio, String fim) =>
      '$_baseUrlNew/api/dp/ponto/espelho/pdf?funcionarioId=$funcId&dataInicio=$inicio&dataFim=$fim';
  static String get dpDependentes => '$_baseUrlNew/api/dp/dependentes';
  static String get dpAfastamentos => '$_baseUrlNew/api/dp/afastamentos';
  static String get dpHistoricos => '$_baseUrlNew/api/dp/historicos';

  static String get tradingBrokerConfig =>
      '$_baseUrlNew/api/trading/broker-config';

  // Consulta e Download DF-e
  static final String consultaDfeConsultar =
      '$_baseUrlNew/api/fiscal/consulta-dfe/consultar';
  static String baixarDfe(String nsu) =>
      '$_baseUrlNew/api/fiscal/consulta-dfe/baixar/$nsu';
  static final String importacoesDfe =
      '$_baseUrlNew/api/fiscal/consulta-dfe/importacoes';

  // Manifestação do Destinatário
  static final String manifestacaoPendentes =
      '$_baseUrlNew/api/fiscal/manifestacao/pendentes';
  static final String manifestacaoHistorico =
      '$_baseUrlNew/api/fiscal/manifestacao/historico';
  static final String manifestacaoRegistrar =
      '$_baseUrlNew/api/fiscal/manifestacao';

  // Lançamentos Financeiros (unificado)
  static String get lancamentosFinanceiros =>
      '$_baseUrlNew/api/financeiro/lancamentos';

  // Importação de Extrato Bancário
  static String get extratoPreview =>
      '$_baseUrlNew/api/financeiro/extrato-importacao/preview';
  static String get extratoConfirmar =>
      '$_baseUrlNew/api/financeiro/extrato-importacao/confirmar';
  static String get extratoImportacoes =>
      '$_baseUrlNew/api/financeiro/extrato-importacao';
  static String excluirExtratoImportacao(int id) =>
      '$_baseUrlNew/api/financeiro/extrato-importacao/$id';

  // Importação em lote de boletos de mensalidade
  static String get boletoLoteIniciar =>
      '$_baseUrlNew/api/importacao/boletos-mensalidade/lote';
  static String boletoLoteArquivos(String loteId) =>
      '$_baseUrlNew/api/importacao/boletos-mensalidade/lote/$loteId/arquivos';
  static String boletoLoteListar(String loteId) =>
      '$_baseUrlNew/api/importacao/boletos-mensalidade/lote/$loteId';
  static String boletoLoteConfirmar(String loteId) =>
      '$_baseUrlNew/api/importacao/boletos-mensalidade/lote/$loteId/confirmar';

  // Dashboard Financeiro Gerencial
  static final String dashboardFinanceiro =
      '$_baseUrlNew/api/financeiro/dashboard';

  // ConciliaÃ§Ã£o BancÃ¡ria
  static final String conciliacaoPendentes =
      '$_baseUrlNew/api/financeiro/conciliacao/pendentes';
  static String conciliacaoSugestoes(int contaBancariaId) =>
      '$_baseUrlNew/api/financeiro/conciliacao/$contaBancariaId/sugestoes';
  static final String conciliacaoConciliar =
      '$_baseUrlNew/api/financeiro/conciliacao/conciliar';
  static String conciliacaoAuto(int contaBancariaId) =>
      '$_baseUrlNew/api/financeiro/conciliacao/auto/$contaBancariaId';
  static String conciliacaoDesfazer(int conciliacaoId) =>
      '$_baseUrlNew/api/financeiro/conciliacao/$conciliacaoId';
  static final String conciliacaoListar =
      '$_baseUrlNew/api/financeiro/conciliacao';

  // Rateio Financeiro
  static String rateioListar(String tipo, dynamic id) =>
      '$_baseUrlNew/api/financeiro/rateio/$tipo/$id';
  static String get rateioSalvar => '$_baseUrlNew/api/financeiro/rateio';
  static String rateioDeletar(String tipo, dynamic id) =>
      '$_baseUrlNew/api/financeiro/rateio/$tipo/$id';
  static String rateioHistorico(String tipo, dynamic id) =>
      '$_baseUrlNew/api/financeiro/rateio/$tipo/$id/historico';

  // Anexos financeiros
  static String get anexosFinanceiros => '$_baseUrlNew/api/financeiro/anexos';
  static String anexoFinanceiro(String id) =>
      '$_baseUrlNew/api/financeiro/anexos/$id';
  static String anexoFinanceiroDownload(String id) =>
      '$_baseUrlNew/api/financeiro/anexos/$id/download';
  static String anexoFinanceiroLinhaDigitavel(String id) =>
      '$_baseUrlNew/api/financeiro/anexos/$id/linha-digitavel';

  // Cobrança Automática
  static String get cobrancaAutomaticaEnviar =>
      '$_baseUrlNew/api/financeiro/cobranca-automatica/enviar';
  static String get cobrancaAutomaticaAgendar =>
      '$_baseUrlNew/api/financeiro/cobranca-automatica/agendar';
  static String get cobrancaAutomaticaHistorico =>
      '$_baseUrlNew/api/financeiro/cobranca-automatica/historico';
  static String get cobrancaAutomaticaPendentes =>
      '$_baseUrlNew/api/financeiro/cobranca-automatica/pendentes';

  // Regua de cobranca
  static String get reguasCobranca => '$_baseUrlNew/api/financeiro/reguas';
  static String reguaCobranca(int id) => '$reguasCobranca/$id';
  static String get cobrancasRegua => '$_baseUrlNew/api/financeiro/cobrancas';

  // Contingência e Rejeições
  static String get listarContingencia => '$_baseUrlNew/api/contingencia';
  static String get listarRejeicoes => '$_baseUrlNew/api/rejeicoes';
  static String reenviarContingencia(dynamic id) =>
      '$_baseUrlNew/api/contingencia/$id/reenviar';

  // Custo Médio
  static String custoMedioConsultar(dynamic id) =>
      '$_baseUrlNew/api/custo-medio/produto/$id';
  static String get custoMedioRecalcular =>
      '$_baseUrlNew/api/custo-medio/recalcular';
  static String custoMedioHistorico(dynamic id) =>
      '$_baseUrlNew/api/custo-medio/historico/$id';
  static String get baixarPorVenda => '$_baseUrlNew/api/custo-medio/baixar';

  // Clonar Lancamento Financeiro
  static String clonarContaPagar(String id) =>
      '$_baseUrlNew/api/financeiro/conta-pagar/$id/clonar';
  static String clonarContaReceber(String id) =>
      '$_baseUrlNew/api/financeiro/conta-receber/$id/clonar';

  // Kanban de Pagamentos
  static String contaPagarStatus(String id) =>
      '$_baseUrlNew/api/financeiro/conta-pagar/$id/status';
  static String contaReceberStatus(String id) =>
      '$_baseUrlNew/api/financeiro/conta-receber/$id/status';

  // Conciliação Bancária - Importação OFX
  static String get conciliacaoImportarOfx =>
      '$_baseUrlNew/api/financeiro/conciliacao/importar-ofx';

  // Dashboard Financeiro KPIs
  static String dashboardFinanceiroKpis(
          {String? empresaId, String? parceiroId, int? dias}) =>
      '$_baseUrlNew/api/financeiro/dashboard/kpis${_buildQueryParams(empresaId: empresaId, parceiroId: parceiroId, dias: dias)}';
  static String dashboardFinanceiroProjecao(
          {String? empresaId, String? parceiroId, int? meses}) =>
      '$_baseUrlNew/api/financeiro/dashboard/projecao${_buildQueryParams(empresaId: empresaId, parceiroId: parceiroId, meses: meses)}';

  // Exportação Power BI / CSV
  static String exportarCsv(String tipo) =>
      '$_baseUrlNew/api/financeiro/exportar/$tipo';

  static String _buildQueryParams(
      {String? empresaId, String? parceiroId, int? dias, int? meses}) {
    final params = <String>[];
    if (empresaId != null) params.add('empresaId=$empresaId');
    if (parceiroId != null) params.add('parceiroId=$parceiroId');
    if (dias != null) params.add('dias=$dias');
    if (meses != null) params.add('meses=$meses');
    return params.isEmpty ? '' : '?${params.join('&')}';
  }

  // Aprovação de Pagamentos
  static String get aprovacaoPagamentoFila =>
      '$_baseUrlNew/api/financeiro/aprovacao-pagamento/fila';
  static String aprovacaoPagamentoSolicitar(dynamic contaPagarId) =>
      '$_baseUrlNew/api/financeiro/aprovacao-pagamento/$contaPagarId/solicitar';
  static String aprovacaoPagamentoAprovar(dynamic aprovacaoId) =>
      '$_baseUrlNew/api/financeiro/aprovacao-pagamento/$aprovacaoId/aprovar';
  static String aprovacaoPagamentoReprovar(dynamic aprovacaoId) =>
      '$_baseUrlNew/api/financeiro/aprovacao-pagamento/$aprovacaoId/reprovar';
  static String aprovacaoPagamentoConta(dynamic contaPagarId) =>
      '$_baseUrlNew/api/financeiro/aprovacao-pagamento/conta/$contaPagarId';

  // Baixa Automática de Recebíveis
  static final String baixaAutomaticaImportar =
      '$_baseUrlNew/api/financeiro/baixa-automatica/importar';
  static String baixaAutomaticaConferir(dynamic id, String acao) =>
      '$_baseUrlNew/api/financeiro/baixa-automatica/$id/conferir?acao=$acao';
  static final String baixaAutomaticaPendentes =
      '$_baseUrlNew/api/financeiro/baixa-automatica/pendentes';
  static String baixaAutomaticaConta(dynamic contaReceberId) =>
      '$_baseUrlNew/api/financeiro/baixa-automatica/conta/$contaReceberId';

  // Automação Financeira
  static final String automacoesFinanceiras =
      '$_baseUrlNew/api/financeiro/automacoes';
  static String automacaoFinanceira(String id) =>
      '$_baseUrlNew/api/financeiro/automacoes/$id';
  static String executarAutomacaoFinanceira(String id) =>
      '$_baseUrlNew/api/financeiro/automacoes/$id/executar';
  static String logsAutomacaoFinanceira(String id) =>
      '$_baseUrlNew/api/financeiro/automacoes/$id/logs';
  static final String todosLogsAutomacoes =
      '$_baseUrlNew/api/financeiro/automacoes/logs';

  // Renegociação de Títulos
  static final String renegociacao = '$_baseUrlNew/api/financeiro/renegociacao';
  static String renegociacaoById(String id) =>
      '$_baseUrlNew/api/financeiro/renegociacao/$id';

  // DRE Gerencial
  static String get dre => '$_baseUrlNew/api/financeiro/dre';
  static String get drePeriodos => '$_baseUrlNew/api/financeiro/dre/periodos';

  // Escrituração Fiscal
  static final String escrituracaoFiscalBase =
      '$_baseUrlNew/api/escrituracao-fiscal';
  static String escrituracaoFiscalListar(int empresaId) =>
      '$escrituracaoFiscalBase?empresaId=$empresaId';
  static String escrituracaoFiscalDetalhe(int id) =>
      '$escrituracaoFiscalBase/$id';
  static String escrituracaoFiscalItens(int id) =>
      '$escrituracaoFiscalBase/$id/itens';
  static String get escrituracaoFiscalGerar => '$escrituracaoFiscalBase/gerar';
  static String escrituracaoFiscalConferir(int id) =>
      '$escrituracaoFiscalBase/$id/conferir';
  static String escrituracaoFiscalFechar(int id) =>
      '$escrituracaoFiscalBase/$id/fechar';

  // Cancelamento e CC-e
  static String cancelamentoNfeCancelar(String nfeId) =>
      '$_baseUrlNew/api/fiscal/cancelamento-cce/nfe/$nfeId/cancelar';
  static String cancelamentoNfeCce(String nfeId) =>
      '$_baseUrlNew/api/fiscal/cancelamento-cce/nfe/$nfeId/cce';
  static String cancelamentoNfeHistorico(String nfeId) =>
      '$_baseUrlNew/api/fiscal/cancelamento-cce/nfe/$nfeId/historico';

  // Contábil - Plano de Contas
  static String get allContasContabeis => '$_baseUrlNew/api/contas-contabeis';
  static String get createContaContabil => '$_baseUrlNew/api/contas-contabeis';
  static String contaContabilById(String id) =>
      '$_baseUrlNew/api/contas-contabeis/$id';
  static String updateContaContabil(String id) =>
      '$_baseUrlNew/api/contas-contabeis/$id';
  static String deleteContaContabil(String id) =>
      '$_baseUrlNew/api/contas-contabeis/$id';
  static String contasContabeisAtivas(String empresaId) =>
      '$_baseUrlNew/api/contas-contabeis?empresaId=$empresaId&ativas=true';
  static String contasContabeisPorTipo(String empresaId, String tipo) =>
      '$_baseUrlNew/api/contas-contabeis?empresaId=$empresaId&ativas=true&tipo=$tipo';

  // Contábil - Lançamentos
  static String allLancamentosContabeis(String empresaId, String periodo) =>
      '$_baseUrlNew/api/lancamentos-contabeis?empresaId=$empresaId&periodo=$periodo';
  static String get createLancamentoContabil =>
      '$_baseUrlNew/api/lancamentos-contabeis';
  static String lancamentoContabilById(String id) =>
      '$_baseUrlNew/api/lancamentos-contabeis/$id';
  static String updateLancamentoContabil(String id) =>
      '$_baseUrlNew/api/lancamentos-contabeis/$id';
  static String deleteLancamentoContabil(String id) =>
      '$_baseUrlNew/api/lancamentos-contabeis/$id';
  static String autoGerarLancamentos(String empresaId, String periodo) =>
      '$_baseUrlNew/api/lancamentos-contabeis/auto-gerar?empresaId=$empresaId&periodo=$periodo';
  static String balanceteUrl(
          String empresaId, String dataInicio, String dataFim) =>
      '$_baseUrlNew/api/lancamentos-contabeis/balancete?empresaId=$empresaId&dataInicio=$dataInicio&dataFim=$dataFim';
  static String balancoUrl(String empresaId, String data) =>
      '$_baseUrlNew/api/lancamentos-contabeis/balanco?empresaId=$empresaId&data=$data';
  static String analisarVariacaoUrl(
          String empresaId, String periodo, String? comparacao) =>
      '$_baseUrlNew/api/lancamentos-contabeis/analisar-variacao?empresaId=$empresaId&periodo=$periodo${comparacao != null ? '&comparacao=$comparacao' : ''}';

  // Contábil - Períodos
  static String allPeriodosContabeis(String empresaId) =>
      '$_baseUrlNew/api/periodos-contabeis?empresaId=$empresaId';
  static String abrirPeriodoContabil(String empresaId, String periodo) =>
      '$_baseUrlNew/api/periodos-contabeis/abrir?empresaId=$empresaId&periodo=$periodo';
  static String validarFechamentoUrl(String empresaId, String periodo) =>
      '$_baseUrlNew/api/periodos-contabeis/validar-fechamento?empresaId=$empresaId&periodo=$periodo';
  static String fecharPeriodoUrl(
          String empresaId, String periodo, int? usuarioId) =>
      '$_baseUrlNew/api/periodos-contabeis/fechar?empresaId=$empresaId&periodo=$periodo${usuarioId != null ? '&usuarioId=$usuarioId' : ''}';
  static String statusPeriodosUrl(String empresaId) =>
      '$_baseUrlNew/api/periodos-contabeis/status?empresaId=$empresaId';

  // IA - Análises
  static String analisarFechamentoUrl(String empresaId, String periodo) =>
      '$_baseUrlNew/api/ai/analisar-fechamento?empresaId=$empresaId&periodo=$periodo';
  static String analisarDreUrl(String empresaId, String periodo) =>
      '$_baseUrlNew/api/ai/analisar-dre?empresaId=$empresaId&periodo=$periodo';
  static String anomaliasFiscaisUrl(String empresaId, String? periodo) =>
      '$_baseUrlNew/api/ai/anomalias-fiscais?empresaId=$empresaId${periodo != null ? '&periodo=$periodo' : ''}';
  static String preverObrigacoesUrl(String empresaId) =>
      '$_baseUrlNew/api/ai/prever-obrigacoes?empresaId=$empresaId';
  static String perguntarAiUrl(String empresaId, String pergunta) =>
      '$_baseUrlNew/api/ai/perguntar?empresaId=$empresaId&pergunta=${Uri.encodeComponent(pergunta)}';

  // Query Builder — Ferramenta de consulta SQL
  static final String queryBuilder =
      '$_baseUrlNew/api/ferramentas/query-builder';
  static String get queryBuilderSchemas => '$queryBuilder/schemas';
  static String get queryBuilderTabelas => '$queryBuilder/tabelas';
  static String queryBuilderColunas(String schema, String tabela) =>
      '$queryBuilder/tabelas/$schema/$tabela/colunas';
  static String get queryBuilderExecutar => '$queryBuilder/executar';
  static String get queryBuilderAtualizar => '$queryBuilder/atualizar';
  static String get queryBuilderQueries => '$queryBuilder/queries-salvas';
  static String queryBuilderQuery(int id) => '$queryBuilder/queries-salvas/$id';

  // ── Dashboards por área (Fase 171 — fundação) ──────────────────────────
  // Rotas kebab-case distintas das legadas (/api/dashboard/financeiro,
  // /api/dp/dashboard) para não colidir. empresaId é resolvido no backend
  // via TenantContext — nunca enviado como query param.
  static String get dashboardAtendimentoKpis =>
      '$_baseUrlNew/api/dashboard/atendimento/kpis';
  static String get dashboardFinanceiroAreaKpis =>
      '$_baseUrlNew/api/dashboard/financeiro-area/kpis';
  static String get dashboardComercialKpis =>
      '$_baseUrlNew/api/dashboard/comercial/kpis';
  static String get dashboardComercialMercadorias =>
      '$_baseUrlNew/api/dashboard/comercial/mercadorias';
  static String get dashboardDpAreaKpis =>
      '$_baseUrlNew/api/dashboard/dp-area/kpis';
  static String get dashboardFiscalKpis =>
      '$_baseUrlNew/api/dashboard/fiscal/kpis';

  // ── Sistema Logs e Monitoramento ──
  static String get sistemaLogs => '$_baseUrlNew/api/sistema-logs';
}
