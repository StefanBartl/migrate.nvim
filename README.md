> **Active development.** This repository is in its development phase — breaking changes are to be expected at any time. Pin a commit or tag if you depend on it.

# migrate.nvim

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
[![CI](https://github.com/StefanBartl/migrate.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/StefanBartl/migrate.nvim/actions/workflows/ci.yml)

> 💡 Pairs well with [recommender.nvim](https://github.com/StefanBartl/recommender.nvim):
> use migrate to clear out deprecated API calls, and recommender to spot the
> repeated chains worth aliasing next.

`migrate.nvim` finds and rewrites deprecated Neovim API calls in the current
line, a range, the whole buffer, or the entire working directory — with a
Telescope picker and preview for anything past single-line scope.

---

## Quick start

```lua
-- lazy.nvim
{
  "StefanBartl/migrate.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  cmd = { "MigrateOpt", "MigrateNotify", "MigrateHl", "MigrateLsp" },
  opts = {}, -- opt + notify + hl + lsp all enabled by default
}
```

```vim
:MigrateOpt          " migrate current line
:MigrateNotify %      " migrate whole buffer, via Telescope picker
:MigrateOpt cwd       " migrate whole working directory, via Telescope picker
:MigrateHl %          " vim.highlight.* -> vim.hl.*
:MigrateLsp %         " vim.lsp.buf_get_clients()/get_active_clients() -> vim.lsp.get_clients()
```

Requires [lib.nvim](https://github.com/StefanBartl/lib.nvim) and
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim); see
[docs/installation.md](docs/installation.md) for full requirements and setup
for lazy.nvim/packer.nvim/vim-plug.

`rg` (ripgrep) is optional, enabling `cwd`-wide scans — declared in
[`docs/install.json`](docs/install.json) and parsed by lib.nvim's
[`deps` module](https://github.com/StefanBartl/lib.nvim/blob/main/lua/lib/nvim/deps/README.md):
a popup explains this the first time `setup()` runs after installing
migrate.nvim, `:Lib deps show migrate.nvim` repeats it any time, and it's
also folded into `:checkhealth migrate`. Disable it **right in this
plugin's own spec**: `require("migrate").setup({ deps_popup = false })`.
`vim.g.lib_nvim_deps_disable_first_run = true` (every plugin) /
`vim.g.lib_nvim_deps_disabled_plugins = { "migrate.nvim" }` also still
work, for turning it off without touching any plugin's config.

---

## Documentation

- [Features](docs/features.md) — migrated APIs, picker, and auto-import behavior.
- [Installation](docs/installation.md) — requirements and setup for lazy.nvim, packer.nvim, and vim-plug.
- [Configuration](docs/configuration.md) — all `setup()` options and their defaults.
- [Commands](docs/commands.md) — quick start, `:MigrateOpt`/`:MigrateNotify` reference, keymaps, and `:checkhealth migrate`.
- [Architecture](docs/architecture.md) — source layout overview.
- [Usage examples](docs/USAGE-EXAMPLES.md) — full before/after scenarios (aliasing, multiline calls, batch workflows, edge cases).
- [Bindings cheatsheet](docs/BINDINGS.md) — machine-readable keymap/command/autocommand reference.
