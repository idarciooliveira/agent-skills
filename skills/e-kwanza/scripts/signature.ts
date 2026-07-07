/**
 * HMAC-SHA256 signature helpers for the É-kwanza API.
 *
 * All three signing rules concatenate their fields RAW (no separators) in a fixed
 * order, then HMAC-SHA256 the result keyed with the merchant's API Key.
 * See references/api-reference.md sections 3, 4, and 5 for the field order per endpoint.
 *
 * Adapt freely — this is a starting point, not a package to import as-is.
 */

import { createHmac, timingSafeEqual } from "crypto";

/** Core signer: HMAC-SHA256(apiKey, concatenatedFields), hex-encoded. */
export function signEkwanza(apiKey: string, fields: string[]): string {
  return createHmac("sha256", apiKey).update(fields.join("")).digest("hex");
}

/**
 * Signature for the payment notification callback's `x-signature` header.
 * Order: code, operationCode (the referenceCode you originally sent), partner
 * registration number, notification token.
 */
export function signPaymentCallback(params: {
  apiKey: string;
  code: string;
  operationCode: string;
  partnerRegistrationNumber: string;
  notificationToken: string;
}): string {
  const {
    apiKey,
    code,
    operationCode,
    partnerRegistrationNumber,
    notificationToken,
  } = params;
  return signEkwanza(apiKey, [
    code,
    operationCode,
    partnerRegistrationNumber,
    notificationToken,
  ]);
}

/**
 * Signature for `meta.signature` on POST /Operations/SendToCustomer.
 * Order: timestamp, mobileNumber, notificationToken, operationCode.
 */
export function signSendToCustomer(params: {
  apiKey: string;
  timestamp: string;
  mobileNumber: string;
  notificationToken: string;
  operationCode: string;
}): string {
  const { apiKey, timestamp, mobileNumber, notificationToken, operationCode } =
    params;
  return signEkwanza(apiKey, [
    timestamp,
    mobileNumber,
    notificationToken,
    operationCode,
  ]);
}

/**
 * Signature for `meta.signature` on POST /Operations/SendKWiKToCustomer.
 * Order: timestamp, IBAN, notificationToken, operationCode.
 */
export function signSendKwikToCustomer(params: {
  apiKey: string;
  timestamp: string;
  iban: string;
  notificationToken: string;
  operationCode: string;
}): string {
  const { apiKey, timestamp, iban, notificationToken, operationCode } = params;
  return signEkwanza(apiKey, [
    timestamp,
    iban,
    notificationToken,
    operationCode,
  ]);
}

/**
 * Verify an inbound `x-signature` header from the payment notification callback.
 * Uses a constant-time comparison to avoid timing side-channels.
 */
export function verifyPaymentCallbackSignature(params: {
  apiKey: string;
  code: string;
  operationCode: string;
  partnerRegistrationNumber: string;
  notificationToken: string;
  receivedSignature: string;
}): boolean {
  const expected = signPaymentCallback(params);
  const a = Buffer.from(expected, "hex");
  const b = Buffer.from(params.receivedSignature, "hex");
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}
