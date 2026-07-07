---
name: ekwanza
description: >-
  Integrates the Angolan É-kwanza (pay4all) and AppyPay payment APIs: payment
  tickets and QR codes, ticket status, wallet payouts (e-kwanza and KWiK/IBAN),
  payment webhooks with HMAC-SHA256 x-signature validation, and
  Referência/Multicaixa Express (GPO) charges. Use when the user mentions
  É-kwanza, e-kwanza, pay4all, AppyPay, KWiK, Multicaixa Express, GPO,
  Angolan payments, webhooks, wallet payouts, or payment integration. Consult
  before writing e-kwanza/pay4all clients or signature code — field
  concatenation order is spec-critical.
---

# É-kwanza Payment Integration

This skill packages the É-kwanza / pay4all "Pagamento Integrado v2.7" API so it can be
dropped into any backend (the examples below are NestJS/TypeScript, matching Idarcio's
usual stack, but the same calls work in Express, Fastify, or any other Node backend).

Full endpoint-by-endpoint reference (request/response shapes, HTTP status/error codes)
lives in `references/api-reference.md` — **read it before implementing an endpoint you
haven't built before**, since the status codes and field names are non-obvious (e.g.
`status: "180"` means invalid signature, not a real HTTP concept).

## What this API covers

There are two separate payment families in this doc — don't mix their auth/signing rules up:

1. **É-kwanza native API** (`/Ticket/...`, `/Operations/...`) — authenticated with a
   `notificationToken` (in the URL or body) and an `X-API-Key` header. Used for:
   - Generating a payment code/QR for a customer to pay (`POST /Ticket/{token}`)
   - Checking a ticket's status (`GET /Ticket/{token}/{ticketCode}`)
   - Paying out to a customer's e-kwanza wallet (`POST /Operations/SendToCustomer`)
   - Paying out to a KWiK account via IBAN (`POST /Operations/SendKWiKToCustomer` +
     `.../SendKWiKToCustomerStatus`)
   - Receiving a webhook when a ticket is paid

2. **AppyPay Gateway (GPO)** — OAuth2 client-credentials auth against
   `login.microsoftonline.com`, then `POST /v2.0/charges` on `gwy-api-tst.appypay.co.ao`
   (swap `-tst` for production host when going live). Used for Referência (EMIS) and
   Multicaixa Express (GPO) charges, plus a separate webhook.

## Workflow

1. **Clarify which flow(s) the user needs**: collecting a payment (ticket/QR, or
   Referência/GPO charge) vs. paying money out (SendToCustomer / SendKWiK). Don't build
   all of them unless asked — they have different auth and different NestJS modules.
2. **Read the relevant section** of `references/api-reference.md` for exact request/response
   shapes and status codes before writing code.
3. **Signature generation is the most common source of bugs.** Every write endpoint
   (ticket creation excluded) needs an HMAC-SHA256 signature over specific fields
   _concatenated in a specific order_ — see "Signature rules" below and
   `scripts/signature.ts`. Get this wrong and every call returns a generic 400 with a
   status code that doesn't obviously mean "signature".
4. **Never hardcode credentials** (notification token, API key, client secret) — read
   them from environment variables / config service, matching Idarcio's usual pattern of
   a NestJS `ConfigService` + `.env`.
5. **Webhooks must respond fast and idempotently.** e-kwanza/AppyPay will retry on
   non-2xx. Verify the signature, persist the event (idempotency key = the transaction
   code), then process asynchronously if there's real work to do — this mirrors the
   `webhook_events` + BullMQ pattern already used for other payment providers.
6. Use the code in `scripts/signature.ts` and `scripts/nestjs-examples.md` as a starting
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
| GPO/Referência charge                   | `POST /v2.0/charges` (AppyPay gateway)                                  | OAuth2 Bearer token                                          |
| GPO/Referência callback (you implement) | `POST {your webhook URL}`                                               | none documented — validate via known `merchantTransactionId` |

Full request/response bodies, all documented error `status` codes, and the ticket/operation
status enums are in `references/api-reference.md`.

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
- The AppyPay OAuth token endpoint and charges endpoint shown in the doc are the **test**
  (`-tst`) hosts — confirm the production hostnames with the pay4all/AppyPay integration
  contact before going live, since they aren't in the source doc.
- `mobileNumber` is only required on ticket creation when a QR code is wanted
  ("simQR" in the spec, i.e. conditionally required).
