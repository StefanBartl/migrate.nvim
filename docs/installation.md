# Installation

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
