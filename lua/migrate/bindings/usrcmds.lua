---@module 'migrate.bindings.usrcmds'
---@brief Enables `:MigrateOpt` / `:MigrateNotify` based on config.
---@description
--- Each module owns its own scan/apply/picker logic (see `migrate.opt`,
--- `migrate.notify`) and registers its user command via
--- `migrate.common.command`; this module only decides *which* of them get
--- enabled for a given config.

local M = {}

---@param cfg UsrCmds.Migrate.Config
---@return nil
function M.setup(cfg)
  if cfg.opt then
    local ok, opt = pcall(require, "migrate.opt")
    if ok then
      opt.enable()
    else
      vim.notify("[migrate] Failed to load opt module: " .. tostring(opt), vim.log.levels.WARN)
    end
  end

  if cfg.notify then
    local ok, notify = pcall(require, "migrate.notify")
    if ok then
      notify.enable()
    else
      vim.notify(
        "[migrate] Failed to load notify module: " .. tostring(notify),
        vim.log.levels.WARN
      )
    end
  end
end

return M
