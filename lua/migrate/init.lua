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

local config = require("migrate.config")

local M = {}

---Setup migration tools
---@param opts UsrCmds.Migrate.Config|nil Configuration table
function M.setup(opts)
  config.setup(opts)
  require("migrate.bindings").setup(config.get())
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
