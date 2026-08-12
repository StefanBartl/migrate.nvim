# Features

`migrate.nvim` finds and rewrites deprecated Neovim API calls — on the
current line, a range, the whole buffer, or the entire working directory.
Every migration target is a self-contained module registered in
[`migrate.registry`](../lua/migrate/registry.lua) (config key → module →
command); the four below are the built-ins, but the registry itself is
open to third-party additions (see "Pluggable migration registry").

## Option API migration (`:MigrateOpt`)

Rewrites `nvim_{buf,win}_{get,set}_option(...)` calls to the
`nvim_{get,set}_option_value(...)` form Neovim replaced them with,
preserving whichever prefix the call used (`vim.api.`, a local `api.`
alias, or none) and turning the buffer/window argument into the new
`{ buf = ... }` / `{ win = ... }` table.

- **Module:** `lua/migrate/opt/migrator.lua` (`migrate_line`), `lua/migrate/opt/init.lua`
- **Usercmds:** `:MigrateOpt` — see [../BINDINGS.md#user-commands](BINDINGS.md#user-commands)
- **Config:** `opts.opt` (default `true`)

## `vim.notify` migration (`:MigrateNotify`)

- **Tab:** true
- **Module:** `lua/migrate/notify/` — `parser/` (detection), `refactor/` (application), `init.lua` (command)
- **Usercmds:** `:MigrateNotify` — see [../BINDINGS.md#user-commands](BINDINGS.md#user-commands)
- **Config:** `opts.notify` (default `true`)

Rewrites `vim.notify(msg, level, ...)` calls — including ones already
routed through a local `notify`/`levels` alias, or ones that already call
a bare `notify(...)` — into `lib.nvim.notify`'s level-method form
(`notify.info(...)`, `notify.error(...)`, etc.), and injects or upgrades
the `local notify = require("lib.nvim.notify").create("[module]")` line
that makes the rewritten calls work.

### What one migration does, end to end

1. **Detects existing aliases** (`lua/migrate/notify/parser/aliases.lua`) —
   `local notify, levels = vim.notify, vim.log.levels`, or either half
   standalone — scanning the first 50 lines, stopping at the first
   `function` definition.
2. **Scans for calls** (`lua/migrate/notify/parser/`), in priority order:
   direct `vim.notify(...)`, the detected alias's call form, then an
   already-existing bare `notify(...)`. Single-line and multiline calls
   (balanced-paren tracked) are both handled; a multiline call is
   consolidated onto one line in the replacement.
3. **Skips long-bracket strings** — a line that starts inside a
   `[[ ]]`/`[=[ ]=]` long string is never scanned, so a `vim.notify(...)`
   written as string *content* (documentation, a code sample embedded in
   a Lua string) is left untouched instead of being "migrated" into
   broken string content.
4. **Injects/upgrades the import** (`lua/migrate/notify/refactor/import.lua`)
   — adds `local notify = require("lib.nvim.notify").create("[name]")`
   above the first code line if missing, or rewrites an existing one whose
   module name differs. `module_name` is either the second argument
   passed to `:MigrateNotify`, or auto-detected from the buffer's path via
   `lib.nvim.lua_ls.get_module_path` when omitted.
5. **Removes stale aliases** (`lua/migrate/notify/refactor/cleanup.lua`) —
   once every call site is migrated, the original
   `local notify, levels = vim.notify, vim.log.levels` (or either half
   standalone) line is deleted.
6. **Auto-writes on `cwd` scans** (`lua/migrate/notify/refactor/write.lua`)
   — files touched during a `cwd`-scope migration are written back to
   disk automatically, `sync` (`vim.fn.writefile`, blocking) or `async`
   (`vim.uv.fs_write`, non-blocking) depending on the module's own
   `WRITE_STRATEGY` constant (currently hardcoded to `"async"`; not yet
   exposed through `setup()`). Line/buffer/range/`%` scopes never
   auto-write — only `cwd` does.
7. **Self-exclusion** — `cwd` scans skip any file inside migrate.nvim's
   own `lua/migrate/` source tree, so the tool never rewrites its own
   `vim.notify` calls.

## `vim.highlight` migration (`:MigrateHl`)

A blanket `vim.highlight.` → `vim.hl.` prefix rename — Neovim removed
`vim.highlight` outright in favor of `vim.hl`, keeping the same member
names (`range`, `on_yank`, `priorities`), so no argument rewriting is
needed, unlike `opt`/`lsp`.

- **Module:** `lua/migrate/hl/migrator.lua` (`migrate_line`), `lua/migrate/hl/init.lua`
- **Usercmds:** `:MigrateHl` — see [../BINDINGS.md#user-commands](BINDINGS.md#user-commands)
- **Config:** `opts.hl` (default `true`)

## LSP client-lookup migration (`:MigrateLsp`)

Rewrites the two deprecated LSP client-lookup calls onto
`vim.lsp.get_clients()`: `buf_get_clients(bufnr)` becomes
`get_clients({ bufnr = bufnr })` (defaulting to buffer `0` when no
argument was passed), and `get_active_clients(filter)` is a name-only
rename to `get_clients(filter)` with its argument list left untouched.
Other `vim.lsp.buf_*` functions (`buf_request*`, `buf_notify`,
`buf_attach_client`, ...) are not deprecated and are deliberately left
alone.

- **Module:** `lua/migrate/lsp/migrator.lua` (`migrate_line`), `lua/migrate/lsp/init.lua`
- **Usercmds:** `:MigrateLsp` — see [../BINDINGS.md#user-commands](BINDINGS.md#user-commands)
- **Config:** `opts.lsp` (default `true`)

## Telescope picker for buffer/cwd scans

A shared picker (`lua/migrate/common/picker.lua`) backs every module's `%`
and `cwd` scope: multi-select with `<Tab>`, a before/after preview per
entry, and batch-apply across every match at once with any of `<C-a>`,
`<S-A>`, `<M-a>`, or `<C-y>` (four keys mapped to the same action, kept
for muscle-memory compatibility across setups). Line and range scopes
apply immediately and never open the picker.

- **Module:** `lua/migrate/common/picker.lua` (`M.show`)
- **Keymaps:** picker keys — see [../BINDINGS.md#picker-keys](BINDINGS.md#picker-keys)

## Pluggable migration registry

`migrate.opt`/`notify`/`hl`/`lsp` are not special-cased anywhere outside
`lua/migrate/registry.lua` — each is a plain `M.register(name, { module,
command, desc })` entry, and `migrate.config.DEFAULTS`,
`migrate.bindings` (usercmds/keymaps/which-key), `migrate.health`, and
`migrate.init`'s `enable_all()`/`disable_all()` all iterate the registry
instead of naming individual modules. A third-party module can add itself
the same way — `require("migrate.registry").register("myname", {...})`
before `require("migrate").setup()` — and picks up a config key, a
health-check entry, and optional keymap support without touching any of
those four files.

- **Module:** `lua/migrate/registry.lua` (`M.register`, `M.list`)

## `:checkhealth migrate`

Reports whether the core module and every registered migration module
load, whether the required dependencies (`lib.nvim`, `telescope.nvim`)
are present, whether `rg` (needed for `cwd` scans) is on `$PATH`, the
active per-module configuration and keymap bindings, and whether
which-key is detected. Also folds in `lib.nvim.deps`' own report for
migrate.nvim's declared optional tools (`docs/install.json`), when a
`lib.nvim` new enough to expose it is installed.

- **Module:** `lua/migrate/health.lua` (`M.check`)
- **Usercmds:** `:checkhealth migrate`

## Debug tracing

`debug = true` in `setup()` turns on tracing through the scan → picker →
apply → write pipeline, routed through `lib.nvim.notify`'s own `.debug()`
level rather than a bespoke logger — so the trace output goes through
whatever sink/filtering the rest of migrate.nvim's notifications already
use. A no-op when `debug` is `false` (the default): no formatting or
notify call happens on the hot path.

- **Module:** `lua/migrate/common/debug.lua` (`M.trace`)
- **Config:** `opts.debug` (default `false`)

## Optional per-module keymaps

Off by default; `setup({ keymaps = { opt = "<leader>mo", notify = "<leader>mn", hl = "<leader>mh", lsp = "<leader>ml" } })`
binds each configured `lhs` to that module's command in current-line
mode. There is no fixed prefix — each `lhs` is whatever string the user
chooses — and which-key (if installed) picks up each mapping's
description automatically, with no group/prefix registration performed.

- **Module:** `lua/migrate/bindings/keymaps.lua`, `lua/migrate/bindings/which_key.lua`
- **Keymaps:** see [../BINDINGS.md#keymaps](BINDINGS.md#keymaps)
- **Config:** `opts.keymaps` (default `false`)
