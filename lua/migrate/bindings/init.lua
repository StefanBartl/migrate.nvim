---@module 'migrate.bindings'
---@brief Orchestrates migrate's bindings: user commands and optional keymaps.

local M = {}

---@param cfg UsrCmds.Migrate.Config
---@return nil
function M.setup(cfg)
  require("migrate.bindings.usrcmds").setup(cfg)

  if type(cfg.keymaps) == "table" then
    require("migrate.bindings.keymaps").setup(cfg)
  end
end

return M
