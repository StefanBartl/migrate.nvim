---@module 'migrate.bindings.keymaps'
---@brief Optional keymaps invoking the migration commands on the current line.
---@description
--- Disabled by default (`config.keymaps = false`). Set to a table to enable:
---   keymaps = { opt = "<leader>mo", notify = "<leader>mn" }
--- Each entry runs `:MigrateOpt` / `:MigrateNotify` with no argument, i.e. the
--- current-line mode (see docs/BINDINGS.md). which-key (if installed) picks up
--- the `desc` on each mapping automatically -- no group registration needed.

local map = require("lib.nvim.map")

local M = {}

---@param cfg UsrCmds.Migrate.Config
---@return nil
function M.setup(cfg)
  local km = cfg.keymaps
  if type(km) ~= "table" then
    return
  end

  if km.opt then
    map("n", km.opt, "<cmd>MigrateOpt<cr>", {}, "migrate: run :MigrateOpt (current line)")
  end

  if km.notify then
    map("n", km.notify, "<cmd>MigrateNotify<cr>", {}, "migrate: run :MigrateNotify (current line)")
  end
end

return M
