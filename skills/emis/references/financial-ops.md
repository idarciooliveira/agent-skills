# GPO API – Financial Operations: Detailed Payloads

Base URL: `https://gpo.emis.co.ao/online-payment-gateway/api`

Financial paths below are relative to `/v1/points-of-sale/{posId}`.

## Data models

### Authorization (authorization request)

```json
{
  "amount": 10.23,
  "currency": "AOA",
  "merchantReferenceNumber": "REF-2023-001",
  "orderOrigin": "ECOMMERCE_CARD",
  "paymentInfo": {
    "card": {
      "pan": "4111111111111111",
      "expiryDate": "12/25",
      "cvv": "123",
      "cardholderName": "JOAO SILVA"
    }
  }
}
```

**Or with mobile (MCXExpress):**

```json
{
  "amount": 10.23,
  "currency": "AOA",
  "merchantReferenceNumber": "REF-2023-001",
  "orderOrigin": "ECOMMERCE_MOBILE",
  "paymentInfo": {
    "mobile": {
      "phoneNumber": "911111112"
    }
  }
}
```

**Or with purchase token (WebFrame):**

```json
{
  "amount": 10.23,
  "currency": "AOA",
  "merchantReferenceNumber": "REF-2023-001",
  "orderOrigin": "ECOMMERCE_CARD",
  "paymentInfo": {
    "token": {
      "value": "<purchaseToken>"
    }
  }
}
```

**Or with GPO token (partial authorization):**

```json
{
  "amount": 5.0,
  "currency": "AOA",
  "merchantReferenceNumber": "REF-2023-001",
  "paymentInfo": {
    "token": {
      "value": "<tokenBoundToReference>"
    }
  }
}
```

| Method | Path | Body |
| --- | --- | --- |
| `POST` | `/authorizations` | Authorization (above) |
| `GET` | `/authorizations/{authorizationId}` | — |
| `GET` | `/authorizations?$filter=...&$top=20&$skip=0&$orderBy=...` | — (OData) |

### TransactionResponse

```json
{
  "id": "19661399736156727",
  "status": "APPROVED",
  "amount": 10.23,
  "currency": "AOA",
  "merchantReferenceNumber": "REF-2023-001",
  "authorizationCode": "ABC123",
  "transactionDate": "2023-07-07T10:15:30Z",
  "errorType": null,
  "errorCode": null,
  "errorMessage": null
}
```

**When the processor declines:**

```json
{
  "id": "19661399736156728",
  "status": "DECLINED",
  "errorType": "EPMS_PROCESSOR",
  "errorCode": "810",
  "errorMessage": "Insufficient funds."
}
```

### AuthorizedPayment (capture after authorization)

```json
{
  "amount": 10.23,
  "currency": "AOA"
}
```

`POST /authorizations/{authorizationId}/payments` — amount may be equal to or less than the authorized amount.

### Refund

```json
{
  "amount": 5.0,
  "currency": "AOA",
  "supervisorId": "supervisor-uuid"
}
```

**Or with supervisor card:**

```json
{
  "amount": 5.0,
  "currency": "AOA",
  "supervisorCard": "XXXX-XXXX-XXXX-XXXX"
}
```

| Method | Path |
| --- | --- |
| `POST` | `/authorizations/{authorizationId}/payments/{paymentId}/refunds` |
| `POST` | `/payments/{paymentId}/refunds` (one-shot payment refund) |

Provide exactly one of `supervisorId` or `supervisorCard`.

### Payment (one-shot – MCXExpress only)

```json
{
  "amount": 10.23,
  "currency": "AOA",
  "merchantReferenceNumber": "201812060000001",
  "paymentInfo": {
    "mobile": {
      "phoneNumber": "911111112"
    }
  }
}
```

`POST /payments`

### Cancel authorization

`POST /authorizations/{authorizationId}/cancellations` — empty body or `CancellationRequest`.

### Merchant references

```
GET /merchant-references
GET /merchant-references/{referenceNumber}
```

---

## Business flows

### Base: authorize → capture → refund

```
[Authorize]                     [Capture]                         [Refund]
POST /authorizations     →    POST /authorizations/        POST /payments/
  ↓ authorizationId             {authId}/payments            {payId}/refunds
                                  ↓ paymentId
```

### Partial payments

```
POST /authorizations (full amount)          → authorizationId_1 (e.g. 1000 AOA)
POST /authorizations/{id}/payments (500)    → paymentId_1 (captured 500)
POST /authorizations (token, 500)           → authorizationId_2 (remainder)
POST /authorizations/{id2}/payments (500)   → paymentId_2 (captured 500)
```

### Partial refunds

```
POST /authorizations/{id}/payments/{pid}/refunds (partial amount)
  → May be repeated until the full captured amount is refunded
  → Requires supervisorId or supervisorCard on each request
```

---

## `orderOrigin` values

| Value               | Description                                   |
| ------------------- | --------------------------------------------- |
| `ECOMMERCE_CARD`    | E-commerce with card                          |
| `ECOMMERCE_MOBILE`  | E-commerce with MCXExpress                    |
| `MOTO_CARD`         | Mail Order / Telephone Order with card        |
| `MOTO_MOBILE`       | Mail Order / Telephone Order with MCXExpress  |
| `PRESENTIAL_CARD`   | In-person with card                           |
| `PRESENTIAL_MOBILE` | In-person with MCXExpress                     |

---

## cURL examples

### Authorization

```bash
curl -X POST "https://gpo.emis.co.ao/online-payment-gateway/api/v1/points-of-sale/45/authorizations" \
  -H "accept: application/json" \
  -H "Authorization: Bearer 9720bdc4-22cb-491f-af25-df584bec630a" \
  -H "Content-Type: application/json" \
  -d '{"amount":10.23,"currency":"AOA","merchantReferenceNumber":"REF-001","orderOrigin":"ECOMMERCE_CARD","paymentInfo":{"mobile":{"phoneNumber":"911111112"}}}'
```

### Capture after authorization

```bash
curl -X POST "https://gpo.emis.co.ao/online-payment-gateway/api/v1/points-of-sale/45/authorizations/19661399736156727/payments" \
  -H "accept: application/json" \
  -H "Authorization: Bearer 9720bdc4-22cb-491f-af25-df584bec630a" \
  -H "Content-Type: application/json" \
  -d '{"amount":10.23,"currency":"AOA"}'
```

### Cancellation

```bash
curl -X POST "https://gpo.emis.co.ao/online-payment-gateway/api/v1/points-of-sale/45/authorizations/19521521888500917/cancellations" \
  -H "accept: application/json" \
  -H "Authorization: Bearer 9720bdc4-22cb-491f-af25-df584bec630a"
```
