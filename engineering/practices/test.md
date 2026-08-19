# Testing

## Principle

Write a test only when its return beats its maintenance cost.

Every test is bought twice: once when it is written, and again every time the implementation moves
underneath it. **AI drove the first price to nearly zero and left the second untouched.** That is why
agent-written suites grow fast and then start dragging - the cheap half got cheaper, the expensive
half did not.

Two questions decide whether a test is worth having. Both have answers.

- **Return** - if a plausible bug were introduced, would this test fail?
- **Cost** - if the implementation changed without changing behavior, would this test fail?

The second is *resistance to refactoring*. A test that answers **no** to the first and **yes** to the
second is pure liability: it catches nothing and bills you on every change. Delete it.

The problem was never the number of tests. It is that nobody priced them.

## Enforcement

### 1. The expected answer comes from outside the code

Decide what the result should be before looking at how it is produced. A test written by reading the
implementation records what the code *does*, bugs included - the defect is now in two files, and the
test can only obstruct the next refactor.

The harder half: **the correct answer is usually not in the code at all.** Common-sense flows can be
inferred; product rules cannot. "Only paid members can favorite." "The limit is a floor, not a ceiling."
"An expired subscription shows the renewal screen instead of blocking." An agent reading only the
source will write a suite that looks complete and quietly misses the rules nobody wrote down.

> Real case: a screen was described as "premium members only." Tests written from the code checked that
> free members are blocked - and passed. The actual policy also had suspended and expired members. A
> bug that let them through survived the whole suite.

**Have the agent ask instead of answer.** Do not commission tests; commission questions.

1. The agent drafts the rules it can find from the code and the commit history, marking every
   uncertain point as an explicit question.
2. A human answers only the marked questions.
3. The answers become the source of truth the tests are written against.

Writing a spec from scratch is the step everyone skips, which is how "just read the code" becomes the
default. A draft full of question marks is cheap enough to actually get done.

### 2. Mock only across a boundary you cannot change

Mocking is where maintenance cost is manufactured. Every mock of your own code freezes a name, a method
list, and a position in the call graph into a file that has nothing to do with behavior.

Maintain a **whitelist of what may be mocked**, not a blacklist of what may not. Agents fill any gap in
a blacklist with another mock, because a mock is the fastest way to make a test go green.

```ts
// ✓ the only sanctioned mocks: systems you do not own and cannot refactor
mockHTTP()      // third-party HTTP
mockClock()     // time
mockRandom()    // randomness
mockBrowser()   // platform and browser APIs
```

- Raw `vi.mock` / `vi.fn` / `unittest.mock` in a test file is a lint error. Sanctioned helpers only.
- Declare directories that are never mocked - repositories, services, hooks, queries, models.
  These are exactly what refactoring moves.
- **Name the helper after the thing being faked, not the call being faked.** `mockFetchCard()` hides
  what boundary is being crossed; `server.respond(cardResponse)` makes it obvious the subject is an
  external system.

### 3. Needing a mock outside the list is a design result, not a test problem

When a test cannot run without faking your own modules, the answer is never a better mock.

Usually the decision buried in there should have been a pure function that takes values and returns a
result. Extract it, test it directly, and let one end-to-end path cover the thin remainder.

Sometimes the answer is worse: **the thing cannot be verified here at all.**

> Real case: a client-side check compared a balance against a top-up limit - but the balance lives in
> another system and the client never sees it. Mocks filled the gap, the test passed, and the passing
> test hid the fact that the rule could not be enforced at that layer.

A green test built on mocks does not just fail to prove correctness. It conceals the question.

### 4. Assert outcomes, not calls

Assert what a caller can observe: the returned value, the persisted state, the response that goes out.

"This function was called with these arguments" is an assertion about wiring, and wiring is exactly
what a refactor rearranges. It also stays green while the feature is broken, as long as the call
still happens.

The same applies to reaching for the subject. Asserting on DOM structure, CSS classes, or a whole
serialized payload buys the same coupling by another route. Prefer assertions phrased the way a user
would state the outcome.

### 5. Put tests on stable boundaries

Exported module functions, HTTP handlers, CLI entry points - surfaces other code already depends on.
Internal helpers get exercised through those, not directly.

A test aimed at a private helper is a promise never to rename it. If a helper must be exported so a
test can reach it, the test is on the wrong boundary.

### 6. Spend where the return is high

High return, stable shape - worth the maintenance:

- calculations and policy: refund amounts, pricing, eligibility
- state transitions, including the moves that must be rejected
- parsing, serialization, and anything crossing a system boundary
- relationships that must hold between two places (→ [env.md](env.md))
- authentication and permission boundaries

Low return, volatile shape - one end-to-end path per user-visible flow is enough:

- glue that only delegates
- layout and presentational structure
- wiring with no branch in it

### 7. Cover the edges, not the middle

Test the boundary of a rule and the first value on either side. Three assertions at the edges of a
refund window are worth more than twenty representative amounts, and they survive the rewrite that
twenty samples would not.

### 8. Prove the return: plant the bug the test claims to catch

A passing test says nothing about whether it defends anything. Coverage says less - it reports which
lines ran, not which bugs would be caught.

Before trusting a test, break the code on purpose:

1. **Predict first.** "Moving the free-shipping threshold from 30,000 to 20,000 will fail
   `cart_free_shipping_boundary`."
2. Make the change.
3. Did the predicted test fail?

Predicting first is the whole trick. Asked *afterwards* why a planted bug survived, an agent will
produce a fluent explanation for either outcome. Committed in advance, the question has one answer.

Plant bugs that look like bugs a person would actually ship - a moved boundary, a dropped policy
condition, a failure response handled as success. Not `0 → 1`, not a renamed variable, not something
that fails to compile. Change only code the tests actually reach, and only in ways an outside observer
could notice.

Three to five realistic mutations beat a tool generating thousands. If the predicted test passes, the
test is thin. When it is ambiguous, call it thin - that is the cheaper mistake.

### 9. Never edit a test to make it pass

A failing test is information. Change a test only when the requirement changed, and say which
requirement changed. "Updated the test to match the new implementation" is the sentence that turns a
suite into decoration.

## Violation signals

Any one of these after a change means this document was broken.

- A test mocks a module from this codebase, or calls a raw mocking primitive directly
- An assertion checks that a function was called, rather than what came out
- The test was written by reading the implementation, with no source of truth outside it
- A behavior-preserving refactor changed test files in the same commit
- A helper is exported only so a test can reach it
- A test failed and the test was the thing that got edited
- Nobody can name a bug the test would catch

## Implementation

Contracts are fixed; the means follow the stack. Use the test runner the project already has
(→ *Lean on the dependencies already in the project*).

| Contract | Example means |
| --- | --- |
| Source of truth outside the code | A short spec file per feature, drafted by the agent as questions and answered by a human |
| Whitelisted mocks | A `test/doubles` module exporting the sanctioned helpers; a lint rule banning raw mocking primitives and mock paths under owned directories |
| Owned collaborators, not mocked | An in-memory implementation of the same interface, or a real database in a disposable container |
| Pure decisions under test | A function taking values and returning a result. No I/O, no clock, no globals |
| Return measured | A pre-commit step that plants a few predicted mutations and records the outcome |

A test that survives a refactor, in TypeScript with vitest:

```ts
// the subject takes values and returns a decision - nothing to mock
it("suggests a full refund at exactly 7 days before start", () => {
  expect(suggestRefundAmountWon(startsAt, 129_000, daysBefore(7))).toBe(129_000)
})
```

What has to survive when this moves to another stack is not the syntax. It is that **the subject was
reachable without mocks**, that the assertion names an **outcome** rather than a call, and that
someone can name the bug it would catch.
