# É-kwanza / pay4all — Full API Reference (v2.7)

Source: "Pagamento Integrado (inclui GPO/GPR) v2.7" — pay4all.

## Contexto

The integrated payment service lets merchants/agents create payment codes for
customers to pay, via API, and get notified by callback when payment succeeds.
API access requires a **notification token** associated with the partner.

---

## 1. Create Payment Code (Ticket)

```
POST /Ticket/{notificationToken}?amount={amount}&referenceCode={referenceCode}&mobileNumber={mobileNumber}
```

### Query params

| Name          | Type    | Required                         |
| ------------- | ------- | -------------------------------- |
| amount        | decimal | yes                              |
| referenceCode | string  | yes                              |
| mobileNumber  | string  | yes, only if a QR code is wanted |

### Responses

**201 Success**

```json
{
  "Code": "{generated code}",
  "QRCode": "{base64 img}",
  "Range": null,
  "Status": 0,
  "ExpirationDate": "{date}"
}
```

**400 Invalid amount** (amount outside allowed range)

```json
{
  "Code": null,
  "Range": { "MaxValue": "{min}", "MinValue": "{max}" },
  "Status": 0
}
```

Note: field names in the source doc list `MaxValue` first with "Montante Mínimo" and
`MinValue` with "Montante Máximo" — verify against the live sandbox response before
relying on which bound is which; the doc's labels are inconsistent.

**400 Invalid notification token**

```json
{ "Code": null, "Range": null, "Status": 36 }
```

**400 Amount not provided**

```json
{ "Code": null, "Range": null, "Status": 1 }
```

**500 Missing parameters**

```json
{ "Code": null, "Range": null, "Status": 1 }
```

---

## 2. Check Payment Code Status

```
GET /Ticket/{notificationToken}/{ticketCode}
```

### Path params

| Name              | Type | Required |
| ----------------- | ---- | -------- |
| ticketCode        | path | yes      |
| notificationToken | path | yes      |

### Responses

**200 Success**

```json
{
  "Amount": "{amount}",
  "Code": "{e-kwanza code}",
  "CreationDate": "{creation date}",
  "ExpirationDate": "{expiration date}",
  "Status": 0
}
```

**404 Not Found**

### Ticket `Status` enum

| Value | Meaning    |
| ----- | ---------- |
| 0     | Pendente   |
| 1     | Processado |
| 2     | Expirado   |
| 3     | Cancelado  |

---

## 3. Payment Notification Callback (you implement this endpoint)

To be notified when a ticket is paid, implement a REST endpoint with this contract:

```
POST {your notification URL}
Headers:
  x-signature: string
```

### Body

```json
{
  "code": "string",
  "operationCode": "string",
  "status": "string",
  "amount": 0.0
}
```

### Your response

| HTTP Status   | Meaning                               | Body                |
| ------------- | ------------------------------------- | ------------------- |
| 200-299       | Success, you updated your side        | `{ "status": "0" }` |
| 200-299       | Success, you did NOT update your side | `{ "status": "1" }` |
| 100-199, 300+ | Not success                           | (any)               |

### Signature validation (`x-signature` header)

HMAC-SHA256, keyed with the merchant's **API Key**. Concatenate, in this order:

1. `code` (received in the ticket-creation response)
2. `operationCode` (the `referenceCode` **you sent** when creating the ticket)
3. Partner registration number (found on the partner's e-kwanza profile, field
   "Nº de registo da empresa")
4. Notification token (found on the merchant's profile)

Compute the same HMAC on your side and compare to `x-signature` to authenticate the
callback before trusting it.

---

## 4. Send Payment to Customer (Wallet)

Debits the partner's eMoney account, credits the customer's e-kwanza wallet.

```
POST /Operations/SendToCustomer
Headers:
  X-API-Key: string
```

### Body

```json
{
  "data": {
    "mobileNumber": "string",
    "token": "string",
    "amount": "string",
    "operationCode": "string"
  },
  "meta": {
    "timestamp": "string",
    "signature": "string"
  }
}
```

### Responses

**200-299 Success**

```json
{
  "ekzOperationCode": "{order number}",
  "ekzTransactionCode": "{transaction number}",
  "status": 0
}
```

| HTTP | status | Meaning                            |
| ---- | ------ | ---------------------------------- |
| 400  | 87     | Invalid amount                     |
| 400  | 180    | Invalid notification token         |
| 400  | 180    | Invalid signature                  |
| 400  | 27     | Invalid phone number               |
| 400  | 31     | Phone number not found             |
| 400  | 29     | Account has no balance             |
| 400  | 36     | Amount above max transaction limit |
| 400  | 37     | Amount below min transaction limit |

### Signature (`meta.signature`)

HMAC-SHA256 keyed with the merchant's API Key, over (in order): `timestamp` +
`mobileNumber` + notification token + `operationCode`.

e-kwanza recomputes this server-side; a mismatch silently rejects the operation.

---

## 5. Send Payment to Customer via KWiK (IBAN)

Debits the partner's eMoney account, credits the given KWiK IBAN.

```
POST /Operations/SendKWiKToCustomer
Headers:
  X-API-Key: string
```

### Body

```json
{
  "data": {
    "IBAN": "string",
    "token": "string",
    "amount": "string",
    "operationCode": "string"
  },
  "meta": {
    "timestamp": "string",
    "signature": "string"
  }
}
```

### Responses

**200 Success**

```json
{
  "ekzOperationCode": "{order number}",
  "ekzTransactionCode": "{transaction number}",
  "status": 0
}
```

**202 Payment pending** — same shape, `"status": 347`. Not an error: poll the status
endpoint (below) until it resolves.

| HTTP | status | Meaning                            |
| ---- | ------ | ---------------------------------- |
| 400  | 32     | KWiK not active                    |
| 400  | 87     | Invalid amount                     |
| 400  | 180    | Invalid notification token         |
| 400  | 180    | Invalid signature                  |
| 400  | 27     | Invalid phone number               |
| 400  | 31     | Phone number not found             |
| 400  | 29     | Account has no balance             |
| 400  | 36     | Amount above max transaction limit |
| 400  | 37     | Amount below min transaction limit |

### Signature (`meta.signature`)

HMAC-SHA256 keyed with the merchant's API Key, over (in order): `timestamp` + `IBAN` +
notification token + `operationCode`.

---

## 6. Get KWiK Payment Status

```
POST /Operations/SendKWiKToCustomerStatus?ExternalReferenceId={id}
Headers:
  X-API-Key: string
```

### Responses (all HTTP 200 unless not found)

```json
{
  "ekzOperationCode": "{order number}",
  "ekzTransactionCode": "{transaction number}",
  "status": 0,
  "OperationStatus": "processed" // or "processing", "cancelled", "voided"
}
```

| OperationStatus | Meaning   |
| --------------- | --------- |
| processed       | Successo  |
| processing      | Pendente  |
| cancelled       | Revertida |
| voided          | Anulada   |

**400 Not found**

```json
{ "status": 1 }
```

---

## 7. Pagamento por Referência e Gateway de Pagamentos Online (GPO) — AppyPay

Two-step flow against the AppyPay gateway (separate from the e-kwanza native API above).

### Step 1 — Authenticate (OAuth2 client credentials)

```
GET https://login.microsoftonline.com/appypaydev.onmicrosoft.com/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
client_id={client_id}
client_secret={client_secret}
resource={resource_id}
```

Returns a bearer token to use in step 2. `client_id`, `client_secret`, and `resource`
are partner-specific — never hardcode the sample values from the source doc, they were
sandbox/example credentials.

### Step 2 — Create a charge

```
POST https://gwy-api-tst.appypay.co.ao/v2.0/charges
Accept: application/json
Content-Type: application/json
Authorization: Bearer {token from step 1}
```

**Referência (EMIS) example body:**

```json
{
  "amount": 10,
  "currency": "AOA",
  "description": "optional description",
  "merchantTransactionId": "unique-id-per-transaction",
  "paymentMethod": "REF_{payment-method-identifier}",
  "options": {
    "MerchantIdentifier": "{e-kwanza merchant account number}",
    "ApiKey": "{e-kwanza-level API key for account mapping}"
  }
}
```

**GPO / Multicaixa Express example body** (adds `paymentInfo.phoneNumber`, and
`paymentMethod` prefixed `GPO_`):

```json
{
  "amount": 10,
  "currency": "AOA",
  "description": "optional description",
  "merchantTransactionId": "unique-id-per-transaction",
  "paymentMethod": "GPO_{payment-method-identifier}",
  "paymentInfo": {
    "phoneNumber": "9XXXXXXXX"
  },
  "options": {
    "MerchantIdentifier": "{e-kwanza merchant account number}",
    "ApiKey": "{e-kwanza-level API key for account mapping}"
  }
}
```

### Field notes

- `paymentMethod`: identifier of the app associated with the payment method
  (`REF_...` or `GPO_...` UUID, provided during onboarding).
- `merchantTransactionId`: must be unique per transaction — use it as your idempotency
  key on your side too.
- `options.MerchantIdentifier` / `options.ApiKey`: map the charge to the merchant's
  e-kwanza account — distinct from the AppyPay OAuth `client_id`/`client_secret`.
- Swap the `-tst` (test) hostname for the production one before going live — the
  production URL isn't in the source doc, confirm with the pay4all/AppyPay contact.

---

## 8. Callback for Referência / GPO (you implement this endpoint)

```
POST {your GPO/Referência notification URL}
```

### Body

```json
{
  "merchantTransactionId": "EKZQA2502121115",
  "ekwanzaTransactionId": 123123,
  "operationStatus": 1,
  "operationData": {
    "amount": 150.0,
    "merchantIdentifier": "66700922",
    "referenceType": "GPO"
  }
}
```

### Your response

Respond `200-299` for success.

### `operationStatus` enum

| Value | Meaning                        |
| ----- | ------------------------------ |
| 1     | Pagamento efetuado com Sucesso |
| 3     | Pagamento Cancelado / Expirado |
| 4     | Pagamento Falhado/Recusado     |
| 5     | Erro                           |

### `referenceType` enum

| Value | Meaning            |
| ----- | ------------------ |
| REF   | Referência EMIS    |
| GPO   | Multicaixa Express |

Note: unlike the native e-kwanza callback, no signature header is documented for this
webhook in the source spec — validate authenticity via a known/expected
`merchantTransactionId` you generated, and confirm with pay4all/AppyPay whether a
signature mechanism exists before treating this endpoint as fully trusted in production.
