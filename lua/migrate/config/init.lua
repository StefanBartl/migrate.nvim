---@module 'migrate.config'
---@brief Runtime configuration store for migrate.nvim.
---@description
--- Deep-merges user options over `migrate.config.DEFAULTS` and exposes a
--- single `get()` accessor so other modules never read a raw options table
--- directly.

local DEFAULTS = require("migrate.config.DEFAULTS")

---@class MigrateConfigModule
---@field options UsrCmds.Migrate.Config
local M = {}

M.options = vim.deepcopy(DEFAULTS)

--- Apply user options. Safe to call once from `setup()`.
--- An empty/nil table falls back to enabling every module (back-compat with
--- the pre-config.nvim default behavior).
---@param opts UsrCmds.Migrate.Config|nil
---@return nil
function M.setup(opts)
  if type(opts) ~= "table" or vim.tbl_isempty(opts) then
    M.options = vim.deepcopy(DEFAULTS)
    return
  end

  -- lib.lua.tables.deep_merge mutates its first argument, so it runs against
  -- a fresh deep copy — DEFAULTS itself must never be mutated (its own
  -- docstring: "Never mutate it at runtime"). Unlike this module's prior
  -- hand-rolled version, it doesn't special-case vim.islist() values (an
  -- override list would be recursively merged into a default list rather
  -- than replacing it wholesale) — not currently reachable since no config
  -- field is list-typed, but worth knowing if one is added later.
  M.options = require("lib.lua.tables").deep_merge(vim.deepcopy(DEFAULTS), opts)
end

---@return UsrCmds.Migrate.Config
function M.get()
  return M.options
end

return M
