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
--- Built on `lib.nvim.bindings.usercmd.composer` (a `path = {}` root route — a flat
--- grammar, no subcommand word). The route declares `args` purely to drive
--- `<Tab>` completion; dispatch bypasses composer's own bound `ctx.args` and
--- reads `ctx.raw` instead (composer's untouched nvim-callback opts — same
--- `.args`/`.range`/`.line1`/`.line2` shape the handler used before this
--- migration), since range takes precedence over the argument regardless of
--- what that argument is, and any argument beyond the first whitespace-run
--- token is silently ignored rather than erroring — behavior that predates
--- this migration and doesn't map onto composer's own positional binding.
---@see migrate.opt
---@see migrate.hl
---@see migrate.lsp
---@see migrate.registry

require("migrate.common.@types")
local notify = require("lib.nvim.notify").create("[migrate]")
local composer = require("lib.nvim.bindings.usercmd.composer")
local debug = require("migrate.common.debug")

local M = {}

local api = vim.api
local str_fmt = string.format

-- Always offers both candidates, unfiltered by arg_lead -- matches the
-- pre-migration default completion (`function() return { "%", "cwd" } end`)
-- verbatim.
composer.register_type("MIGRATE_SCOPE", {
  validate = function(raw)
    return true, raw, nil
  end,
  complete = function()
    return { "%", "cwd" }
  end,
})

---@internal
--- Report what a migration *would* do, without touching the buffer.
---
--- Only the line and range modes need this: `%` and `cwd` already go through
--- a picker, which is a preview with an apply step. Line and range apply
--- straight away, which is exactly where "show me first" was missing.
---
--- Each match carries both `text` and `migrated`, so the report is the real
--- before/after rather than a description of one.
---@param opts MigrateCommon.CommandOpts
---@param matches MigrateCommon.Match[]
---@param what string  # e.g. "on line 12" / "in range"
---@return nil
local function report_dry_run(opts, matches, what)
  local lines =
    { str_fmt("%s — %d migration(s) %s, nothing applied:", opts.name, #matches, what) }
  for _, m in ipairs(matches) do
    lines[#lines + 1] = str_fmt("  %d: %s", m.lnum, vim.trim(m.text or ""))
    lines[#lines + 1] =
      str_fmt("  %s  %s", (" "):rep(#tostring(m.lnum)), vim.trim(m.migrated or ""))
  end
  notify.info(table.concat(lines, "\n"))
end

---@internal
--- Run one migration invocation. `cmd_opts` is composer's `ctx.raw` (same
--- shape as the original nvim user-command callback opts).
---@param opts MigrateCommon.CommandOpts
---@param cmd_opts table
---@param arg string|nil  # the parsed scope positional (`%`/`cwd`), never the
---       raw argument string: that still carries any flags, so re-parsing it
---       here made `--dry-run` look like an invalid scope.
---@param dry_run boolean|nil  # report instead of applying (line/range modes)
---@return nil
local function dispatch(opts, cmd_opts, arg, dry_run)
  local bufnr = api.nvim_get_current_buf()

  -- Handle range mode (visual or explicit range)
  if cmd_opts.range > 0 then
    debug.trace("[%s] scan_range %d-%d", opts.name, cmd_opts.line1, cmd_opts.line2)
    local matches = opts.scan_range(bufnr, cmd_opts.line1, cmd_opts.line2)

    if #matches == 0 then
      notify.warn("No matches in range")
      return
    end

    if dry_run then
      report_dry_run(opts, matches, "in range")
      return
    end

    -- Apply directly (no picker for ranges)
    debug.trace("[%s] apply %d match(es) (range)", opts.name, #matches)
    opts.apply_matches(matches)

    notify.info(str_fmt("Applied %d migration(s) in range", #matches))
    return
  end

  -- Handle argument-based modes
  if not arg or arg == "" then
    -- Current line mode
    local cursor = api.nvim_win_get_cursor(0)
    debug.trace("[%s] scan_range line=%d (current line)", opts.name, cursor[1])
    local matches = opts.scan_range(bufnr, cursor[1], cursor[1])

    if #matches == 0 then
      notify.warn("No matches on current line")
      return
    end

    if dry_run then
      report_dry_run(opts, matches, str_fmt("on line %d", cursor[1]))
      return
    end

    -- Apply directly (no picker for single line)
    debug.trace("[%s] apply %d match(es) (line)", opts.name, #matches)
    opts.apply_matches(matches)

    notify.info(str_fmt("Applied %d migration(s) on line %d", #matches, cursor[1]))
  elseif arg == "%" then
    -- Buffer mode with picker
    debug.trace("[%s] scan_buffer", opts.name)
    local matches = opts.scan_buffer(bufnr)

    if #matches == 0 then
      notify.warn("No matches in buffer")
      return
    end

    debug.trace("[%s] show_picker %d match(es) (buffer)", opts.name, #matches)
    opts.show_picker(matches)
  elseif arg == "cwd" then
    -- CWD mode with picker
    debug.trace("[%s] scan_cwd", opts.name)
    local matches = opts.scan_cwd()

    if #matches == 0 then
      notify.warn("No matches in cwd")
      return
    end

    debug.trace("[%s] show_picker %d match(es) (cwd)", opts.name, #matches)
    opts.show_picker(matches)
  else
    notify.error(str_fmt("Invalid argument: %s. Use: [empty], %%, or cwd", arg))
  end
end

--- Register migration command with unified behavior
---@param opts MigrateCommon.CommandOpts
function M.register(opts)
  composer.verb(opts.name, {
    desc = str_fmt("Migration tool: %s  [%%|cwd] [-n|--dry-run]", opts.name),
    range = true,
    routes = {
      {
        path = {},
        args = { { name = "mode", type = "MIGRATE_SCOPE", optional = true } },
        flags = {
          -- Only meaningful for the line and range modes; `%`/`cwd` already
          -- preview through their picker. Accepted there too rather than
          -- rejected, so a mapping can pass it unconditionally.
          { name = "dry-run", short = "n", bool = true },
        },
        range = true,
        desc = str_fmt("Migration tool: %s", opts.name),
        run = function(ctx)
          dispatch(opts, ctx.raw, ctx.args.mode, ctx.flags["dry-run"])
        end,
      },
    },
  })
end

return M
