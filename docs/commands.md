# Commands

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

See [USAGE-EXAMPLES.md](USAGE-EXAMPLES.md) for full before/after
scenarios (aliasing, multiline calls, batch workflows, edge cases).

---

## Commands

Each command is its own [`lib.nvim.usercmd.composer`](https://github.com/StefanBartl/lib.nvim)
verb (a flat root route, no subcommand tree).

| Command | Argument | Behavior |
|---|---|---|
| `:MigrateOpt` / `:MigrateNotify` | *(none)* | Migrate the current line, applied immediately |
| `:'<,'>MigrateOpt` / `:'<,'>MigrateNotify` | *(range)* | Migrate the given range, applied immediately |
| `:MigrateOpt %` / `:MigrateNotify %` | `%` | Scan the whole buffer, open Telescope picker |
| `:MigrateOpt cwd` / `:MigrateNotify cwd` | `cwd` | Scan the working directory via ripgrep, open Telescope picker |

`:MigrateNotify` additionally accepts a second argument, the module name used
in the injected `require("lib.nvim.notify").create("[name]")` line, e.g.
`:MigrateNotify % my.plugin.ui`. This module name is always the *second*
token, even in range mode — `:'<,'>MigrateNotify my.plugin.ui` puts
`my.plugin.ui` in the unused first slot, not the module name. Pass a
placeholder first instead: `:'<,'>MigrateNotify - my.plugin.ui`.

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

See [BINDINGS.md](BINDINGS.md) for the full machine-readable keymap/command/
autocommand cheatsheet.

---

## Health

```vim
:checkhealth migrate
```

Reports core module status, required dependencies (`lib.nvim`,
`telescope.nvim`), optional `ripgrep` availability, the active configuration,
and whether which-key is detected.
