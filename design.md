# Design Principles

These principles take precedence over an agent's default behavior.

They apply to **screens where a user performs work**: admin tools, dashboards, forms, settings, and
internal tools. Platform does not matter - web, desktop, and mobile are all in scope.
Persuasion design (landing pages, marketing pages) is out of scope for this document.

Each example shows the **shape** of a violation; it does not limit the principle to that case.

## Principles

### 1. A list is a read view, and the data decides its shape

Open an edit form only on request. When users recognize items by image (assets, products,
screenshots), use a card grid. When users compare items by fields (codes, dates, amounts, states),
use a table. When an image is incidental, keep the table and add a thumbnail column.

```text
✗ a list that renders every record as an always-open edit form
✗ a card grid for coupon records that are compared by code, amount, and state
✓ coupons: table + row click opens a detail/edit panel
✓ card news assets: thumbnail card grid
```

### 2. The screen follows the operator's workflow, not the database schema

```text
✗ form fields laid out in table-column order
✓ the most frequent tasks (check state, copy a code, toggle active) on the first screen,
  rare tasks (edit a date range) behind the detail view
```

### 3. The most frequent action takes the fewest clicks

```text
✗ toggling a coupon active requires entering a form, finding a checkbox, and saving
✓ a one-click toggle on the list row
```

### 4. Show derived state; never make the user compute it

```text
✗ the user reads startsAt, endsAt, and active, then works out whether the coupon is valid
✓ the screen shows "currently valid" / "expires Aug 30" as a computed status
```

### 5. Follow the product's existing patterns; invent a new one only where the existing one fails

```text
✗ the applications screen is a table with a detail panel, but the coupons screen is a stack of forms
✓ both screens share the same structure
```

### 6. State the consequence before a destructive or customer-visible action

```text
✗ a "save" button that does not say what changes
✓ "deactivating blocks new uses; history is preserved" at the moment of the action
```

### 7. Encode state and structure visually; sentences are the last resort

Color, badges, icons, placement, and weight come first; add a short label only when those are not
enough. A screen that needs an explanatory paragraph has failed at its layout. The inverse is a
violation of the same principle: an icon that carries meaning always gets a text label or tooltip.

```text
✗ a three-sentence policy explanation above the list, helper text under every field
✓ "currently valid" as a green dot with a short label;
  the policy sentence appears once, at the action that needs it
```
