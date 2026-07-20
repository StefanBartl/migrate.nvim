# migrate.nvim — Binding Cheatsheet

Machine-readable overview of every keymap, user command, and autocommand
defined by `migrate.nvim`. This file is documentation only and mirrors the
source of truth in `lua/migrate/bindings/`. Any change there must be
reflected here.

## Keymaps

None by default. Optional — set `keymaps` in `setup()` to enable:

```lua
require("migrate").setup({
  keymaps = {
    opt = "<leader>mo",
    notify = "<leader>mn",
  },
})
```

| lhs (user-defined) | mode | config key | runs | desc |
| --- | --- | --- | --- | --- |
| `keymaps.opt` | n | `keymaps.opt` | `:MigrateOpt` (current line) | migrate: run :MigrateOpt (current line) |
| `keymaps.notify` | n | `keymaps.notify` | `:MigrateNotify` (current line) | migrate: run :MigrateNotify (current line) |

There is no fixed prefix — each `lhs` is an arbitrary string the user
chooses. which-key (if installed) picks up the `desc` above automatically;
no group/prefix registration is performed (see
`lua/migrate/bindings/which_key.lua`).

## User Commands

Registered when their module is enabled (`opt` / `notify`, both default to
`true`), each its own [`lib.nvim.usercmd.composer`](https://github.com/StefanBartl/lib.nvim)
verb (a flat `path = {}` root route — no subcommand tree). `:MigrateOpt` is
registered through the shared factory in `lua/migrate/common/command.lua`;
`:MigrateNotify` registers directly in `lua/migrate/notify/init.lua` since
its grammar (an extra `module_name` argument, different auto-write rules)
doesn't fit that factory.

| name | args | range | desc |
| --- | --- | --- | --- |
| `:MigrateOpt` | `[%\|cwd]` | yes | Migrate `nvim_{buf,win}_{get,set}_option` calls |
| `:MigrateNotify` | `[%\|cwd] [module_name]` | yes | Migrate `vim.notify` calls to `lib.nvim.notify` |

Argument semantics (both commands):

| arg | behavior |
| --- | --- |
| *(none)* | Current line, applied immediately |
| *(range, e.g. `:'<,'>`)* | Given range, applied immediately (no picker) |
| `%` | Whole buffer, opens Telescope picker |
| `cwd` | Working directory via ripgrep, opens Telescope picker (`MigrateNotify cwd` auto-writes touched files) |

## Autocommands

None. migrate.nvim performs all work on explicit `:MigrateOpt` /
`:MigrateNotify` invocations — no `FileType`/`BufWritePre`/etc. autocmds are
registered.

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
