---@module 'migrate.config.DEFAULTS'
---@brief Immutable default configuration for migrate.nvim.
---@description
--- Single source of truth for every configurable value. `migrate.config`
--- deep-merges user options on top of this table. Never mutate it at runtime.
---
--- Every migration module registered in `migrate.registry` gets a config key
--- here (default `true`) -- see that module for the per-key description
--- (e.g. what `opt`/`notify`/`hl`/`lsp` each migrate) instead of duplicating
--- it in comments here, which would drift as modules are added.

local registry = require("migrate.registry")

---@type UsrCmds.Migrate.Config
local DEFAULTS = {
  -- Optional keymaps that run the corresponding command on the current line.
  -- false = no keymaps (default); or a table to enable individually:
  --   keymaps = { opt = "<leader>mo", notify = "<leader>mn" }
  keymaps = false,

  -- Trace the scan -> picker -> apply -> write pipeline via notify.debug().
  debug = false,
}

for name in pairs(registry.list()) do
  DEFAULTS[name] = true
end

return DEFAULTS
