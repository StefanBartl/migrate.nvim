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

--- Recursively merge `override` into a copy of `base`.
---@param base table
---@param override table
---@return table
local function deep_merge(base, override)
  local out = {}
  for k, v in pairs(base) do
    out[k] = v
  end
  for k, v in pairs(override) do
    if type(v) == "table" and type(out[k]) == "table" and not vim.islist(v) then
      out[k] = deep_merge(out[k], v)
    else
      out[k] = v
    end
  end
  return out
end

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

  M.options = deep_merge(DEFAULTS, opts)
end

---@return UsrCmds.Migrate.Config
function M.get()
  return M.options
end

return M
