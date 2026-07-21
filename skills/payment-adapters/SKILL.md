---
name: payment-adapters
description: >-
  Designs and debugs wallet payment adapter orchestration for Angolan cash-in
  and cash-out rails (EMIS, É-kwanza GPO, É-kwanza KWiK, AppyPay, sandbox,
  manual bank transfer). Use when the user mentions PaymentProcessor,
  CashInProvider, ProviderOperation, PAYMENT_PROVIDERS, reconciliation cron,
  stuck Pending top-ups, UNKNOWN vs REJECTED, providerRef, PROVIDER_CLEARING,
  escrow vs clearing vs float, kill-switches, or non-production top-up amounts.
  Complements the emis and ekwanza vendor API skills — read those for HTTP
  payloads; use this skill for status ports, dual-rail identity, cutover, and
  ledger invariants.
---

# Payment Adapters (Wallet Orchestration)

Vendor skills (`emis`, `ekwanza`) document **HTTP APIs**. This skill documents
**how a wallet backend should wrap them**: ports, status routing, reconciliation,
identity keys, ledger clearing, and cutover checklists.

Learned from production Bulir / similar wallet integrations in Angola (2025–2026).
Apply the rules even when product names differ.

## When to use which skill

| Question | Skill |
| --- | --- |
| EMIS authorize / MCXExpress / WebFrame payloads | `emis` |
| É-kwanza Ticket / KWiK signature / AppyPay `/charges` | `ekwanza` |
| Stuck Pending, cancel vs reconcile, dual env, clearing seeds | **this skill** |

## Architecture rules

1. **Providers are rails, not the wallet.** The app is custodian of customer
   balances. External systems move money in/out; they do not own ledger truth.
2. **No live failover.** Feature flags are kill-switches. Policy selects the
   active cash-in and cash-out rail. If the active rail is down, fail closed —
   do not silently try another provider.
3. **One provider key end-to-end.** Policy key = registry key = `extProvider` /
   operation.provider = reconciliation filter. Kill-switch names may differ
   slightly (e.g. policy `E_KWANZA`, flag `E_KWANZA_PAYMENT`) — document the
   mapping explicitly and never invent a third string.
4. **Dual-rail products need dual env.** É-kwanza often means:
   - GPO / AppyPay host for **cash-in** (`…_GPO_*`)
   - Native partners API for **KWiK cash-out** (`…_API_*`)
   Sharing prefixes causes wrong amounts, 404s, and “mixed credentials” incidents.
5. **"GPO" is ambiguous.** It can mean EMIS GPO, AppyPay GPO (É-kwanza charges),
   or colloquial Multicaixa Express. Always name the host and env prefix.

## Recommended ports

Normalize provider responses into small enums so the processor stays boring.

**Cash-in:** `ACCEPTED` | `REJECTED` | `PENDING` | `UNKNOWN`  
**Cash-out:** `COMPLETED` | `FAILED` | `PROCESSING` | `UNKNOWN`

Idempotency keys (examples that work well):

- Cash-in: `cash-in:{transactionId}`
- Withdraw: `withdrawal:{transactionId}` (also useful as provider external reference)

## Cash-in status routing

| Adapter status | Provider reference? | Outcome |
| --- | --- | --- |
| `ACCEPTED` | — | Complete + credit wallet |
| `PENDING` or `UNKNOWN` | yes | Leave Pending; reconcile later |
| `PENDING` or `UNKNOWN` | **no** | **Cancel** (unreconcilable) |
| `REJECTED` | — | Cancel + notify failure |

### Mapping footguns

- **`successful: true` alone is not accepted** on AppyPay GPO. Prefer terminal
  `Success` / success code (`100`) / accepted payment status.
- **`successful: false` / `Failed` / client refuse (e.g. 231, EPMS_940) → `REJECTED`.**
  Never map these to `UNKNOWN` while storing a provider id — that traps Pending.
- Persist structured error/raw JSON. Never persist `""` as raw (breaks `??` fallbacks).
- Client HTTP timeout ≠ provider failure. If a provider id exists, reconcile;
  if retries exhaust without a reference, mark submission-uncertain or cancel per
  product policy — do not pretend the payment is still confirmable.

## Cash-out status routing

| Signal | Outcome |
| --- | --- |
| Definitive success | `COMPLETED` — settle, tax, notify |
| Definitive business failure | `FAILED` — reverse wallet debit if already taken |
| Accepted async (e.g. KWiK 202 / 347) | `PROCESSING` — poll |
| Transport / parse ambiguity | `UNKNOWN` — **do not reverse** |

### Settlement modes

- **MANUAL:** admin confirm settles in one step.
- **POLLING:** admin confirm only **approves**; a dispatcher / lease claims the
  operation, calls the provider, then cron reconciles to COMPLETED/FAILED.

Tax and domain events must fire on **settle** paths (dispatch completed +
reconcile), not only on the confirm-Completed path.

Parse **PascalCase and camelCase** on native É-kwanza bodies
(`Status`, `EkzOperationCode`). CamelCase-only parsers turn known failures into
UNKNOWN.

Normalize Angolan IBAN to full `AO06…` before KWiK send if storage is BBAN.

## Reconciliation

Typical safe defaults:

- Interval: every **5 minutes**
- Min age: **2 minutes** (avoid racing the initiating job)
- Require `extReference` / providerRef — skip otherwise
- Batch size capped (e.g. 50)

Both the **payment job** and the **cron** must upsert the same
`ProviderOperation` (or equivalent) status. Divergent paths leave ops
`SUBMITTED` forever after the transaction already Completed/Cancelled.

## Ledger vocabulary

Do not collapse these concepts:

| Term | Meaning |
| --- | --- |
| **Escrow** | Booking / job hold of customer funds |
| **Provider clearing** | In-transit balance for a rail + direction (cash-in or withdraw) |
| **Merchant float** | Net funds at the provider (e.g. É-kwanza CASH_IN − WITHDRAW) |

Cash-in clearing does **not** automatically go to zero when the user withdraws on
another rail. Seed `PROVIDER_CLEARING` (or equivalent) for **each** direction
before enabling that rail — missing seeds cause “charge succeeded, settle
cancelled” incidents.

## Non-production top-up overrides

Use **one** shared env var for reduced cash-in amounts in non-prod
(e.g. `NON_PRODUCTION_TOPUP_AMOUNT`). Per-provider override names cause humans
and agents to edit EMIS while É-kwanza still charges the default (or vice versa).

Preserve **requested vs charged** in transaction metadata. Credit policy must be
explicit (credit requested vs credit charged).

Restart the API after env changes — Nest `EnvService` does not hot-reload.

## Cutover checklist

Before flipping a rail live:

- [ ] Env for that rail only (correct prefix / host)
- [ ] DB allowlists / CHECKs include the provider key
- [ ] Admin UI options include the provider if ops select it
- [ ] Kill-switch + active policy agree
- [ ] Clearing accounts seeded for the direction(s)
- [ ] Job + reconcile paths update the same operation record
- [ ] Tax / notifications on settle paths
- [ ] Fixture tests: terminal fail → REJECTED/FAILED; no providerRef → cancel;
      PascalCase parse; no double URL path; IBAN normalize

## Debugging cheat sheet

| Symptom | Likely cause |
| --- | --- |
| Pending forever after customer refused | Terminal fail mapped to UNKNOWN + providerRef |
| Pending forever, no extReference | Left Pending without providerRef |
| Charge OK, wallet not credited | Missing clearing seed / settle cancelled |
| `…/charges/charges` 404 | Base URL already includes `/charges` |
| Wrong amount still 10 / 100 | Edited wrong override env; API not restarted |
| KWiK `status=NaN` | PascalCase body not parsed |
| Ops thinks payout done | Confused debit-accepted with COMPLETED |
| Wrong KPI on “clearing” | Escrow / clearing / float confused |

## Related skills

- `emis` — EMIS GPO vendor API
- `ekwanza` — É-kwanza native + AppyPay GPO vendor API
