# GPO API – Error Reference

Base URL: `https://gpo.emis.co.ao/online-payment-gateway/api`

4xx API errors return an `ErrorBody`. Processor declines may also appear on
`TransactionResponse` with `errorType = EPMS_PROCESSOR`.

## Request errors (HTTP 400 / 404 / 409)

| Type            | Code                     | HTTP | Description                                                                 |
| --------------- | ------------------------ | ---- | --------------------------------------------------------------------------- |
| INVALID_REQUEST | BODY                     | 400  | Request body invalid. See `message`.                                        |
| INVALID_REQUEST | QUERY_PARAMS             | 400  | Invalid query parameters. See `message`.                                    |
| INVALID_REQUEST | HEADER_PARAMS            | 400  | Invalid headers. See `message`.                                             |
| INVALID_REQUEST | PATH_PARAMS              | 400  | Invalid path parameters. See `message`.                                     |
| INVALID_REQUEST | PAYMENT_INFO             | 400  | Payment data missing or duplicated (e.g. card + mobile in the same request). |
| INVALID_REQUEST | CURRENCY                 | 400  | Invalid currency code (must be ISO-4217, e.g. AOA).                          |
| INVALID_REQUEST | REFERENCE_NUMBER         | 400  | Merchant reference already exists in GPO.                                   |
| INVALID_REQUEST | RESOURCE                 | 404  | Indicated resource (posId, merchantId, transactionId, etc.) does not exist. |
| INVALID_REQUEST | DUPLICATED_RESOURCE      | 409  | Resource already exists and cannot be reinserted without deleting it first. |
| INVALID_REQUEST | MISSING_SUPERVISOR       | 400  | Provide `supervisorId` or `supervisorCard` (exactly one).                   |
| INVALID_REQUEST | DUPLICATED_SUPERVISOR    | 400  | Both `supervisorId` and `supervisorCard` sent — send only one.              |
| INVALID_REQUEST | INVALID_GRANT_TYPE       | 400  | Invalid grant type on the authentication request.                           |
| INVALID_REQUEST | INVALID_CHARGE_VIEW_TYPE | 400  | Only charges with `viewType=QR_CODE` can be viewed.                         |
| INVALID_REQUEST | CURRENCY_NOT_ALLOWED     | 400  | Currency not allowed for this merchant/terminal.                             |
| INVALID_REQUEST | INVALID_USER             | 400  | User not registered in the authorization system (Keycloak).                 |
| INVALID_REQUEST | INVALID_DEVICE_STATUS    | 400  | Device status incompatible with the operation.                              |
| INVALID_REQUEST | ACTIVE_DEVICE_SESSION    | 400  | Device has an active session — operation blocked until it ends.             |
| INVALID_REQUEST | INVALID_USER_ATTRIBUTE   | 400  | User attribute has an invalid value.                                        |
| INVALID_REQUEST | CONCURRENCY_ERROR        | 409  | GPO could not update data — retry later.                                    |

## Authorization errors (HTTP 401)

| Type          | Code           | Message                                | Description                                                              |
| ------------- | -------------- | -------------------------------------- | ------------------------------------------------------------------------ |
| AUTHORIZATION | NOT_AUTHORIZED | Not authorized.                        | Token missing permissions, expired, or absent. Renew via `refresh_token`. |
| AUTHORIZATION | MISSING_TOKEN  | Please provide compliant bearer token. | `Authorization: Bearer` header not sent.                                 |
| AUTHORIZATION | INVALID_TOKEN  | Invalid bearer token format.           | Header present but malformed.                                            |

## System errors (HTTP 500)

| Type         | Code                | Description                                         |
| ------------ | ------------------- | --------------------------------------------------- |
| SYSTEM_ERROR | GENERAL_ERROR       | Internal GPO error. Contact EMIS support.           |
| SYSTEM_ERROR | COMMUNICATION_ERROR | Internal communication error. Contact EMIS support. |

## GPO business errors (HTTP 400 / 403 / 503)

| Type     | Code                                            | HTTP | Description                                                                                                                          |
| -------- | ----------------------------------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------ |
| BUSINESS | CLOSE_IN_PROGRESS                               | 403  | Terminal close already in progress — wait for completion.                                                                            |
| BUSINESS | TRANSACTIONAL_BLOCKED                           | 403  | Terminal closed or closing — does not accept financial transactions.                                                                 |
| BUSINESS | DELETE_SUPERVISOR_FORBIDDEN                     | 403  | Cannot delete a supervisor in use or with status ≠ UNKNOWN.                                                                          |
| BUSINESS | SUPERVISOR_VALIDATION_TERMINAL                  | 403  | Supervisor creation transaction incompatible with current terminal state.                                                            |
| BUSINESS | CLOSE_PENDING_TRANSACTIONS                      | 503  | Cannot close terminal with in-flight transactions. Retry after an interval.                                                          |
| BUSINESS | OPEN_PENDING_TRANSACTIONS                       | 503  | Cannot open terminal with pending transactions (internal reversals). Retry after minutes; contact support if it persists.            |
| BUSINESS | INVALID_PAYMENT_TOKEN                           | 400  | Payment token does not match the indicated merchant reference.                                                                       |
| BUSINESS | INVALID_PARTIAL_AUTHORIZATION                   | 400  | Reference is not in a state that allows partial authorization (e.g. full auth already exists).                                        |
| BUSINESS | INVALID_AUTHORIZATION_AMOUNT                    | 400  | Partial authorization amount exceeds what the customer authorized.                                                                   |
| BUSINESS | TRANSACTION_ALREADY_PROCESSED                   | 400  | Authorization already captured or cancelled — cannot be processed again.                                                             |
| BUSINESS | PAYMENT_AMOUNT_BIGGER_THAN_AUTHORIZATION_AMOUNT | 400  | Capture amount exceeds the authorized amount.                                                                                         |
| BUSINESS | INVALID_TRANSACTION_TYPE                        | 400  | Parent transaction is not the correct type for the requested operation.                                                              |
| BUSINESS | INVALID_STATE_PARENT_TRANSACTION                | 400  | Parent authorization already processed — cannot be captured/cancelled.                                                               |
| BUSINESS | INVALID_SUPERVISOR                              | 400  | Terminal has no associated supervisorId — provide a valid supervisorId.                                                              |
| BUSINESS | NO_SUPERVISOR                                   | 400  | Terminal has no associated supervisor.                                                                                               |
| BUSINESS | PROCESSOR_TIMEOUT                               | 503  | Timeout talking to the processor. Retry.                                                                                             |
| BUSINESS | ESTABLISHMENT_INACTIVE                          | 403  | Establishment inactive in GPO.                                                                                                         |
| BUSINESS | POS_INACTIVE                                    | 403  | Terminal inactive.                                                                                                                   |

## Processor errors

Processor errors are returned on `TransactionResponse` with `errorType = EPMS_PROCESSOR`.
For the up-to-date processor code list:

```
GET /api/v1/errors/processor
Authorization: Bearer <access_token>
Accept-Language: en (optional — default is the gateway-configured language)
```

Common examples: `Insufficient funds`, `Card blocked`, `Invalid card number`.

If you receive a code not listed by that endpoint, contact EMIS support for configuration.

## ErrorBody shape

```json
{
  "type": "INVALID_REQUEST",
  "code": "REFERENCE_NUMBER",
  "message": "Requested merchant reference number already exists."
}
```

For processor errors, `TransactionResponse` also includes:

```json
{
  "errorType": "EPMS_PROCESSOR",
  "errorCode": "810",
  "errorMessage": "Insufficient funds."
}
```
