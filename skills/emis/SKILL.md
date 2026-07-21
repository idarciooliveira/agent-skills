---
name: emis
description: >-
  Integrates EMIS GPO (Gateway de Pagamentos Online) for Angola: OAuth2 auth,
  WebFrame card capture, Multicaixa Express, authorizations/captures/refunds,
  charges/QR, supervisors and terminals. Use when the user mentions EMIS, GPO,
  gpo.emis.co.ao, pagamentonline.emis.co.ao, Multicaixa Express, TPA Express,
  Angolan card payments, authorizations, refunds, WebFrame, EPMS_PROCESSOR, or
  EMIS one-shot mobile payments. Read references before implementing endpoints
  you haven’t built before. Also use when debugging EMIS cash-in Pending,
  processor declines, or mTLS / password-grant token issues.
---

# EMIS GPO Payment Integration

This skill packages the EMIS **GPO** (Gateway de Pagamentos Online) API for Angolan
card and Multicaixa Express payments.

**Documented public base URL:** `https://gpo.emis.co.ao/online-payment-gateway`  
**Documented API version:** v02.80 (2023-07-07)  
**Swagger:** `https://gpo.emis.co.ao/online-payment-gateway/swagger`

**Important:** Some merchant / wallet integrations (including Bulir) call a different
host such as `pagamentonline.emis.co.ao` (often with a non-default port) using
**password grant + client certificates (mTLS)**, not the public OAuth Authorization
Code / WebFrame path. Always read the target project's `EMIS_*` env and token URL
before assuming the public swagger host or OAuth v2 frame flow.

Detailed payloads, OAuth steps, WebFrame params, and error tables live under
`references/` — **read the matching file before implementing an endpoint you haven’t
built before**.

For **wallet / job-orchestrator patterns** (status ports, reconciliation, ledger
clearing), also read the sibling `payment-adapters` skill.

**Do not use this skill for É-kwanza / AppyPay GPO charges** — that is a different
product on `gwy-api.appypay.co.ao`. Use the `ekwanza` skill. The word "GPO" appears
in both and is a common mix-up.

## What this API covers

Two integration families — don’t mix PCI assumptions:

1. **WebFrame (recommended for e-commerce card)** — EMIS iframe captures card data;
   you get a one-time `purchaseToken`, then call REST authorizations. Merchants
   without PCI-DSS certification should use this path.
2. **REST WebServices** — server-to-server calls with Bearer OAuth. Raw card fields
   in the body require PCI-DSS. Multicaixa Express uses `paymentInfo.mobile` (phone
   number) and supports one-shot payments without prior authorization.

Core financial ops (all under `/api/v1/points-of-sale/{posId}/`): authorize → capture
(payment) → refund; cancel authorization; one-shot MCXExpress payment; merchant
reference lookups. Also: charges/QR, supervisors, terminals, merchants, schedules.

### Wallet cash-in subset (most mobile top-ups)

Many wallet backends only implement:

- Token fetch (password grant and/or mTLS, project-specific)
- One-shot `POST .../points-of-sale/{posId}/payments` with `paymentInfo.mobile`
- Status poll / webhook / cron reconciliation

They often **do not** implement WebFrame, authorize→capture, refunds, or charges/QR.
Don’t scaffold the full GPO surface unless asked.

## Workflow

1. **Clarify which flow(s) the user needs**: WebFrame card checkout, MCXExpress
   one-shot, auth→capture, refund (needs supervisor), charges/QR, or management
   (supervisors/terminals). Don’t build everything unless asked.
2. **Confirm host + auth** from the target env (`EMIS_PAYMENT_URL`,
   `EMIS_GET_TOKEN_URL`, certs). Prefer OAuth v2 Authorization Code for greenfield
   e-commerce; treat password-grant + mTLS as a valid production pattern when the
   merchant already uses it.
3. **Read the relevant reference** before coding that area (auth, financial payloads,
   WebFrame, or errors).
4. **Never hardcode credentials** (`client_id`, `client_secret`, merchant password).
   Access tokens expire in ~3600s — refresh with `refresh_token` when using OAuth
   refresh, or re-fetch when using short-lived password-grant tokens.
5. **Use a unique `merchantReferenceNumber` per order.** Never reuse across distinct
   orders; it correlates authorizations, partial payments, and lookups.

## Quick endpoint reference

Prefix financial paths with `/api/v1/points-of-sale/{posId}` unless noted.

| Purpose | Method & path |
| --- | --- |
| OAuth token (v2) | `POST /api/v2/oauth/token` |
| OAuth login frame (v2) | `GET /api/v2/oauth/frame` |
| Frame token (WebFrame) | `GET /api/v1/frame-token` |
| Authorize | `POST .../authorizations` |
| Capture after auth | `POST .../authorizations/{authorizationId}/payments` |
| Refund after capture | `POST .../authorizations/{authorizationId}/payments/{paymentId}/refunds` |
| Cancel authorization | `POST .../authorizations/{authorizationId}/cancellations` |
| One-shot payment (MCXExpress) | `POST .../payments` |
| Refund one-shot | `POST .../payments/{paymentId}/refunds` |
| List / get authorizations | `GET .../authorizations` (OData), `GET .../authorizations/{id}` |
| Merchant references | `GET .../merchant-references`, `GET .../merchant-references/{referenceNumber}` |
| Charges / QR | `POST/GET /api/v1/charges`, `GET /api/v1/charges/{chargeId}/transactions` |
| Supervisors | `POST/GET/PUT /api/v1/supervisors` |
| Terminals | `GET /api/v1/points-of-sale`, `POST .../{posId}/open-close` |
| Merchants | `GET/PUT /api/v1/merchants/{merchantId}` |
| Schedules | `POST/GET/PUT .../schedules` |
| Processor error catalog | `GET /api/v1/errors/processor` |

Full request/response bodies and business flows: `references/financial-ops.md`.

## Production lessons (hard-won)

### Host / auth drift

- Swagger host (`gpo.emis.co.ao`) may differ from the merchant’s live
  `EMIS_PAYMENT_URL`. Always trust the project env.
- Password grant + client certs is common for server-side MCXExpress. Don’t “fix”
  a working integration by rewriting it to Authorization Code without an explicit ask.
- Keep EMIS env vars (`EMIS_*`) separate from É-kwanza / AppyPay GPO vars
  (`E_KWANZA_GPO_*`, `APPY_PAY_*`). Changing the wrong top-up override amount is a
  frequent ops mistake when both rails exist in one monorepo.

### Status / processor declines

- Prefer an explicit status map from EMIS string enums → your port
  (`ACCEPTED` / `REJECTED` / `PENDING` / `UNKNOWN`).
- Processor declines appear on `TransactionResponse` with
  `errorType: EPMS_PROCESSOR` (and related EPMS codes). Treat definitive declines as
  **Rejected / cancel**, not Pending.
- If initiate returns no provider reference, do **not** leave the wallet transaction
  Pending for reconciliation — there is nothing to poll. Cancel as unreconcilable.
- Client / mobile timeouts ≠ EMIS failure. If a provider reference exists, reconcile;
  if not, cancel or mark submission-uncertain per your payment-adapters policy.

### Non-production amount overrides

When a shared non-prod top-up override exists (e.g. `NON_PRODUCTION_TOPUP_AMOUNT`),
use **one** variable for all cash-in rails in the same app. Per-provider override
names cause agents and humans to edit the wrong env while the other rail still
charges the default.

### Cutover checklist

- [ ] `EMIS_*` env present (token URL, payment URL, POS id, merchant ids, certs)
- [ ] Feature / kill-switch and active cash-in policy agree
- [ ] Clearing / ledger seed for EMIS cash-in if the wallet uses provider clearing
- [ ] Cron or webhook path can complete Pending rows that have `extReference`
- [ ] Job path and recon path persist the same provider operation shape

## Gotchas worth flagging to the user

- Send `Authorization: Bearer <access_token>` on every API call; refresh before expiry.
- Refunds require `supervisorId` **or** `supervisorCard` (exactly one).
- One-shot `POST .../payments` is **Multicaixa Express only** — not for card.
- Closed or closing terminals reject financial ops (`TRANSACTIONAL_BLOCKED`).
- HTTP **503** with `OPEN_PENDING_TRANSACTIONS` / `CLOSE_PENDING_TRANSACTIONS`: retry
  after minutes; contact EMIS support if it persists.
- List endpoints support OData (`$filter`, `$orderBy`, `$top`, `$skip`). Dates are
  ISO-8601 (`2023-07-07T10:15:30Z`).
- Only charges with `viewType=QR_CODE` are viewable via the GPO API.
- 4xx errors use `ErrorBody` `{ type, code, message }` — see
  `references/error-codes.md`. Processor declines also appear on
  `TransactionResponse` with `errorType: EPMS_PROCESSOR`.

## Additional resources

- [references/auth-flows.md](references/auth-flows.md) — OAuth v2/v1, refresh, JWT roles
- [references/financial-ops.md](references/financial-ops.md) — payloads, flows, cURL
- [references/webframe.md](references/webframe.md) — Frame Token → purchaseToken
- [references/error-codes.md](references/error-codes.md) — GPO and processor errors
- Sibling skill `payment-adapters` — wallet ports, reconciliation, clearing vocabulary
