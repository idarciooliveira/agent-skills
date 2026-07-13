# GPO API – OAuth 2.0 Authentication Flows

Base URL: `https://gpo.emis.co.ao/online-payment-gateway`

GPO uses **Keycloak** as the authorization server (Auth Server).

## Flow 1 – Authorization Code (v2 – recommended)

### Step 1: Render the login frame

Embed the GPO login page so the merchant user can authenticate:

```
GET https://gpo.emis.co.ao/online-payment-gateway/api/v2/oauth/frame
```

**Query parameters (manual table 3):**

| Parameter       | Required | Description                          |
| --------------- | -------- | ------------------------------------ |
| `client_id`     | Yes      | Public application ID                |
| `redirect_uri`  | Yes      | URL that receives the auth code      |
| `response_type` | Yes      | `"code"`                             |
| `scope`         | Yes      | Requested scopes (e.g. `gpo-scope`)  |

### Step 2: Receive redirect with code

After login, GPO redirects to `redirect_uri` with:

| Parameter       | Type   | Description                |
| --------------- | ------ | -------------------------- |
| `code`          | String | Temporary authorization code |
| `session_state` | String | Session state              |

### Step 3: Exchange code for access token

```
POST https://gpo.emis.co.ao/online-payment-gateway/api/v2/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=password
&client_id=<client_id>
&client_secret=<client_secret>
&code=<code_from_step_2>
&password=<merchant_password>
```

**Response fields (manual table 6):**

| Field           | Type         | Description                                |
| --------------- | ------------ | ------------------------------------------ |
| `access_token`  | String       | Bearer token for API calls                 |
| `refresh_token` | String       | Token used to renew `access_token`         |
| `expires_in`    | int          | Lifetime in seconds (typically 3600)       |
| `token_type`    | String       | `"bearer"`                                 |
| `id_token`      | String (JWT) | JWT with merchant information              |

### Step 4: Use the access token

```
Authorization: Bearer <access_token>
```

---

## Flow 2 – Offline / Client Credentials (v1 – legacy)

Offline mode: the application holds merchant credentials without a login iframe.

```
POST https://gpo.emis.co.ao/online-payment-gateway/api/v1/token
Content-Type: application/json

{
  "client_id": "9e7a492e-38df-41b6-b6bb-49c9ee401653",
  "client_secret": "wBAiHA5N/xQ6GlSMIu8mQWMomBWUWUxdwBJa2RIm/BM=",
  "user_email": "comerciante@emis.co.ao"
}
```

> **Warning:** The returned token stays **inactive** until the merchant visits the Auth
> Server and grants permission manually. The merchant must notify the integrator after
> granting access.

This flow will be **discontinued**. Migrate to v2.

---

## Flow 3 – Refresh token

Renew `access_token` without a full login:

```
POST https://gpo.emis.co.ao/online-payment-gateway/api/v2/oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&client_id=<client_id>
&client_secret=<client_secret>
&refresh_token=<refresh_token>
```

---

## JWT format (`id_token`)

The `id_token` JWT includes merchant claims such as:

- `userId` – internal user ID
- `name` – merchant name
- `email` – merchant email
- `permissions` – permissions by role (`TPA_MANAGER`, `TPA_ADMIN`, `GPO_ADMIN`, `TPA_OPERATOR`, `MMT`)
- `resources` – accessible resources (terminals)
- `group_ids` – merchant group IDs
- `restricted` – whether the token is restricted

**Main roles:**

| Role           | Permissions                                      |
| -------------- | ------------------------------------------------ |
| `GPO_ADMIN`    | All permissions                                  |
| `TPA_ADMIN`    | Full terminal + user management                  |
| `TPA_MANAGER`  | Transactions, operator user management           |
| `TPA_OPERATOR` | Transactions and terminal info                   |
| `MMT`          | Transaction creation only                        |

---

## Migrating credentials v1 → v2

Integrators moving from v1 to v2 should:

1. Contact EMIS for new credentials: `client_id`, `client_secret`, and `password`
2. Point authentication at the v2 token endpoint
3. Implement Authorization Code (login frame) or an EMIS-approved offline path
