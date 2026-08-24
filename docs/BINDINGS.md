# migrate.nvim — Binding Cheatsheet

Machine-readable overview of every keymap, user command, and autocommand
defined by `migrate.nvim`. This file is documentation only and mirrors the
source of truth in `lua/migrate/bindings/`. Any change there must be
reflected here.

## Keymaps

None by default. Optional — set `keymaps` in `setup()` to enable, keyed the
same as [`migrate.registry`](../lua/migrate/registry.lua)'s entries:

```lua
require("migrate").setup({
  keymaps = {
    opt = "<leader>mo",
    notify = "<leader>mn",
    hl = "<leader>mh",
    lsp = "<leader>ml",
  },
})
```

| lhs (user-defined) | mode | config key | runs | desc |
| --- | --- | --- | --- | --- |
| `keymaps.opt` | n | `keymaps.opt` | `:MigrateOpt` (current line) | migrate: run :MigrateOpt (current line) |
| `keymaps.notify` | n | `keymaps.notify` | `:MigrateNotify` (current line) | migrate: run :MigrateNotify (current line) |
| `keymaps.hl` | n | `keymaps.hl` | `:MigrateHl` (current line) | migrate: run :MigrateHl (current line) |
| `keymaps.lsp` | n | `keymaps.lsp` | `:MigrateLsp` (current line, or N with a count) | migrate: run :MigrateLsp (current line, or N with a count) |

**A count migrates that many lines.** `3<leader>mo` runs the command over the
cursor line and the two below it, clamped to the end of the buffer. It is
issued as an explicit `:{line1},{line2}` range — the same range mode a Visual
selection produces, so it applies directly with no picker, exactly like the
single-line case it generalizes.

The commands were range-capable all along; nothing was passing them a range
from a keymap. A count is spelled as a range rather than left to Vim's own
count-to-address translation, because `:3MigrateOpt` would mean "line 3", not
"three lines from here".

There is no fixed prefix — each `lhs` is an arbitrary string the user
chooses. which-key (if installed) picks up the `desc` above automatically;
no group/prefix registration is performed (see
`lua/migrate/bindings/which_key.lua`).

## User Commands

Registered when their module is enabled (`opt` / `notify` / `hl` / `lsp`,
all default to `true`, driven by [`migrate.registry`](../lua/migrate/registry.lua)),
each its own [`lib.nvim.usercmd.composer`](https://github.com/StefanBartl/lib.nvim)
verb (a flat `path = {}` root route — no subcommand tree). `:MigrateOpt`,
`:MigrateHl`, and `:MigrateLsp` are registered through the shared factory in
`lua/migrate/common/command.lua`; `:MigrateNotify` registers directly in
`lua/migrate/notify/init.lua` since its grammar (an extra `module_name`
argument, different auto-write rules) doesn't fit that factory.

| name | args | range | desc |
| --- | --- | --- | --- |
| `:MigrateOpt` | `[%\|cwd]` | yes | Migrate `nvim_{buf,win}_{get,set}_option` calls |
| `:MigrateNotify` | `[%\|cwd] [module_name]` | yes | Migrate `vim.notify` calls to `lib.nvim.notify` |
| `:MigrateHl` | `[%\|cwd]` | yes | Migrate `vim.highlight.*` calls to `vim.hl.*` |
| `:MigrateLsp` | `[%\|cwd]` | yes | Migrate `vim.lsp.buf_get_clients()`/`get_active_clients()` to `vim.lsp.get_clients()` |

Argument semantics (all four commands):

| arg | behavior |
| --- | --- |
| *(none)* | Current line, applied immediately |
| *(range, e.g. `:'<,'>`)* | Given range, applied immediately (no picker) |
| `%` | Whole buffer, opens Telescope picker |
| `cwd` | Working directory via ripgrep, opens Telescope picker (`MigrateNotify cwd` auto-writes touched files) |

For `:MigrateNotify`, `module_name` is always the *second* token — in range
mode a single token fills the unused first slot instead, so pass a
placeholder first: `:'<,'>MigrateNotify - my.plugin.ui`.

## Autocommands

None. migrate.nvim performs all work on explicit `:MigrateOpt` /
`:MigrateNotify` / `:MigrateHl` / `:MigrateLsp` invocations — no
`FileType`/`BufWritePre`/etc. autocmds are registered.

## Picker keys

Registered by `lua/migrate/common/picker.lua` on the Telescope prompt buffer
(buffer/cwd modes only):

| lhs | mode | action |
| --- | --- | --- |
| `<CR>` | i, n | Apply current entry, or all multi-selected (`<Tab>`) entries |
| `<C-a>` | i, n | Apply **all** matches |
| `<S-A>` | i, n | Apply **all** matches |
| `<M-a>` | i, n | Apply **all** matches |
| `<C-y>` | i, n | Apply **all** matches |
