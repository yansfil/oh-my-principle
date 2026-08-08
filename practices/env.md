# Environment Variables

## Principle

The contract for environment variables lives in code. The only thing that lives outside code is the value.

How many keys the app reads, what shape each one has, and what happens when one is missing — code must be
able to answer all of it. What lives outside code (a deployment dashboard, a local `.env`, a CI secret) is
**one value per key**, and nothing else.

## Enforcement

### 1. One registry is the single source of truth

Declare every key the app reads in one place. Register a key there before using it anywhere else.
For each key, record:

| Field | Meaning |
| --- | --- |
| Requirement | The app cannot boot without it (required), or only one feature degrades (optional) |
| Shape | The validator that decides whether a value is usable |
| Fallback | What the code actually uses when the value is absent (optional keys only) |
| Note | **What happens when this key is missing** |
| Scope | Server-only, or reaching the client (only when there is more than one boundary) |

The registry must be **enumerable at runtime.** Most of the enforcement below rests on "walk every
registered key," and without enumeration those checks fall back to a human keeping two lists in sync,
which always drifts.

Do not fill the note field mechanically. Not "API key," but "sends the payment confirmation email;
without it delivery is skipped and payment approval still goes through." It is the only evidence the
next person has when deciding whether the key can be deleted.

### 2. Code reads environment variables only through the registry

Keep raw access — `process.env.X`, `os.environ["X"]` — out of application code. The only exception is
keys the runtime injects on its own (`NODE_ENV` and friends), and that exception list belongs in code too.

Once raw access is allowed, the registry stops being a source of truth and becomes documentation.
A typo in a key name turns into a silent empty value, unregistered keys creep in, and nobody can answer
what has to be set at deploy time.

**Add a test that scans the source for raw access and fails on any key that is not registered.**
Without it, rule 1 depends on discipline, and discipline is the first thing to go before a deadline.

### 3. Required keys never have a fallback

This is *Surface failures explicitly* as it applies to environment variables.

A fallback means the app runs without the key, which contradicts calling it required. When the key is
missing the app does not fail — it **quietly points at the wrong target.** Script entry points that skip
the boot check are where this hurts most.

> Real incident: `DATABASE_URL ?? "postgresql://localhost..."` kept the app running against a local
> database after the production key went missing.

Ban the combination itself with a test that finds any required key carrying a fallback.

Fallbacks for optional keys go the other way: **collect them in one place instead of hard-coding them.**
Scattered, the same value gets copied into several files and only some of them get updated.

> Real incident: the canonical domain was hard-coded separately in the site metadata module and in the
> notification module.

### 4. Validate everything once at boot

Check every registered key before the process accepts its first request.

- required: check presence and shape. Fail the boot if any is missing.
- optional: check shape only when a value is present.

Read a key at the moment the feature needs it and the failure surfaces **after the user has already
paid.** The boot check moves that failure to just after deploy. Validating optional keys serves the same
end — a typo'd webhook URL gets caught at boot instead of when an alert is needed.

Report **every** problem key at once. One at a time turns into one redeploy per key.

### 5. The example file matches the registry exactly

Commit `.env.example` (name it by your stack's convention) and enforce with a test that its key set
matches the registry **in both directions.** A key only in the example fails, and so does a key only in
the registry.

- Required keys are not commented out. Copying the file should be enough to boot.
- Optional keys are commented out, so "you can live without this" is visible in the shape of the file.
- Values are placeholders that convey the format only. Never a real value.

A file kept in sync by hand always drifts, and a drifted example file is worse than none: a new
contributor trusts it, fails, and never trusts it again.

### 6. Values stay out of the repository and out of the logs

- Exclude files holding real values from the repository. Commit only the example.
- **Never put a value in a validation error.** Emit the key name and the kind of problem, nothing more.
  Boot errors are retained in deployment logs, and those logs are usually readable by more people than
  the value itself is.
- Do not print or forward the contents of a secret-bearing file. Confirm presence or length if you must.

### 7. Anything that reaches the client is a public value

A value baked into the build output is **public**, whatever prefix it carries and whatever tool put it
there. Mark that boundary with the registry's scope field and keep server-only keys from crossing it.

Exposing only the keys each boundary needs also removes the path by which a server secret leaks into
client code. For a program with a single runtime boundary (a CLI, a batch job) this rule does not apply.

## Violation signals

Any one of these after a change means this document was broken.

- Code reads a key that is not in the registry
- A required key gained a `?? default` / `or "default"` / `getenv(key, default)`
- A new key was added and the example file was not updated
- A value shows up in a validation error or a log line
- The call was "leave it for now and clean it up later"
  (→ *Do not accept a stopgap that only works for now and is meant to be replaced later*)

## Implementation

The contracts above are fixed; the means follow the stack. Use what the project already depends on
(→ *Lean on the dependencies already in the project*).

| Contract | Example means |
| --- | --- |
| Registry + shape validation | TypeScript: a zod schema object / Python: `pydantic-settings` / Go: a tagged struct |
| Boot-time full check | The framework's startup hook, the app factory, the top of `main()` |
| Contract test | The project's existing test runner: read the example file and diff key sets, scan the source for raw access |
| Value injection | `.env`-style files locally, the platform's secret store in deployment |

One registry entry, in TypeScript with zod:

```ts
DATABASE_URL: {
  scope: "server",
  requirement: "required",
  schema: z.string().min(1),
  note: "Postgres connection string (Neon in production)"
}
```

Moving that entry to another stack, what has to survive is not the syntax. It is that **all four fields
are filled in** and that **the registry can be enumerated to drive the checks.**
