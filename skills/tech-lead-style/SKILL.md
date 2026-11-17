---
name: tech-lead-style
description: Writes pt-AO business docs (Confluence pages, proposals, decision memos, reports, plans, risk registers, checklists, requests to other teams) in a terse Tech Lead style: numbers, tables, named owners, labelled unknowns. Use when asked for "tech-lead-style".
---

# tech-lead-style

Say what is, with numbers, in short sentences. Put structure in tables. Name who acts. Label the unknowns. Point to the source.

For a full page, read [references/page-skeletons.md](references/page-skeletons.md) for the section order and [references/phrase-bank.md](references/phrase-bank.md) for reusable sentences.

## Language
- Use pt-AO with post-reform spelling: equipa, utilizador, ficheiro, registo, monitorização, ecrã, telemóvel, palavra-passe, deteção, Projeto. No Brazilian forms. Write "continua a enviar", not "enviando". Ordinals are "3.º".
- Keep the English trade term: logs, traces, dashboards, tenant, cluster, deploy, rollout, backup, onboarding, handover, backlog, pull request, SSO, Tech Lead, Compliance.
- Translate when a plain word exists: coletor, alta disponibilidade, cópia de segurança, mascaramento, retenção.
- Explain a term once, in parentheses, the first time it appears: "alta disponibilidade (um nó pode falhar sem parar o serviço)".

## Voice
- On reference pages, plans and reports, write in the impersonal third person with a named actor as subject: "O Comercial confirma…". Never use "você".
- Write instructions as infinitives: "Registar aqui o resultado…", "Não copiar o conteúdo para aqui: a cópia desatualiza."
- Use "nós" only in proposals to other teams ("Propomos…").
- One clause per sentence, 5–15 words. Fragments are fine in table cells.
- State rules as flat negations: "Não reinicia, não faz deploy e não altera sistemas dos clientes."
- State benefits as mechanisms, not adjectives.
- No greetings, opinions, exclamation marks, emoji or decorative icons.

## Numbers and uncertainty
- Give every claim a number plus a unit or the point where it's measured: "99,5% ou mais por mês, medida no gateway", "até 3 minutos após a falha (p95)".
- Number format: decimal comma, "10×", "2 a 5 TB", "16 vCPU · 64 GB RAM".
- Put the hedge in one labelled place. Don't spread it through the text. For example: "Estimativa indicativa, a validar na Fase 0 com volumes medidos."
- Unknowns are written "A definir", "Data prevista" or "(opcional)". Use "—" for a cell that doesn't apply.
- Never invent figures, prices, names, legal text or commitments. Write "A definir" and name who supplies the value.

## Structure
- Open with one of:
  - a definition sentence
  - a metadata table (Estado lozenge, Responsável, Última revisão)
  - a framing panel (scope, assumptions, dependencies)
  - a kicker line with "**Objetivo:**"
  
  Never open with "Introdução".
- H2 headings are sentence-case noun phrases or plain questions: "Quem observa o quê", "Não-objetivos". Number them only in a PRD or a decision memo.
- End on a repo pointer ("Detalhe técnico: `<path>` no repositório `<repo>`."), "Pendente", "Questões em aberto" or an empty log table. Never end with a summary.

## Formatting
- Use a table for anything with 2 or more attributes. Headers can read as questions: "Se precisa de… | Leia", "Opção | Efeito", "Questão | Proposta atual | Decidir até".
- IDs are stable and never renumbered: RF-01, RNF-01, R-01, Q1.
- Use bold only in these places:
  - row labels
  - a headline clause: "**Sem cláusula assinada, sem migração.** …"
  - label-colon lead-ins: "**Critérios de saída:**", "**Pedido:**"
  
  Never bold for emphasis inside a sentence.
- Lozenges are all caps:
  - green: done or default (SIM, TEMOS, PADRÃO)
  - yellow: pending (PROPOSTO, AGUARDA DECISÃO)
  - red: missing or mandatory (FALTA, MUST, CRÍTICO)
  - blue: informational (EM PLANEAMENTO)
  - grey: neutral (PARCIAL)
- Panels:
  - info: scope, source, TL;DR
  - warning: estimate or legal disclaimer
  - note: one hard rule
- Dates:
  - date picker in tables
  - "23/10/2026" in prose
  - written out in kickers
  - lowercase months for periods ("abril a junho de 2027")
  - YYYY-MM-DD in repo docs
- Paths, identifiers and placeholders go in `code`. Link a page by naming it: "Detalhe em <Página>."

## Moves
- Before and after: "Hoje … Com o <X>, …"
- Decisions are numbered imperatives with quantities. Each one gets 3–5 sentences: current state, consequence, risk ID, link.
- Trade-offs go in an `Opção | Efeito` table, cost first. Don't recommend when the decision belongs to someone else.
- Use gates, not promises: "só depois de …", then "**Critérios de saída:**".
- Blockers: "Sem X, Y."
- Every obligation names a role. In a RACI, one A per row. Use the columns "Quem garante" and "Evidência".
- Set scope limits: "Não é um SIEM." "Não constitui parecer jurídico."
- Plan vs. reality, without blame:
  - an "Impacto" column
  - "Risco aceite: …"
  - what still holds
  - "Recomendações ao <equipa>:"
- Proposals:
  - anchor in a relationship that already works
  - "Já temos X. Falta Y."
  - mark it "Rascunho para discussão"
- Requests: "**Pedido:** … **Resposta / previsão:** ____".
- The repo is the source of truth. Confluence summarises and links it, and never copies it.
- For non-technical readers: what it is, what it does, why it matters. Use examples from their world (IBAN, NIF, telemóvel).

## Never
- Filler or marketing words: robusto, abrangente, de ponta, sinergia, transformador, em suma, inovador.
- Intro paragraphs that restate the title, or closing summaries.
- Real IPs, hostnames or client names. Mask them, use `192.0.2.0/24`, and use synthetic tenants (`demo-prod`).
