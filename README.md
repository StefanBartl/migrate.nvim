```
  ███╗   ███╗██╗ ██████╗ ██████╗   █████╗ ████████╗███████╗
  ████╗ ████║██║██╔════╝ ██╔══██╗ ██╔══██╗╚══██╔══╝██╔════╝
  ██╔████╔██║██║██║  ███╗██████╔╝ ███████║   ██║   █████╗
  ██║╚██╔╝██║██║██║   ██║██╔══██╗ ██╔══██║   ██║   ██╔══╝
  ██║ ╚═╝ ██║██║╚██████╔╝██║  ██║ ██║  ██║   ██║   ███████╗
  ╚═╝     ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
                                                       .nvim
```

![Neovim](https://img.shields.io/badge/Neovim-0.9+-57A143?logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/Made%20with-Lua-2C2D72?logo=lua&logoColor=white)

> 💡 Pairs well with [recommender.nvim](https://github.com/StefanBartl/recommender.nvim):
> use migrate to clear out deprecated API calls, and recommender to spot the
> repeated chains worth aliasing next.

`migrate.nvim` finds and rewrites deprecated Neovim API calls in the current
line, a range, the whole buffer, or the entire working directory — with a
Telescope picker and preview for anything past single-line scope.

---

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Commands](#commands)
- [Keymaps](#keymaps)
- [Health](#health)
- [Architecture](#architecture)
- [Roadmap](#roadmap)

---

## Features

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

---

## Requirements

- Neovim **0.9+**
- [lib.nvim](https://github.com/StefanBartl/lib.nvim) — **required**, used for
  notifications, keymaps, and the migrated `notify` API
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) —
  **required** for the `%` and `cwd` picker modes
- *(optional)* [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) — for
  `cwd`-wide scans

---

## Installation

**When to use which:**

| Variant | Startup impact | Commands available | When to use |
|---|---|---|---|
| **`cmd` (lazy)** | Minimal | On first `:MigrateOpt`/`:MigrateNotify` | **Recommended** — a migration tool is rarely needed at startup |
| **`lazy = false`** | Loads immediately | Right from the start | Rare: want it available before any command is typed |

### lazy.nvim

*Default (lazy-loaded on command use):*

```lua
{
  "StefanBartl/migrate.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  cmd = { "MigrateOpt", "MigrateNotify" },
  opts = {},
}
```

*Load at startup:*

```lua
{
  "StefanBartl/migrate.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  lazy = false,
  opts = {},
}
```

### packer.nvim

```lua
use({
  "StefanBartl/migrate.nvim",
  requires = { "StefanBartl/lib.nvim" },
  config = function()
    require("migrate").setup()
  end,
})
```

### vim-plug

```vim
Plug 'StefanBartl/lib.nvim'
Plug 'StefanBartl/migrate.nvim'
```

```lua
require("migrate").setup()
```

---

## Quick Start

```lua
require("migrate").setup() -- opt + notify both enabled by default
```

```vim
" Current line:
:MigrateOpt
:MigrateNotify

" Whole buffer, via Telescope picker:
:MigrateOpt %
:MigrateNotify % my.module.name

" Whole cwd, via Telescope picker (notify mode auto-writes touched files):
:MigrateOpt cwd
:MigrateNotify cwd my.module.name

" Explicit range:
:'<,'>MigrateOpt
:'<,'>MigrateNotify
```

In the Telescope picker: `<CR>` applies the current/multi-selected entries,
`<C-a>` / `<S-A>` / `<M-a>` / `<C-y>` apply **all** matches at once.

See [docs/USAGE-EXAMPLES.md](docs/USAGE-EXAMPLES.md) for full before/after
scenarios (aliasing, multiline calls, batch workflows, edge cases).

---

## Configuration

All options and their defaults:

```lua
require("migrate").setup({
  -- Enable `:MigrateOpt`.
  opt = true,

  -- Enable `:MigrateNotify`.
  notify = true,

  -- Optional keymaps that run the corresponding command on the current line.
  -- false = no keymaps (default); or a table to enable individually:
  keymaps = false,
  -- keymaps = { opt = "<leader>mo", notify = "<leader>mn" },
})
```

Passing an empty table (or omitting `setup()` options) enables both modules —
equivalent to `{ opt = true, notify = true }`.

---

## Commands

| Command | Argument | Behavior |
|---|---|---|
| `:MigrateOpt` / `:MigrateNotify` | *(none)* | Migrate the current line, applied immediately |
| `:'<,'>MigrateOpt` / `:'<,'>MigrateNotify` | *(range)* | Migrate the given range, applied immediately |
| `:MigrateOpt %` / `:MigrateNotify %` | `%` | Scan the whole buffer, open Telescope picker |
| `:MigrateOpt cwd` / `:MigrateNotify cwd` | `cwd` | Scan the working directory via ripgrep, open Telescope picker |

`:MigrateNotify` additionally accepts a second argument, the module name used
in the injected `require("lib.nvim.notify").create("[name]")` line, e.g.
`:MigrateNotify % my.plugin.ui`.

---

## Keymaps

Disabled by default. Enable in `setup()`:

```lua
require("migrate").setup({
  keymaps = {
    opt = "<leader>mo",
    notify = "<leader>mn",
  },
})
```

Each configured keymap runs the corresponding command in current-line mode.
which-key (if installed) picks up each mapping's description automatically —
no group registration is needed since there is no fixed prefix.

---

## Health

```vim
:checkhealth migrate
```

Reports core module status, required dependencies (`lib.nvim`,
`telescope.nvim`), optional `ripgrep` availability, the active configuration,
and whether which-key is detected.

---

## Architecture

```
migrate.nvim/
  lua/migrate/
    init.lua               -- setup()
    config/{init,DEFAULTS}  -- merge + get()
    bindings/               -- usrcmds, optional keymaps, which-key
    common/                 -- shared command/picker/buffer helpers
    opt/                    -- nvim_*_option -> *_option_value
    notify/                 -- vim.notify -> lib.nvim.notify
      parser/               -- detection: aliases, patterns, extraction, migration
      refactor/             -- application: import injection, cleanup, apply, write
    health.lua
    @types/init.lua
  docs/BINDINGS.md          -- binding cheatsheet
  docs/USAGE-EXAMPLES.md    -- before/after scenarios
  doc/migrate.txt           -- :h migrate
```

---

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md).
