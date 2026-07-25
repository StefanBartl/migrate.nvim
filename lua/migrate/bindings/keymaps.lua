---@module 'migrate.bindings.keymaps'
---@brief Optional keymaps invoking the migration commands on the current line.
---@description
--- Disabled by default (`config.keymaps = false`). Set to a table to enable,
--- keyed the same as `migrate.registry`'s entries:
---   keymaps = { opt = "<leader>mo", notify = "<leader>mn" }
--- Each entry runs its command with no argument, i.e. the current-line mode
--- (see docs/BINDINGS.md). which-key (if installed) picks up the `desc` on
--- each mapping automatically -- no group registration needed.

local map = require("lib.nvim.map")
local registry = require("migrate.registry")

local M = {}

---@param cfg UsrCmds.Migrate.Config
---@return nil
function M.setup(cfg)
  local km = cfg.keymaps
  if type(km) ~= "table" then
    return
  end

  for name, entry in pairs(registry.list()) do
    if km[name] then
      map(
        "n",
        km[name],
        string.format("<cmd>%s<cr>", entry.command),
        {},
        string.format("migrate: run :%s (current line)", entry.command)
      )
    end
  end
end

return M
