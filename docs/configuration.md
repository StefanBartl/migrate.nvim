# Configuration

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
