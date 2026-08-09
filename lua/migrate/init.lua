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
---
--- Every enabled module comes from `migrate.registry` -- see that module for
--- the full list (`opt`, `notify`, `hl`, `lsp`, and any third-party module
--- registered before `setup()` runs).

local config = require("migrate.config")
local registry = require("migrate.registry")

local M = {}

---Setup migration tools
---@param opts UsrCmds.Migrate.Config|nil Configuration table
function M.setup(opts)
  config.setup(opts)
  require("migrate.bindings").setup(config.get())

  -- One-time (persisted across restarts) popup on the first setup() after
  -- installing this plugin: which CLI tools it wants and why
  -- (docs/install.json). `:Lib deps show migrate.nvim` thereafter.
  -- `config.get().deps_popup = false` (set right in the setup() spec,
  -- config/DEFAULTS.lua) disables it for this plugin specifically. pcall'd:
  -- an older lib.nvim without lib.nvim.deps mustn't break setup() over an
  -- informational popup.
  if config.get().deps_popup ~= false then
    local ok_deps, deps = pcall(require, "lib.nvim.deps")
    if ok_deps then
      deps.show_once("migrate.nvim")
    end
  end
end

---Enable all registered migration tools (convenience function)
function M.enable_all()
  local opts = {}
  for name in pairs(registry.list()) do
    opts[name] = true
  end
  M.setup(opts)
end

---Disable all registered migration tools
function M.disable_all()
  for _, entry in pairs(registry.list()) do
    pcall(vim.api.nvim_del_user_command, entry.command)
  end
end

return M
