# Features

| Module | Migrates | Modes |
|---|---|---|
| **opt** | `nvim_{buf,win}_{get,set}_option` → `nvim_{get,set}_option_value` | line, range, buffer (`%`), cwd |
| **notify** | `vim.notify(...)` (incl. aliased/existing `notify(...)` calls) → `lib.nvim.notify` | line, range, buffer (`%`), cwd |

- **Telescope picker** for buffer/cwd scans — multi-select (`<Tab>`), preview,
  batch-apply (`<C-a>` / `<S-A>` / `<M-a>` / `<C-y>`)
- **Auto-import** — `notify` mode injects/upgrades the
  `local notify = require("lib.nvim.notify").create("[module]")` line and
  removes stale `vim.notify`/`vim.log.levels` aliases
- **Auto-write on cwd scans** — files touched during a `cwd` notify-migration
  are written back to disk automatically (async by default)
- **Self-exclusion** — cwd scans never rewrite migrate.nvim's own source
- **`:checkhealth migrate`** — reports dependency status and active config
