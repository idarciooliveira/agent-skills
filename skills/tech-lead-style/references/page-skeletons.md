# Page skeletons

Keep the order and drop sections that don't apply. "→" separates sections, and `A | B` is a table's columns.

- **Home / index:**
  1. EM PLANEAMENTO lozenge
  2. Definition sentence
  3. "Hoje … Com o X, …"
  4. "Factos principais" key/value table
  5. "Como ler esta documentação": `Se precisa de… | Leia`
  6. Children macro
- **Context / problem:**
  1. Situação atual, with `Problema | O que acontece na prática`
  2. O que muda (Hoje / Com o X, parallel bullets)
  3. `# | Objetivo | Como se mede`
  4. Benefícios (bold lead-ins)
  5. Não-objetivos
  6. Detalhe técnico
- **PRD:**
  - Metadata table (Estado / Responsável / Última revisão / Aprovação), then TOC
  - Numbered sections:
    1. Resumo
    2. Objetivos e métricas
    3. Não-objetivos
    4. Personas: `Persona | O que precisa | Como usa`
    5. Âmbito (Dentro / Fora)
    6. RF-xx with MoSCoW lozenges and acceptance criteria
    7. RNF-xx with "Valor alvo" (matches the repo's QS-xx)
    8. Pressupostos
    9. Dependências: `Dependência | De quem | Necessária até`
    10. Questões em aberto: `Questão | Proposta atual | Decidir até`
    11. Entregas por fase
- **Decision memo:**
  1. Metadata (Reunião / Apresenta / AGUARDA DECISÃO)
  2. "N decisões permitem arrancar X no próprio dia, <data>."
  3. Decisões pedidas (numbered imperatives)
  4. Contexto de cada decisão: one H3 each, with `Opção | Efeito` when there are alternatives
  5. Registo das decisões: empty `# | Decisão tomada | Data | Observações`
- **Compliance:**
  1. Warning panel ("Não constitui parecer jurídico")
  2. Options with PADRÃO / A PEDIDO
  3. `Referência | A quem se aplica | O que implica`
  4. Data classes with SIM / NÃO
  5. Numbered controls
  6. Retention with Motivo
  7. Contract task list, ending "A redação é da responsabilidade do Jurídico."
- **Roadmap:**
  1. Info panel (start date, dependencies, blackout)
  2. `Fase | Início | Fim | Resultado`
  3. Month grid with ■ cells
  4. One H2 per phase ("Fase 0 — Fundações"): dates, bullets, **Critérios de saída:**
  5. `Marco | Data prevista`
- **Estimate:**
  1. Warning panel ("Estimativa indicativa, a validar…")
  2. `Componente | Quantidade | Especificação por unidade | Função`, one table per location
  3. `Sinal | Limiar | Ação`
  4. Custos panel (who prices it)
- **Risk register:**
  1. A one-line scale and review rule
  2. `ID | Risco | P | I | Mitigação | Sinal de alerta | Responsável | Estado`, with a bold headline in each Risco cell and shaded P/I
  3. "Riscos que pedem decisão": "**R-02** — aceitar X ou financiar Y."
- **Team / RACI:**
  1. Note panel on "a definir"
  2. `Função | Nome | Dedicação | Responsabilidades`, where Dedicação is Tempo inteiro / Parcial / Pontual
  3. `Área | Envolvimento`
  4. RACI legend "**R** executa · **A** responde pelo resultado (um por atividade) · **C** é consultado · **I** é informado", then the grid
- **Operating model:**
  1. `Equipa | Onde trabalha | O que acompanha | Recebe alertas`
  2. Alert flow as 3 panels
  3. Severity lozenges (CRÍTICO / AVISO / INFORMAÇÃO)
  4. Onboarding list, then **Objetivo:**
  5. `Passo | O que acontece | Condição para avançar`
  6. `Rotina | Frequência | Responsável`
- **Glossary:**
  1. "Termos … explicados para quem não é da área técnica. Alguns termos ficam em inglês porque é assim que a indústria os usa."
  2. `Termo | Significado`, entries like "**Dual-write** (envio duplo)" plus "<o que é>. <o que faz>. <para que serve>."
- **Proposal to other teams:**
  1. Grey caps eyebrow, 2-sentence purpose, audience lozenges
  2. TL;DR panel with the draft caveat
  3. PARTE 1 · A IDEIA: analogy, then cards with TEMOS / FALTA
  4. PARTE 2 · APLICADO: rules, lifecycle with gates and "Contagem: n existem, n parciais, n faltam", `Requisito | Quem garante | Evidência`, RACI
  5. PARTE 3 · EXEMPLOS: Hoje / Proposta
  6. PARTE 4 · ROLLOUT: bold verb steps, KPIs with "meta:"
  7. Referências ("Onde usamos:")
  8. Questões em aberto (Sobre a proposta / Para decidir)
  9. Grey sign-off
- **Plan vs. reality:**
  1. Info panel (where the plan is, what this page shows, repo is the source)
  2. `Recurso | Pedido | Alocado | Do pedido`
  3. `Área | Plano original | Realidade | Impacto`
  4. Topic sections with "Risco aceite:" and "Recomendações ao X:"
  5. Calendário (one line)
  6. Pendente
- **Repo index (runbooks):**
  1. Info panel ("vivem no repositório, em inglês, e só mudam por pull request… Não copiar o conteúdo para aqui")
  2. H2 groups with `Runbook | Quando usar | Link`
  3. "Ponto de partida do operador: …"
- **Checklist / request to a team:**
  1. Kicker "**Escopo · Registo de <data> · Para partilha com <Equipa>**"
  2. **Objetivo:** and **Privacidade:**
  3. Resumo table
  4. `Área | Resultado`, with untested items stated
  5. Pedidos: an italic "Assinalar cada item…", then H3s with a task list, **Referência:**, **Pedido:** and **Resposta / previsão:** ____
