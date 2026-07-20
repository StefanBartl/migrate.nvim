---@module 'migrate.common.command'
---@brief Generic command registration for migration tools.
---@description
--- Provides a unified command handler that supports:
---   - Line mode (no args, current line)
---   - Range mode (visual selection or explicit :1,5Command)
---   - Buffer mode (% argument)
---   - CWD mode (cwd argument)
--- Each migration type provides callbacks for scanning and applying.
---
--- Built on `lib.nvim.usercmd.composer` (a `path = {}` root route — a flat
--- grammar, no subcommand word). The route declares `args` purely to drive
--- `<Tab>` completion; dispatch bypasses composer's own bound `ctx.args` and
--- reads `ctx.raw` instead (composer's untouched nvim-callback opts — same
--- `.args`/`.range`/`.line1`/`.line2` shape the handler used before this
--- migration), since range takes precedence over the argument regardless of
--- what that argument is, and any argument beyond the first whitespace-run
--- token is silently ignored rather than erroring — behavior that predates
--- this migration and doesn't map onto composer's own positional binding.

require("migrate.common.@types")
local notify = require("lib.nvim.notify").create("[migrate]")
local composer = require("lib.nvim.usercmd.composer")

local M = {}

local api = vim.api
local str_fmt = string.format

-- Always offers both candidates, unfiltered by arg_lead -- matches the
-- pre-migration default completion (`function() return { "%", "cwd" } end`)
-- verbatim.
composer.register_type("MIGRATE_SCOPE", {
  validate = function(raw) return true, raw, nil end,
  complete = function() return { "%", "cwd" } end,
})

--- Run one migration invocation. `cmd_opts` is composer's `ctx.raw` (same
--- shape as the original nvim user-command callback opts).
---@param opts MigrateCommon.CommandOpts
---@param cmd_opts table
local function dispatch(opts, cmd_opts)
  local arg = cmd_opts.args:match("%S+")
  local bufnr = api.nvim_get_current_buf()

  -- Handle range mode (visual or explicit range)
  if cmd_opts.range > 0 then
    local matches = opts.scan_range(bufnr, cmd_opts.line1, cmd_opts.line2)

    if #matches == 0 then
      notify.warn("No matches in range")
      return
    end

    -- Apply directly (no picker for ranges)
    opts.apply_matches(matches)

    notify.info(str_fmt("Applied %d migration(s) in range", #matches))
    return
  end

  -- Handle argument-based modes
  if not arg or arg == "" then
    -- Current line mode
    local cursor = api.nvim_win_get_cursor(0)
    local matches = opts.scan_range(bufnr, cursor[1], cursor[1])

    if #matches == 0 then
      notify.warn("No matches on current line")
      return
    end

    -- Apply directly (no picker for single line)
    opts.apply_matches(matches)

    notify.info(str_fmt("Applied %d migration(s) on line %d", #matches, cursor[1]))

  elseif arg == "%" then
    -- Buffer mode with picker
    local matches = opts.scan_buffer(bufnr)

    if #matches == 0 then
      notify.warn("No matches in buffer")
      return
    end

    opts.show_picker(matches)

  elseif arg == "cwd" then
    -- CWD mode with picker
    local matches = opts.scan_cwd()

    if #matches == 0 then
      notify.warn("No matches in cwd")
      return
    end

    opts.show_picker(matches)

  else
    notify.error(str_fmt("Invalid argument: %s. Use: [empty], %%, or cwd", arg))
  end
end

--- Register migration command with unified behavior
---@param opts MigrateCommon.CommandOpts
function M.register(opts)
  composer.verb(opts.name, {
    desc = str_fmt("Migration tool: %s", opts.name),
    range = true,
    routes = {
      { path = {},
        args = { { name = "mode", type = "MIGRATE_SCOPE", optional = true } },
        range = true,
        desc  = str_fmt("Migration tool: %s", opts.name),
        run   = function(ctx) dispatch(opts, ctx.raw) end },
    },
  })
end

return M
