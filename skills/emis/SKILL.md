---
name: emis
description: >-
  Integrates EMIS GPO (Gateway de Pagamentos Online) for Angola: OAuth2 auth,
  WebFrame card capture, Multicaixa Express, authorizations/captures/refunds,
  charges/QR, supervisors and terminals. Use when the user mentions EMIS, GPO,
  gpo.emis.co.ao, Multicaixa Express, TPA Express, Angolan card payments,
  authorizations, refunds, or WebFrame integration. Read references before
  implementing endpoints you haven’t built before.
---

# EMIS GPO Payment Integration

This skill packages the EMIS **GPO** (Gateway de Pagamentos Online) API for Angolan
card and Multicaixa Express payments. Use it when implementing or debugging clients
against `gpo.emis.co.ao`.

**Production base URL:** `https://gpo.emis.co.ao/online-payment-gateway`  
**Documented API version:** v02.80 (2023-07-07)  
**Swagger:** `https://gpo.emis.co.ao/online-payment-gateway/swagger`

Detailed payloads, OAuth steps, WebFrame params, and error tables live under
`references/` — **read the matching file before implementing an endpoint you haven’t
built before**.

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

## Workflow

1. **Clarify which flow(s) the user needs**: WebFrame card checkout, MCXExpress
   one-shot, auth→capture, refund (needs supervisor), charges/QR, or management
   (supervisors/terminals). Don’t build everything unless asked.
2. **Prefer OAuth v2** (Authorization Code). Treat v1 offline token as legacy /
   being discontinued — see `references/auth-flows.md`.
3. **Read the relevant reference** before coding that area (auth, financial payloads,
   WebFrame, or errors).
4. **Never hardcode credentials** (`client_id`, `client_secret`, merchant password).
   Access tokens expire in ~3600s — refresh with `refresh_token`.
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
