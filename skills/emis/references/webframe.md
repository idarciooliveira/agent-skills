# GPO API – WebFrame Integration

WebFrame is the recommended e-commerce path for card payments. EMIS provides an iframe
that captures card data securely so the merchant never handles raw PCI-DSS card fields.

Base URL: `https://gpo.emis.co.ao/online-payment-gateway`

## End-to-end flow

```
1. Merchant → GPO: Request Frame Token
2. GPO → Merchant: Return frameToken
3. Merchant → Customer browser: Render iframe with frameToken
4. Customer browser: Enter card data in the frame
5. Frame → GPO: Validate and create purchase token
6. GPO → Merchant (callback): Return purchaseToken
7. Merchant → GPO (REST): POST /authorizations with purchaseToken
```

---

## Step 1 – Frame Token

Temporary token that authenticates the card-capture session.

```
GET https://gpo.emis.co.ao/online-payment-gateway/api/v1/frame-token
Authorization: Bearer <access_token>
```

### Frame URL parameters (manual table 1)

| Parameter                 | Required | Type      | Description                                      |
| ------------------------- | -------- | --------- | ------------------------------------------------ |
| `frameToken`              | Yes      | String    | Token from the previous step                     |
| `amount`                  | Yes      | Decimal   | Amount to authorize                              |
| `currency`                | Yes      | String(3) | ISO-4217 code (e.g. `AOA`)                       |
| `merchantReferenceNumber` | Yes      | String    | Unique merchant reference                        |
| `orderOrigin`             | Yes      | String    | Operation type (e.g. `ECOMMERCE_CARD`)           |
| `language`                | No       | String    | Frame language (e.g. `pt`, `en`)                 |
| `callbackUrl`             | Yes      | String    | Merchant URL that receives `purchaseToken`       |
| `cancelUrl`               | No       | String    | Redirect URL if the customer cancels             |

**Frame render URL:**

```
https://gpo.emis.co.ao/online-payment-gateway/webframe?frameToken=<token>&amount=...&currency=AOA&...
```

---

## Step 2 – Purchase token (`purchaseToken`)

After the customer submits card data, GPO posts `purchaseToken` to `callbackUrl`.

**Possible errors during the process (manual table 2):**

| Code                  | Description                                          |
| --------------------- | ---------------------------------------------------- |
| `FRAME_TOKEN_EXPIRED` | Frame token expired — request a new frame token      |
| `FRAME_TOKEN_INVALID` | Invalid frame token                                  |
| `CARD_DATA_INVALID`   | Invalid card data entered by the customer            |
| `CARD_NOT_SUPPORTED`  | Unsupported card type                                |
| `OPERATION_CANCELLED` | Customer cancelled the operation                     |

---

## Step 3 – Purchase operation

With the received `purchaseToken`, authorize via REST:

```
POST /api/v1/points-of-sale/{posId}/authorizations
Authorization: Bearer <access_token>
Content-Type: application/json

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

---

## Communication security

- All traffic must use **TLS/HTTPS**
- `callbackUrl` must be an HTTPS endpoint on the merchant side
- Validate callback authenticity against the original `frameToken`
- `purchaseToken` is single-use — expire after use or timeout

---

## WebFrame screens

The frame shows the customer:

1. Card data form (number, expiry, CVV)
2. Payment confirmation
3. Result (approved / declined)

The merchant never receives raw card data.
