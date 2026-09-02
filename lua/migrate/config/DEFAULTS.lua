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
---@see migrate.registry

local registry = require("migrate.registry")

---@type UsrCmds.Migrate.Config
local DEFAULTS = {
  -- Optional keymaps that run the corresponding command on the current line.
  -- false = no keymaps (default); or a table to enable individually:
  --   keymaps = { opt = "<leader>mo", notify = "<leader>mn" }
  keymaps = false,

  -- Trace the scan -> picker -> apply -> write pipeline via notify.debug().
  debug = false,

  -- One-time "which CLI tools does this plugin want, and why" popup on
  -- first setup() after install (via lib.nvim.deps). false disables it for
  -- this plugin specifically, right here in the spec passed to setup() —
  -- no vim.g needed. See README.
  deps_popup = true,

  -- Register a position preview with hover.nvim, so resting the cursor on a
  -- line that uses a deprecated call says so in hover.nvim's float. Soft in
  -- both directions: without hover.nvim installed this does nothing at all,
  -- and it costs nothing then either.
  --
  -- On by default, which is unusual for an integration and deliberate here:
  -- `migrate_line` returns the line unchanged unless it genuinely migrates,
  -- so this answers only where there is something to report. The usual
  -- objection to an unasked float -- that it interrupts without adding --
  -- has no purchase.
  hover = true,
}

for name in pairs(registry.list()) do
  DEFAULTS[name] = true
end

return DEFAULTS
