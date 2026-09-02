---@module 'migrate.hover'
---@brief Tell hover.nvim that the line under the cursor uses a deprecated API.
---@description
--- [hover.nvim](https://github.com/StefanBartl/hover.nvim) previews what the
--- cursor points at: a file, a picture, a PDF page, a URL. This module
--- answers a different question in the same float — not *what does this point
--- at* but *is there anything to say about this line* — through hover.nvim's
--- `positions` contribution, which exists for exactly that.
---
--- **Why this pairing is a good one, and it is worth being precise about
--- why.** The standing objection to an automatic preview is noise: a float
--- that opens unasked is unwelcome unless it says something the line does not
--- already say. That objection does not apply here. `migrate_line` returns
--- the line unchanged unless the line genuinely uses a deprecated call, so
--- this answers on the small set of lines where there is something to report
--- and stays silent everywhere else. No shape heuristic, no volume switch
--- needed, no "documentation is made of links" problem.
---
--- **It is the same function `:Migrate lsp` uses.** Not a second
--- implementation of the rules, and not a copy of the patterns: if the
--- migrator learns a new deprecation, the hover learns it in the same commit.
--- A separate rule table here would be a second source of truth that can fall
--- behind the first one silently.
---
--- **Soft, in both directions.** hover.nvim is not a dependency of this
--- plugin: `setup` `pcall`s for it and does nothing when it is absent.
--- hover.nvim in turn never names migrate.nvim -- it takes the contribution
--- through its registry and would not notice a sixth contributor.
---
---@see migrate.lsp.migrator

local M = {}

local api = vim.api

---@type boolean Registered once; a second setup() must not stack a second one.
local _registered = false

---@internal
--- What to put in the float for a line that migrates.
---@param migrated string
---@return string[]
local function lines_for(migrated)
  return {
    "deprecated API on this line",
    "",
    "now:  " .. vim.trim(migrated),
    "",
    "`:Migrate lsp` rewrites it, here or across the buffer.",
  }
end

--- Register the position preview with hover.nvim, if it is installed.
---
--- Idempotent: hover.nvim keys contributions by plugin name, so calling this
--- twice replaces rather than stacks -- but the guard here also keeps a
--- second `setup()` from doing the work at all.
---@return boolean registered
function M.setup()
  if _registered then
    return true
  end

  local ok, registry = pcall(require, "hover.registry")
  if not ok or type(registry) ~= "table" or type(registry.register) ~= "function" then
    return false
  end
  -- An older hover.nvim has a registry but not this contribution kind. It
  -- would silently ignore `positions`, which reads as "the feature does not
  -- work" rather than as "your hover.nvim predates it".
  if type(registry.position_at) ~= "function" then
    return false
  end

  registry.register("migrate.nvim", {
    positions = {
      ---@param bufnr integer
      ---@param row integer 1-based
      ---@return table|nil
      function(bufnr, row)
        if not api.nvim_buf_is_valid(bufnr) then
          return nil
        end
        -- Only where a deprecated call could be written. A prose buffer is
        -- not going to contain `vim.lsp.buf_get_clients`, and reading the
        -- line is cheaper than migrating it.
        local line = api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
        if type(line) ~= "string" or line == "" then
          return nil
        end

        local ok_mig, migrated = pcall(require("migrate.lsp.migrator").migrate_line, line)
        if not ok_mig or type(migrated) ~= "string" or migrated == line then
          return nil
        end

        return { lines = lines_for(migrated), title = "migrate.nvim" }
      end,
    },
  })

  _registered = true
  return true
end

---@internal
--- Forget the registration. Tests only -- `setup` is otherwise a one-way
--- door within a session, which is what makes it idempotent.
---@return nil
function M._reset()
  _registered = false
end

return M
