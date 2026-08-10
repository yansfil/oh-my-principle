# Engineering Principles

These principles take precedence over an agent's default behavior.

Examples are written in TypeScript, but the principles are stack-independent. Each example shows the
**shape** of a violation; it does not limit the principle to that case.

## Principles

### 1. Do not preserve backward compatibility

Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.

```ts
// ✗ keeps the old field alongside the new one
return { name: user.name, displayName: user.displayName }

// ✓ update every consumer, then delete the old field
return { displayName: user.displayName }
```

### 2. Choose the simplest implementation that fully meets the current requirements

Avoid speculative abstractions, configuration, and indirection.

```ts
// ✗ one channel today, but the extension point is already open
interface Notifier { send(message: string): Promise<void> }
const notifiers: Record<string, Notifier> = { slack: new SlackNotifier() }
await notifiers[config.channel].send(message)

// ✓
await sendSlack(message)
```

### 3. Grow the system in layers

Start from the smallest version that works end to end, and add each new capability on top of a
product that already works. Never trade a working product for unfinished complexity.

This one is about the order of the work, not the shape of the code.

```text
✗ open list, detail, and checkout at once, and sit for weeks with none of them working
✓ finish list until it ships → add detail on top of it → add checkout on top of that
```

### 4. Surface failures explicitly

Do not cover an invalid state with a default, an empty value, or a silent skip. Raise at the point
of failure. Add a fallback only when that behavior is itself a requirement, never to avoid an error.

```ts
// ✗ covers the failure with an empty value
try { return JSON.parse(raw) } catch { return {} }

// ✗ covers a missing required value — when the key is absent this silently points at a local database
const url = process.env.DATABASE_URL ?? "postgresql://localhost:5432/dev"

// ✓ both raise where the failure happens
return JSON.parse(raw)
const url = requireEnv("DATABASE_URL")
```

### 5. Keep components modular and concerns clearly separated

```ts
// ✗ a view component assembles the query
const rows = useQuery(sql`select * from users where org_id = ${orgId}`)

// ✓ hide it behind a domain function
const rows = useQuery(() => listUsersByOrg(orgId))
```

```ts
// ✗ domain logic knows the transport
function calculateRefund(req: NextRequest) { ... }

// ✓ the domain takes values
function calculateRefund(order: Order, canceledAt: Date) { ... }
```

### 6. Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability

Do not reimplement common functionality without a clear reason.

```ts
// ✗ hand-rolls time zones, leap years, and DST
const [y, m, d] = raw.split("-").map(Number)
const kst = new Date(Date.UTC(y, m - 1, d) + 9 * 3600_000)

// ✓ leave it to an established library
const kst = zonedTimeToUtc(raw, "Asia/Seoul")
```

### 7. Lean on the dependencies already in the project before writing your own implementation or adding packages

Do not assume a library lacks a capability without checking its documentation and types.

```ts
// ✗ zod is already here, but "it probably can't do this" wins and a package is added
import Joi from "joi"

// ✓ check the documentation and types of what is already there
import { z } from "zod"
```

### 8. Make architectural decisions for the long term

Do not accept a stopgap that only works for now and is meant to be replaced later.

```ts
// ✗ "keep it in memory for now, move it to a database later"
const sessions = new Map<string, Session>()

// ✓ if persistence is a requirement, go to the database from the start
await db.insert(sessionsTable).values(session)
```

This does not conflict with #3. You may cut **scope** — ship the list now, add the detail later.
You may not lay a **foundation** you already plan to throw away.

### 9. Log for the questions you will have to answer later

Delete tracing breadcrumbs or drop them to a lower level. Whatever you keep, record as structure
rather than as a sentence, and make it possible to tie back to the request it came from. Record
people by identifier, never by content.

```ts
// ✗ unleveled breadcrumbs — they pile up in production and answer no question
console.log("payment started")
console.log("got here", result)

// ✗ an interpolated sentence — unsearchable, unaggregatable, and it keeps PII and secrets
console.log(`user ${user.email} paid ${amount} with ${card.number}`)

// ✓ keep the trace, but drop the level
logger.debug("payment.request.received", { requestId, orderId })

// ✓ event name + request id + subject id, and none of the content
logger.info("payment.authorized", { requestId, orderId, userId, amount })
```

A log is not handling. Logging an error and continuing violates #4.

### 10. Every failure must be observable from outside the process

Raising is not the end of it. An exception that dies in a background job, a fire-and-forget call that
never lands, a nightly run that touches zero rows and exits clean — every line can obey #4 while the
system fails in silence. Ask it of every failure path: **who finds out, and how?** If the answer needs
someone to read the code or go digging through logs, nobody finds out.

Swallowing is allowed when continuing is the requirement — a notification failure must not block a
payment. It is allowed only when the swallow is itself emitted as an event someone will see.

**Doing nothing successfully is not success.** A run that matched nothing, a filter that removed
everything, a consumer that drained no queue — report it as its own outcome, not as a clean exit.

```ts
// ✗ fire-and-forget — the failure has nowhere to land
void notifyApplicationCreated(input)

// ✗ swallowed, and "recorded" where nobody is looking
try { await notify(input) } catch (e) { console.error(`notify failed: ${e}`) }

// ✓ swallow on purpose, and emit the swallow as an observable event
const result = await notifySafely(input)
if (result.status === "failed") {
  logger.error("notification.failed", { requestId, applicationId, channel: "slack" })
}

// ✗ a clean exit that did nothing
await processPending()

// ✓ the empty outcome is a signal of its own
logger.info("batch.completed", { requestId, processed: count })
```

## Practices

Areas where a principle has concrete enforcement. Read the linked document before touching that area.

- The contract for environment variables lives in code; only the value lives outside.
  → [practices/env.md](practices/env.md)
- A test is worth writing only when its return beats its maintenance cost.
  → [practices/test.md](practices/test.md)
