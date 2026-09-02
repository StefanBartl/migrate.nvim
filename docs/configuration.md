# Configuration

All options and their defaults:

```lua
require("migrate").setup({
  -- Enable `:MigrateOpt`.
  opt = true,

  -- Enable `:MigrateNotify`.
  notify = true,

  -- Enable `:MigrateHl`.
  hl = true,

  -- Enable `:MigrateLsp`.
  lsp = true,

  -- Optional keymaps that run the corresponding command on the current line.
  -- false = no keymaps (default); or a table to enable individually:
  keymaps = false,
  -- keymaps = { opt = "<leader>mo", notify = "<leader>mn", hl = "<leader>mh", lsp = "<leader>ml" },

  -- Trace the scan -> picker -> apply -> write pipeline via notify.debug().
  debug = false,

  -- Register a position preview with hover.nvim, so resting the cursor on a
  -- line that uses a deprecated call says so in its float. A no-op without
  -- hover.nvim installed. See docs/hover.md for why this one is on by
  -- default while every other integration here is opt-in.
  hover = true,
})
```

Passing an empty table (or omitting `setup()` options) enables every
registered module — equivalent to explicitly setting each of `opt`,
`notify`, `hl`, `lsp` to `true`. The enabled set is driven by
[`migrate.registry`](../lua/migrate/registry.lua), so a third-party module
registered there picks up a config key the same way.
