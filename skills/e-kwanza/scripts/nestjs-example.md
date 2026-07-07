# NestJS integration sketch

Adapt module/provider names to the target project's conventions. This mirrors a typical
`PaymentsModule` with a provider-specific subfolder (`payments/ekwanza/...`), matching a
multi-provider payments architecture with `webhook_events`-style idempotency.

## Config

```ts
// ekwanza.config.ts
export default registerAs("ekwanza", () => ({
  baseUrl: process.env.EKWANZA_BASE_URL,
  notificationToken: process.env.EKWANZA_NOTIFICATION_TOKEN,
  apiKey: process.env.EKWANZA_API_KEY,
  partnerRegistrationNumber: process.env.EKWANZA_PARTNER_REG_NUMBER,
}));
```

## Client service (native e-kwanza API)

```ts
@Injectable()
export class EkwanzaService {
  private readonly http: AxiosInstance;

  constructor(private readonly config: ConfigService) {
    this.http = axios.create({ baseURL: this.config.get("ekwanza.baseUrl") });
  }

  async createTicket(
    amount: number,
    referenceCode: string,
    mobileNumber?: string,
  ) {
    const token = this.config.get("ekwanza.notificationToken");
    const { data } = await this.http.post(`/Ticket/${token}`, null, {
      params: { amount, referenceCode, mobileNumber },
    });
    return data; // { Code, QRCode, Range, Status, ExpirationDate }
  }

  async getTicketStatus(ticketCode: string) {
    const token = this.config.get("ekwanza.notificationToken");
    const { data } = await this.http.get(`/Ticket/${token}/${ticketCode}`);
    return data;
  }

  async sendToCustomer(
    mobileNumber: string,
    amount: string,
    operationCode: string,
  ) {
    const notificationToken = this.config.get("ekwanza.notificationToken");
    const apiKey = this.config.get("ekwanza.apiKey");
    const timestamp = new Date().toISOString();

    const signature = signSendToCustomer({
      apiKey,
      timestamp,
      mobileNumber,
      notificationToken,
      operationCode,
    });

    const { data } = await this.http.post(
      "/Operations/SendToCustomer",
      {
        data: { mobileNumber, token: notificationToken, amount, operationCode },
        meta: { timestamp, signature },
      },
      { headers: { "X-API-Key": apiKey } },
    );
    return data;
  }
}
```

## Webhook controller (payment notification)

```ts
@Controller("webhooks/payments/ekwanza")
export class EkwanzaWebhookController {
  constructor(
    private readonly config: ConfigService,
    private readonly webhookEvents: WebhookEventsService, // idempotency store
    private readonly queue: PaymentsQueue, // e.g. BullMQ producer
  ) {}

  @Post()
  async handle(
    @Headers("x-signature") signature: string,
    @Body()
    body: {
      code: string;
      operationCode: string;
      status: string;
      amount: number;
    },
  ) {
    const valid = verifyPaymentCallbackSignature({
      apiKey: this.config.get("ekwanza.apiKey"),
      code: body.code,
      operationCode: body.operationCode,
      partnerRegistrationNumber: this.config.get(
        "ekwanza.partnerRegistrationNumber",
      ),
      notificationToken: this.config.get("ekwanza.notificationToken"),
      receivedSignature: signature,
    });
    if (!valid) throw new UnauthorizedException("invalid signature");

    // idempotency: dedupe on operationCode/code before enqueueing
    const isNew = await this.webhookEvents.recordIfNew("ekwanza", body.code);
    if (isNew) await this.queue.add("ekwanza-payment-received", body);

    return { status: "0" }; // "I updated my side" (enqueue counts, ack immediately)
  }
}
```

## Notes

- Keep the webhook handler fast — verify signature, dedupe, enqueue, return. Do the
  actual balance/state update in the queue consumer.
- `sendToCustomer`/`sendKwikToCustomer` responses use `status: 0` for success — don't
  confuse with HTTP status. Map the numeric `status` codes from
  `references/api-reference.md` to typed errors in one place (e.g. an
  `EkwanzaErrorCode` enum) rather than re-checking magic numbers at call sites.
- For KWiK payouts, after a `202`/`347` pending response, schedule a status poll
  (`SendKWiKToCustomerStatus`) rather than blocking the request.
