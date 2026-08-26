---@module 'migrate.bindings.keymaps'
---@brief Optional keymaps invoking the migration commands on the current line.
---@description
--- Disabled by default (`config.keymaps = false`). Set to a table to enable,
--- keyed the same as `migrate.registry`'s entries:
---   keymaps = { opt = "<leader>mo", notify = "<leader>mn" }
--- Each entry runs its command with no argument, i.e. the current-line mode
--- (see docs/BINDINGS.md). which-key (if installed) picks up the `desc` on
--- each mapping automatically -- no group registration needed.
---
--- **A count migrates that many lines.** `3<leader>mo` runs the command over
--- the cursor line and the two below it, as an explicit `:{line1},{line2}`
--- range -- the same range mode a Visual selection produces, so it applies
--- directly with no picker, exactly like the single-line case it generalizes.
---
--- The command was range-capable all along; nothing was passing it one from a
--- keymap. A count is spelled as a range rather than left to Vim's own
--- count-to-address translation, because `:3Migrate` would mean "line 3", not
--- "three lines from here".

local keymap = require("lib.nvim.bindings.keymap")
local registry = require("migrate.registry")

local M = {}

---@param cfg UsrCmds.Migrate.Config
---@return Lib.Keymap.Registered[]|nil
function M.setup(cfg)
  local km = cfg.keymaps
  if type(km) ~= "table" then
    return
  end

  local count = require("lib.nvim.count")

  ---@type table<string, Lib.Keymap.Action>
  local actions = {}
  ---@type string[]
  local order = {}

  for name, entry in pairs(registry.list()) do
    actions[name] = {
      rhs = function()
        local n = count.get()
        if n <= 1 then
          vim.cmd(entry.command)
          return
        end

        local line = vim.api.nvim_win_get_cursor(0)[1]
        local last = math.min(line + n - 1, vim.api.nvim_buf_line_count(0))
        vim.cmd(string.format("%d,%d%s", line, last, entry.command))
      end,
      desc = string.format("run :%s (current line, or N with a count)", entry.command),
    }
    order[#order + 1] = name
  end
  table.sort(order)

  -- No defaults: every entry is unset until a user names a key, so setting one
  -- is what claims it. Declared through the registry all the same, which is
  -- what turns a mistyped entry name from a silently dead keymap into a
  -- reported one -- and the names come from `migrate.registry`, so a new
  -- migration is mappable with no second list to update.
  return keymap.register("migrate", { order = order, actions = actions }, km)
end

return M
