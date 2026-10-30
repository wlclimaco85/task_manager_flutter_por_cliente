# CLAUDE.md — task_manager_flutter_por_cliente (Conta Própria / SaaS B2B)

> Regras globais da workspace estão em `C:\App_Academia\CLAUDE.md`. Em conflito, o pai prevalece.

## Project

**Flutter "Conta Própria" — SaaS B2B para o empresário direto (sem escritório de contabilidade por cima).**

O próprio usuário é a empresa direta. Foco em execução, simplicidade e autoatendimento. Consome o
backend `AppAcademia`. `description` do pubspec: "App Conta Própria - Gestão Direta SaaS B2B".

**NÃO possui** telas de gestão contábil: sem chat com escritório, sem chamados contábeis, sem GED
contábil, sem alvarás, sem menu de parceiros contábeis. **Mantém:** cadastros básicos (clientes/
fornecedores como "Contatos", produtos, serviços, contas bancárias), financeiro (contas a pagar/
receber, extrato, DRE) e vendas/fiscal básico.

**Core Value:** gestão direta e leve para o empresário — tudo que lembra "escritório contábil acima"
fica de fora de propósito.

## Stack & Plataformas

- **Flutter/Dart**, Material 3. Plataformas: android, ios, windows, web, macos, linux.
- **SEM fastlane** neste projeto (publicação não automatizada aqui).
- Entradas: `main.dart`, `main_web.dart`, `main_windows.dart`.

## Tema (IDENTIDADE PRÓPRIA — NÃO MISTURAR)

- Tema oficial **"Serene Zen Management"** em `lib/core/theme/zen_theme.dart` (+ `GridColors`).
- Identidade: cores suaves de gestão, leveza, tranquilidade, clareza, **anti-ansiedade / anti-fome**.
  Sensação de sossego — oposto da densidade do admin e do verde do Abraço.
- **PROIBIDO** trazer tema/paleta de qualquer outro app. O "zen" é o diferencial deste projeto.

## Replicação de Componentes (CRÍTICO, com exceção de escopo)

- Membro da **tríade**. Recebe correções de bug compartilhado, contrato de API, network caller,
  models, auth, helpers, formatters e widgets genéricos vindas do `task_manager_flutter`.
- **EXCEÇÃO terminante:** é PROIBIDO copiar para cá telas de escritório contábil (Chat, Chamados,
  GED, Alvarás, parceiros contábeis). Replicar só o que faz sentido no "conta própria".
- Nunca copiar o tema dos outros ao replicar lógica.

## Arquitetura & Paridade

- Mesma base da tríade: `web/`, `windows/`, `mobile/`, `widgets/` genéricos, `services/`, `providers/`.
- Paridade multiplataforma obrigatória (Web/Windows ⇒ Mobile) para as telas que este app tem.

## UI/UX (OBRIGATÓRIO para mudança de layout)

- Mudança de layout/design DEVE envolver agente de UI/UX (`ui-ux-pro-max` / skill `frontend-design`),
  preservando a identidade zen. Correção funcional preserva o layout (menor diff).

## Componente de Cadastro / Detail + Abas de Relação (PONTO CRÍTICO — já reabriu várias vezes)

O insert pelo componente de *detail* e as abas de relação (ex.: Roles do Login, vínculos) são o ponto
que mais reincide. Ao mexer em tela de detail/cadastro ou em vínculo (role, aba de relação), o teste
do cenário é OBRIGATÓRIO e cobre o ciclo REAL ponta a ponta: `inserir → salvar (sucesso) → reabrir o
detail → conferir persistência → abrir a aba de relação e conferir o vínculo`. Trocar a role DEVE
refletir na grid, sem cache de roles antigas. Dois sistemas de permissão (`SecurityMatrix` e
`PermissionService`/`MenuConfig`). Proibido declarar pronto sem esse teste verde (Definition of Done no pai).

## Testes & Code Review (OBRIGATÓRIO)

- **Criar e rodar o teste do cenário (`flutter test` focado) antes de concluir.** Suíte inteira só antes
  de push pra `main`. `analyze` é só apoio.
- NUNCA find-replace em massa `const`→`final` (quebra `*.fromEnvironment` em runtime).
- **Push para `main` → code review OBRIGATÓRIO.** Branch base: `desenv`. Encoding UTF-8.
