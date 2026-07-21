---
name: ekwanza
description: >-
  Integrates the Angolan É-kwanza (pay4all) and AppyPay payment APIs: payment
  tickets and QR codes, ticket status, wallet payouts (e-kwanza and KWiK/IBAN),
  payment webhooks with HMAC-SHA256 x-signature validation, and
  Referência/Multicaixa Express (GPO) charges. Use when the user mentions
  É-kwanza, e-kwanza, pay4all, AppyPay, KWiK, Multicaixa Express, GPO charges,
  Angolan payments, webhooks, wallet payouts, or payment integration. Consult
  before writing e-kwanza/pay4all clients or signature code — field
  concatenation order is spec-critical. Also use when debugging stuck Pending
  charges, FAILED/UNKNOWN KWiK payouts, dual-rail env confusion, or PascalCase
  response parsing.
---

# É-kwanza Payment Integration

This skill packages the É-kwanza / pay4all "Pagamento Integrado v2.7" API so it can be
dropped into any backend (the examples below are NestJS/TypeScript, matching Idarcio's
usual stack, but the same calls work in Express, Fastify, or any other Node backend).

Full endpoint-by-endpoint reference (request/response shapes, HTTP status/error codes)
lives in `references/api-reference.md` — **read it before implementing an endpoint you
haven't built before**, since the status codes and field names are non-obvious (e.g.
`status: "180"` means invalid signature, not a real HTTP concept).

For **wallet / job-orchestrator patterns** (status ports, reconciliation, ledger
clearing, provider keys), also read the sibling `payment-adapters` skill.

## What this API covers

There are two separate payment families — **don't mix their auth, hosts, or env
prefixes**:

1. **É-kwanza native API** (`/Ticket/...`, `/Operations/...`) — authenticated with a
   `notificationToken` (in the URL or body) and an `X-API-Key` header. Used for:
   - Generating a payment code/QR for a customer to pay (`POST /Ticket/{token}`)
   - Checking a ticket's status (`GET /Ticket/{token}/{ticketCode}`)
   - Paying out to a customer's e-kwanza wallet (`POST /Operations/SendToCustomer`)
   - Paying out to a KWiK account via IBAN (`POST /Operations/SendKWiKToCustomer` +
     `.../SendKWiKToCustomerStatus`)
   - Receiving a webhook when a ticket is paid

2. **AppyPay Gateway (GPO)** — OAuth2 client-credentials auth against
   `login.microsoftonline.com`, then `POST /charges` on the AppyPay gateway host.
   Used for Referência (EMIS) and Multicaixa Express (GPO) charges, plus an optional
   separate webhook.

**Production hosts (confirm with integrator; test hosts use `-tst`):**

| Family | Typical host | Env prefix (recommended) |
| --- | --- | --- |
| AppyPay GPO cash-in | `https://gwy-api.appypay.co.ao/v2.0` | `E_KWANZA_GPO_*` or `APPY_PAY_*` |
| Native cash-out / tickets | `https://partnersapi.e-kwanza.ao` | `E_KWANZA_API_*` (+ notification token + API key) |

The AppyPay **gateway host** is not the same product as a legacy "AppyPay adapter"
merchant account. Sharing credentials across those two will silently misroute money.

## Workflow

1. **Clarify which flow(s) the user needs**: collecting a payment (ticket/QR, or
   Referência/GPO charge) vs. paying money out (SendToCustomer / SendKWiK). Don't build
   all of them unless asked — they have different auth and different NestJS modules.
2. **Name the rail first** in code and env: GPO cash-in vs native KWiK cash-out.
   Never reuse one env prefix for both.
3. **Read the relevant section** of `references/api-reference.md` for exact request/response
   shapes and status codes before writing code.
4. **Signature generation is the most common source of bugs.** Every write endpoint
   (ticket creation excluded) needs an HMAC-SHA256 signature over specific fields
   _concatenated in a specific order_ — see "Signature rules" below and
   `scripts/signature.ts`. Get this wrong and every call returns a generic 400 with a
   status code that doesn't obviously mean "signature".
5. **Never hardcode credentials** (notification token, API key, client secret) — read
   them from environment variables / config service, matching Idarcio's usual pattern of
   a NestJS `ConfigService` + `.env`.
6. **Webhooks must respond fast and idempotently** when you implement them.
   e-kwanza/AppyPay will retry on non-2xx. Many production wallets settle GPO/KWiK via
   **polling** instead — if webhooks are unused, document that and wire reconciliation.
7. Use the code in `scripts/signature.ts` and `scripts/nestjs-example.md` as a starting
   point, adapting names/module structure to the target project rather than copy-pasting
   blindly.

## Signature rules (read carefully — order matters)

HMAC-SHA256, keyed with the merchant's **API Key**, over the fields below **concatenated
in this exact order** (no separators mentioned in the spec — concatenate the raw values
in order):

| Endpoint                                                                       | Fields to concatenate (in order)                                                                        |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| Payment notification callback (`x-signature` header, e-kwanza validates yours) | `code` + `operationCode` (partner's `referenceCode`) + partner registration number + notification token |
| `POST /Operations/SendToCustomer` (`meta.signature`)                           | `timestamp` + `mobileNumber` + notification token + `operationCode`                                     |
| `POST /Operations/SendKWiKToCustomer` (`meta.signature`)                       | `timestamp` + `IBAN` + notification token + `operationCode`                                             |

For `SendToCustomer`/`SendKWiKToCustomer`, e-kwanza recomputes the same hash server-side;
if it doesn't match, the operation is silently rejected — this is the #1 thing to check
first when debugging a mysterious failure on those two endpoints.

See `scripts/signature.ts` for a ready-to-adapt implementation.

## Quick endpoint reference

| Purpose                                 | Method & Path                                                           | Auth                                                         |
| --------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------ |
| Create payment code / QR                | `POST /Ticket/{notificationToken}?amount=&referenceCode=&mobileNumber=` | token in path                                                |
| Check ticket status                     | `GET /Ticket/{notificationToken}/{ticketCode}`                          | token in path                                                |
| Payment notification (you implement)    | `POST {your callback URL}`                                              | `x-signature` header from e-kwanza                           |
| Pay to customer wallet                  | `POST /Operations/SendToCustomer`                                       | `X-API-Key` header + body `meta.signature`                   |
| Pay to KWiK/IBAN                        | `POST /Operations/SendKWiKToCustomer`                                   | `X-API-Key` header + body `meta.signature`                   |
| Check KWiK payout status                | `POST /Operations/SendKWiKToCustomerStatus?ExternalReferenceId=`        | `X-API-Key` header                                           |
| GPO/Referência charge                   | `POST /charges` on AppyPay gateway base URL (`…/v2.0`)                  | OAuth2 Bearer token                                          |
| GPO/Referência callback (you implement) | `POST {your webhook URL}`                                               | none documented — validate via known `merchantTransactionId` |

Full request/response bodies, all documented error `status` codes, and the ticket/operation
status enums are in `references/api-reference.md`.

## Production lessons (hard-won)

These mistakes repeatedly caused stuck money, wrong cancels, or false "success" UX.
Treat them as required reading before shipping.

### Dual rail — never collapse identity

- **GPO cash-in** and **native KWiK cash-out** are different HTTP stacks and credential
  sets. One product key in a wallet app can wrap both, but env vars must stay split
  (e.g. `*_GPO_*` vs `*_API_*`).
- AppyPay **gateway host** (`gwy-api.appypay.co.ao`) ≠ AppyPay **merchant adapter**
  credentials used by an older AppyPay-only module.
- Base URL for GPO must be the API root ending in `/v2.0`. The client appends
  `/charges`. If the base URL already ends in `/charges`, you get `…/charges/charges`
  → 404.

### GPO charge status mapping

Live Multicaixa Express charges often return after the customer confirms (or refuses)
on the phone. Map carefully:

| Provider signal | Treat as | App action |
| --- | --- | --- |
| `responseStatus.successful: true` alone | **Not terminal** | Keep pending / poll |
| `responseStatus.status: "Success"` or `code: 100` | Accepted | Credit / complete |
| `successful: false` + `status: "Failed"` (e.g. code `231`, EPMS_940 client refuse) | **Rejected** | Cancel immediately |
| `successful: false` with no recognizable status | Prefer **Rejected** | Do not leave ambiguous Pending with a provider id |
| Network / 5xx / timeout after possible accept | Unknown | Retry or leave reconcilable Pending only if you have a provider reference |

**Rule:** `successful: false` means the charge was **not** accepted for confirmation.
Mapping it to `UNKNOWN` while storing a provider id leaves transactions stuck Pending
until a cron polls — and ops think money is still waiting when the customer already
refused.

Persist structured `raw` / error payloads. Never store `""` as raw — empty string
bypasses `??` fallbacks and blinds debugging.

### KWiK payout status mapping

| Signal | Treat as |
| --- | --- |
| HTTP 200 + `status: 0` | Completed |
| HTTP 202 + `status: 347` | Processing — poll status |
| Known business failure codes (e.g. `27,29,31,32,36,37,87,180`) | Failed — reverse wallet if already debited |
| Ambiguous / transport error | Unknown — **do not reverse** |

Live bodies often use **PascalCase** (`Status`, `EkzOperationCode`, `OperationStatus`).
CamelCase-only parsers produce `NaN` / UNKNOWN for known failures (e.g. destination
not found `31`). Always normalize both casings.

### IBAN

`SendKWiKToCustomer` expects a full Angolan IBAN (`AO06…`). If the app stores BBAN
(21 digits), normalize before signing and sending. Wrong format surfaces as a
destination / validation failure, not a signature error.

### Async semantics

- Client / mobile HTTP timeouts are **not** payment outcomes. GPO may still settle;
  keep Pending + reconcile when a provider reference exists.
- HTTP 201 / audit "SUCCESS" / "withdrawal accepted" often means **wallet debit
  accepted for dispatch**, not that KWiK paid the bank yet.
- Don't reverse or show "failed" on UNKNOWN — reverse only on definitive FAILED.

### Cutover checklist (before flipping a rail live)

- [ ] Env for that rail only (GPO vs native) present in the target environment
- [ ] Provider / policy key consistent end-to-end (registry, `extProvider`, recon filter,
      kill-switch — avoid `E_KWANZA` vs `E_KWANZA_PAYMENT` drift)
- [ ] Ledger / clearing accounts seeded for the direction (cash-in and/or withdraw)
- [ ] Admin UI / allowlists unlocked if ops must select the provider
- [ ] Job path and reconciliation path both update the same operation record
- [ ] Tax / domain events fire on **settle** paths, not only on admin confirm when
      settlement is polling-based

## Gotchas worth flagging to the user

- Ticket status `0/1/2/3` (Pendente/Processado/Expirado/Cancelado) is a **different**
  enum from operation `status: 0` in the SendToCustomer/SendKWiK responses — success is
  `status: 0` there, but a ticket in state `0` just means "still pending payment".
  Don't conflate them in code or in a shared `PaymentStatus` type.
- `SendKWiKToCustomer` can return `202` with `status: 347` (pendente) — this is not an
  error, it means poll `SendKWiKToCustomerStatus` until `OperationStatus` settles to
  `processed`, `cancelled`, or `voided`.
- GPO's own `operationStatus` in its callback (`1/3/4/5`) is yet another distinct enum
  (Sucesso/Cancelado-Expirado/Falhado/Erro) — again, don't reuse the ticket or
  SendToCustomer enums for it.
- The AppyPay OAuth token endpoint and charges endpoint shown in older docs are often
  **test** (`-tst`) hosts — confirm production hostnames with the pay4all/AppyPay
  integration contact before going live.
- `mobileNumber` is only required on ticket creation when a QR code is wanted
  ("simQR" in the spec, i.e. conditionally required).

## Additional resources

- [references/api-reference.md](references/api-reference.md) — payloads, status codes
- [scripts/signature.ts](scripts/signature.ts) — HMAC field order helpers
- [scripts/nestjs-example.md](scripts/nestjs-example.md) — Nest wiring sketch
- Sibling skill `payment-adapters` — wallet ports, reconciliation, clearing vocabulary
