---@module 'migrate'
---@brief Unified migration module setup
---@description
--- Central entry point for all migration tools.
--- Enables consistent setup across all migration types.
---
--- Example usage:
---   require("migrate").setup({
---     opt = true,
---     notify = true,
---   })
---
--- Or enable individual modules:
---   require("migrate.opt").enable()
---   require("migrate.notify").enable()

local M = {}

---Setup migration tools
---@param config UsrCmds.Migrate.Config|nil Configuration table
function M.setup(config)
  config = config or {}

  -- Default: enable all if no config provided
  if vim.tbl_isempty(config) then
    config = {
      opt = true,
      notify = true,
    }
  end

  -- Enable modules based on config
  if config.opt then
    local ok, opt = pcall(require, "migrate.opt")
    if ok then
      opt.enable()
    else
      vim.notify(
        "[migrate] Failed to load opt module: " .. tostring(opt),
        vim.log.levels.WARN
      )
    end
  end

  if config.notify then
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

---Enable all migration tools (convenience function)
function M.enable_all()
  M.setup({
    opt = true,
    notify = true,
  })
end

---Disable all migration tools
function M.disable_all()
  -- Remove user commands
  pcall(vim.api.nvim_del_user_command, "MigrateOpt")
  pcall(vim.api.nvim_del_user_command, "MigrateNotify")
end

return M
