---@module 'migrate.config.DEFAULTS'
---@brief Immutable default configuration for migrate.nvim.
---@description
--- Single source of truth for every configurable value. `migrate.config`
--- deep-merges user options on top of this table. Never mutate it at runtime.

---@type UsrCmds.Migrate.Config
local DEFAULTS = {
  -- Enable `:MigrateOpt` (nvim_{buf,win}_{get,set}_option -> *_option_value).
  opt = true,

  -- Enable `:MigrateNotify` (vim.notify -> lib.nvim.notify).
  notify = true,

  -- Optional keymaps that run the corresponding command on the current line.
  -- false = no keymaps (default); or a table to enable individually:
  --   keymaps = { opt = "<leader>mo", notify = "<leader>mn" }
  keymaps = false,
}

return DEFAULTS
