# hover.nvim integration

Resting the cursor on a line that uses a deprecated call says so, in
[hover.nvim](https://github.com/StefanBartl/hover.nvim)'s float — the same
float that previews a file, a picture or a PDF page when the cursor is on a
path.

```
local c = vim.lsp.buf_get_clients(0)

┌ migrate.nvim ─────────────────────────────────────────┐
│ deprecated API on this line                           │
│                                                       │
│ now:  local c = vim.lsp.get_clients({ bufnr = 0 })    │
│                                                       │
│ `:Migrate lsp` rewrites it, here or across the buffer.│
└───────────────────────────────────────────────────────┘
```

## What it is, in hover.nvim's terms

hover.nvim takes three kinds of contribution. A **source** answers "what is
under the cursor?", a **preview** answers "how do I render a target of this
type?", and a **position** answers "is there anything to say about this
*place*?" — for a cursor position that points at nothing.

This is the third kind, and it is the reason that kind exists: a deprecated
call is not something the line *points at*, it is a fact *about* the line.
Before hover.nvim grew `positions`, "no target" meant "no hover" and this
integration was not expressible.

## Why it is on by default

Every other optional integration in this ecosystem is opt-in, and this one is
not. The reason is specific rather than a preference.

hover.nvim's standing rule is that a float opening unasked is welcome only
when it says something the line does not already say — which is why web links
are off, why fetching is off again on top, and why office conversion is off.
Each of those fires often and adds little, or costs a lot.

Neither applies here. The check is `migrate.lsp.migrator.migrate_line`, the
same function `:Migrate lsp` runs, and it returns the line **unchanged**
unless the line genuinely uses a deprecated call. So:

- it answers on the small set of lines where there is something to report,
- and is silent on every other line, with no heuristic deciding that.

There is no volume to gate, so there is nothing for a switch to protect you
from.

## The rules are not duplicated here

The position function calls the migrator. It does not carry its own copy of
the patterns, which means a deprecation the migrator learns is one the hover
knows in the same commit. A separate rule table would be a second source of
truth that can fall behind the first one silently — the failure mode this
ecosystem has hit more than once.

The consequence worth stating: **the hover reports exactly what
`:Migrate lsp` would rewrite, no more and no less.** If the float says
nothing on a line you believe is deprecated, the migrator does not handle it
either, and that is the thing to fix.

## Soft in both directions

- **Without hover.nvim**, `setup()` looks for `hover.registry`, does not find
  it, and returns. Nothing is registered, nothing errors, nothing costs
  anything.
- **Without migrate.nvim**, hover.nvim is unaffected: it never names this
  plugin. Contributions arrive through its registry, and it would not notice
  a sixth contributor.
- **With an older hover.nvim** that has a registry but not `positions`, the
  integration declines rather than registering something that would be
  silently ignored — which would read as "the feature does not work" instead
  of "your hover.nvim predates it".

## Turning it off

```lua
require("migrate").setup({ hover = false })
```

Or from hover.nvim's side, which silences every registered position preview at
once rather than only this one:

```vim
:Hover positions off
```

## What it does not do

- **It does not rewrite anything.** The float is a preview; `:Migrate lsp`
  does the writing. That separation is deliberate — a hover that edited the
  buffer would be a very surprising hover.
- **It does not scan the buffer.** One line, the one under the cursor. A
  buffer-wide report is what the picker is for.
- **It does not follow the cursor into a non-file buffer.** hover.nvim never
  attaches to a buffer with a non-empty `'buftype'`, so a picker, a tree or a
  terminal is out regardless.
