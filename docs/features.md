# Features

| Module | Migrates | Modes |
|---|---|---|
| **opt** | `nvim_{buf,win}_{get,set}_option` → `nvim_{get,set}_option_value` | line, range, buffer (`%`), cwd |
| **notify** | `vim.notify(...)` (incl. aliased/existing `notify(...)` calls, single- and multiline) → `lib.nvim.notify` | line, range, buffer (`%`), cwd |
| **hl** | `vim.highlight.*` (`range`, `on_yank`, `priorities`) → `vim.hl.*` | line, range, buffer (`%`), cwd |
| **lsp** | `vim.lsp.buf_get_clients()` / `vim.lsp.get_active_clients()` → `vim.lsp.get_clients()` | line, range, buffer (`%`), cwd |

Every module is a plain entry in [`migrate.registry`](../lua/migrate/registry.lua)
(config key → module → command) — a third-party module can add itself there
without touching `migrate.config`/`migrate.bindings`.

- **Telescope picker** for buffer/cwd scans — multi-select (`<Tab>`), preview,
  batch-apply (`<C-a>` / `<S-A>` / `<M-a>` / `<C-y>`)
- **Auto-import** — `notify` mode injects/upgrades the
  `local notify = require("lib.nvim.notify").create("[module]")` line and
  removes stale `vim.notify`/`vim.log.levels` aliases
- **String-literal aware** — `notify` mode skips `vim.notify(...)` written
  inside a `[[ ]]`/`[=[ ]=]` long-bracket string instead of migrating it
- **Auto-write on cwd scans** — files touched during a `cwd` notify-migration
  are written back to disk automatically (async by default)
- **Self-exclusion** — cwd scans never rewrite migrate.nvim's own source
- **`debug = true`** — traces the scan → picker → apply → write pipeline via
  `lib.nvim.notify`'s `.debug()` level
- **`:checkhealth migrate`** — reports dependency status and active config
