# .github

Repositório de defaults da organização **revtriever-vera** (produto **Vera**): templates de issue e PR, o README do perfil, o script do project board e as **skills do Claude Code** distribuídas para os outros repositórios.

O repositório é **público**, como toda a organização: nada aqui pode conter ID de conta AWS, ID de VPC/subnet/security group/RDS, endpoint, ARN, e-mail ou telefone pessoal, token ou chave. Esses valores vêm de variáveis e secrets.

## Antes de usar

- **Sync de skills desligada até o dono configurar o acesso.** O workflow `sync-skills.yml` só roda por `workflow_dispatch` e o job de sync roda quando `vars.SKILLS_SYNC_ENABLED == 'true'` ou quando a execução manual marca `dry_run`. Sem a variável e sem `dry_run`, o workflow termina com um aviso explícito (job `disabled`) e não sincroniza nada. Até lá, copie `skills/<grupo>/*` à mão para `.claude/skills/` em `vera-api`/`vera-fe`.
- **Secret `GH_TOKEN`:** fine-grained PAT com `Contents: Read and write` em `vera-api` e `vera-fe` (nada além disso). Sem ele, a execução real da sync falha com uma anotação de erro clara por repositório; o `dry_run` funciona sem o secret e sem a variável `SKILLS_SYNC_ENABLED`. O cadastro do secret e da variável é o card revtriever-vera/vera#31. O PAT expira sem aviso: anote a data de expiração.
- **Runner:** o workflow roda em `ubuntu-latest`.

```
.github/
├── ISSUE_TEMPLATE/       # PRD, feature, bug, tech debt, QA + links de contato
├── pull_request_template.md
└── workflows/sync-skills.yml
profile/README.md         # página da org (github.com/revtriever-vera)
skills/                   # fonte de verdade das skills do Claude Code
setup-project.sh          # prepara o project board da org
```

## Skills: fonte única de verdade

A pasta `skills/` é a **fonte única** das skills do Claude Code. Cada repositório recebe só as skills relevantes ao seu contexto, no formato nativo `.claude/skills/<nome>/SKILL.md`. As skills são genéricas de stack e processo (camadas, dados, filas, testes, front, convenções); skills de módulos de negócio da Vera nascem junto com o módulo.

### Como funciona

1. Abra um PR aqui alterando arquivos em `skills/`.
2. O PR precisa de **aprovação humana**: esse é o gate de qualidade.
3. Depois do merge em `main`, dispare a action **Sync Skills** manualmente (`workflow_dispatch`); ela dá push direto na `main` dos repositórios configurados.
4. Nenhuma aprovação adicional nos repositórios destino: o gate já aconteceu aqui.
5. O Claude Code descobre as skills sozinho em `.claude/skills/`.

### Estrutura

```
skills/
├── sync-config.json                 # mapeamento repo → grupos
├── shared/                          # todos os repos recebem
│   ├── conventions/SKILL.md         # idioma, vocabulário, tipagem, lint, git, i18n, repositório público
│   ├── pr-review/SKILL.md           # como revisar um PR
│   └── qa-run/SKILL.md              # como executar o roteiro de QA de uma milestone
├── backend/                         # repos NestJS
│   ├── api-conventions/SKILL.md     # DTO/zod, OpenAPI, controller, contrato de erro
│   ├── architecture/SKILL.md        # camadas, ports, injeção
│   ├── caching/SKILL.md
│   ├── data-access/SKILL.md         # Kysely, tenant (companyId), migrations
│   ├── infrastructure/SKILL.md      # CDK, ambientes dev/prod, CI/CD
│   ├── local-dev/SKILL.md
│   ├── observability/SKILL.md       # pino, OTel, requestId
│   ├── queues-and-scheduling/SKILL.md
│   └── testing/SKILL.md
└── frontend/                        # repos React
    ├── data-fetching/SKILL.md
    ├── forms/SKILL.md
    ├── frontend-architecture/SKILL.md
    ├── testing/SKILL.md
    └── ui-and-styling/SKILL.md      # design system e i18n (pt-BR e en)
```

### Mapeamento por grupo

| Grupo        | Pastas recebidas      | Repositórios |
| ------------ | --------------------- | ------------ |
| **backend**  | `shared` + `backend`  | `vera-api`   |
| **frontend** | `shared` + `frontend` | `vera-fe`    |

`vera-observability` não recebe skills (repositório sem aplicação rodando). Para adicionar repositórios ou grupos, edite `skills/sync-config.json`.

### `.claude/skills` no repositório destino é um espelho

A sync **poda** qualquer skill que não esteja no conjunto canônico do grupo: editar uma skill direto no destino não adianta, o próximo sync sobrescreve. Cada repositório sincronizado ganha `.claude/skills/.synced-from-org`, listando o conjunto canônico e os grupos de origem.

Se um repositório precisa de uma skill só dele, declare em `keep` no `sync-config.json`:

```json
"keep": { "vera-api": ["skill-so-daqui"] }
```

### Execução manual

A action aceita `workflow_dispatch` com `repos` (lista separada por vírgula, ou `all`) e `dry_run`. Simule sempre com `dry_run: true` primeiro: ela só imprime `<repo> ← [<grupos>]`, sem clonar nem dar push, mesmo com `SKILLS_SYNC_ENABLED` desligada. Execuções da sync são serializadas (`concurrency: sync-skills`, sem cancelar a que está em andamento). O token do PAT vai ao `git` por `http.extraheader` e nunca é gravado na URL nem em `.git/config` dos destinos. Na execução real, para o `vera-api`, a sync compara as portas da skill `backend/local-dev` com o `docker-compose.yml` e emite um `::warning` se divergirem (não falha). Os repositórios destino precisam aceitar push direto na `main` pelo bot; se um ruleset bloquear, a sync falha com `push bloqueado` no log.

## Workflows

| Workflow        | Trigger                                                           | O que faz                                        |
| --------------- | ----------------------------------------------------------------- | ------------------------------------------------ |
| **Sync Skills** | Manual (`workflow_dispatch`), atrás de `vars.SKILLS_SYNC_ENABLED` (ou `dry_run`) | Sincroniza `.claude/skills/` nos repos do config |

## Issue templates

`.github/ISSUE_TEMPLATE/` vale para todos os repositórios da org sem template próprio.

| Template       | Título    | Labels aplicadas                         |
| -------------- | --------- | ---------------------------------------- |
| PRD (Roadmap)  | `[PRD] `  | `type: prd` · `status: refinement`       |
| Feature        | `[FEAT] ` | `type: feature` · `status: refinement`   |
| Bug            | `[BUG] `  | `type: bug` · `status: refinement`       |
| Débito técnico | `[TECH] ` | `type: tech-debt` · `status: refinement` |
| Handoff de QA  | `[QA] `   | `type: qa`                               |

As labels são aplicadas pelos templates, mas **não são criadas por este repositório**: precisam existir na org/repositório, senão o GitHub as ignora.

## PR template

`.github/pull_request_template.md`: o que muda, por quê, como validar e um checklist de merge (lint/typecheck/testes, Swagger, migration aditiva, PII em log, repositório público, skills atualizadas, custo AWS).

## Perfil da org

`profile/README.md` é a página renderizada em [github.com/revtriever-vera](https://github.com/revtriever-vera), possível porque este repositório é público.

## Project board

`setup-project.sh <número>` adiciona ao Project da org os campos que faltam (`Priority`, `Size`, `Area`, `Target`, `Spent (h)`), pulando os que já existem, e vincula `vera`, `vera-api`, `vera-fe` e `vera-observability`. Exige o número de um Project existente (não cria outro) e o escopo `project` no `gh`:

```bash
gh auth refresh -h github.com -s project
./setup-project.sh <número>
```

As colunas de Status ficam por conta da UI; a sugestão está no final do script.
