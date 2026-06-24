---@module 'migrate.common.command'
---@brief Generic command registration for migration tools.
---@description
--- Provides a unified command handler that supports:
---   - Line mode (no args, current line)
---   - Range mode (visual selection or explicit :1,5Command)
---   - Buffer mode (% argument)
---   - CWD mode (cwd argument)
---   - Custom completion function per module
--- Each migration type provides callbacks for scanning and applying.

require("migrate.common.@types")
local notify = require("lib.nvim.notify").create("[migrate]")

local M = {}

local api = vim.api
local str_fmt = string.format

--- Register migration command with unified behavior
---@param opts MigrateCommon.CommandOpts
function M.register(opts)
  api.nvim_create_user_command(opts.name, function(cmd_opts)
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
  end, {
    nargs = "?",
    range = true,
    desc = str_fmt("Migration tool: %s", opts.name),
    complete = opts.complete or function()
      -- Default completion
      return { "%", "cwd" }
    end,
  })
end

return M
