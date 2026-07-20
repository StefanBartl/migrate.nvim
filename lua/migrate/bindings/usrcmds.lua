---@module 'migrate.bindings.usrcmds'
---@brief Enables `:MigrateOpt` / `:MigrateNotify` based on config.
---@description
--- Each module owns its own scan/apply/picker logic (see `migrate.opt`,
--- `migrate.notify`) and registers its user command via
--- `migrate.common.command`; this module only decides *which* of them get
--- enabled for a given config.

local notify = require("lib.nvim.notify").create("[migrate.bindings.usrcmds]")

local M = {}

---@param cfg UsrCmds.Migrate.Config
---@return nil
function M.setup(cfg)
  if cfg.opt then
    local ok, opt = pcall(require, "migrate.opt")
    if ok then
      opt.enable()
    else
      notify.warn("Failed to load opt module: " .. tostring(opt))
    end
  end

  if cfg.notify then
    local ok, notify_mod = pcall(require, "migrate.notify")
    if ok then
      notify_mod.enable()
    else
      notify.warn("Failed to load notify module: " .. tostring(notify_mod))
    end
  end
end

return M
