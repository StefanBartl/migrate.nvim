---@module 'migrate.bindings.which_key'
---@brief Reports whether which-key is installed.
---@description
--- which-key is a **soft** dependency: migrate.nvim's optional keymaps
--- (`migrate.bindings.keymaps`) already carry a `desc`, which which-key picks
--- up on its own -- no group/prefix to register, since keymaps are entirely
--- user-chosen strings with no fixed prefix. This module only exists so
--- `:checkhealth migrate` can report which-key's presence.

local M = {}

--- Whether which-key is installed (for :checkhealth reporting).
---@return boolean
function M.available()
  local ok, wk = pcall(require, "which-key")
  return ok and type(wk) == "table"
end

return M
