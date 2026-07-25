---@module 'migrate.bindings.usrcmds'
---@brief Enables each registered migration module's command based on config.
---@description
--- Each module owns its own scan/apply/picker logic (see `migrate.opt`,
--- `migrate.notify`, `migrate.hl`, `migrate.lsp`) and registers its own user
--- command; this module only decides *which* of them get enabled for a
--- given config, driven entirely by `migrate.registry` -- adding a module
--- here is just registering it there.

local notify = require("lib.nvim.notify").create("[migrate.bindings.usrcmds]")
local registry = require("migrate.registry")

local M = {}

---@param cfg UsrCmds.Migrate.Config
---@return nil
function M.setup(cfg)
  for name, entry in pairs(registry.list()) do
    if cfg[name] then
      local ok, mod = pcall(require, entry.module)
      if ok then
        mod.enable()
      else
        notify.warn(string.format("Failed to load %s module: %s", name, tostring(mod)))
      end
    end
  end
end

return M
