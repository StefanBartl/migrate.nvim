---@module 'migrate.opt'
---@brief Migrate deprecated nvim_buf/win_get/set_option to nvim_get/set_option_value.
---@description
--- Refactored to use common migration infrastructure.
--- Supports: line, range, buffer (%), cwd modes.

local command = require("migrate.common.command")
local picker = require("migrate.common.picker")
local buffer_ops = require("migrate.common.buffer")
local migrator = require("migrate.opt.migrator")
local notify = require("lib.nvim.notify")

local M = {}

local api = vim.api
local fn = vim.fn
local str_fmt = string.format

local migrate_line_text = migrator.migrate_line

---Scan buffer range for matches
---@param bufnr integer
---@param line1 integer 1-based start
---@param line2 integer 1-based end
---@return MigrateCommon.Match[]
local function scan_range(bufnr, line1, line2)
  local matches = {}

  if not api.nvim_buf_is_valid(bufnr) then
    return matches
  end

  local lines = api.nvim_buf_get_lines(bufnr, line1 - 1, line2, false)
  local fname = api.nvim_buf_get_name(bufnr)

  for i, line in ipairs(lines) do
    local migrated = migrate_line_text(line)
    if migrated ~= line then
      table.insert(matches, {
        bufnr = bufnr,
        fname = fname ~= "" and fname or nil,
        lnum = line1 + i - 1,
        text = line,
        migrated = migrated,
        source = "buf",
      })
    end
  end

  return matches
end

---Scan entire buffer
---@param bufnr integer
---@return MigrateCommon.Match[]
local function scan_buffer(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return {}
  end

  local line_count = api.nvim_buf_line_count(bufnr)
  return scan_range(bufnr, 1, line_count)
end

---Scan cwd using ripgrep
---@return MigrateCommon.Match[]
local function scan_cwd()
  local matches = {}

  if fn.executable("rg") == 0 then
    notify.error("ripgrep (rg) not found")
    return matches
  end

  local pattern = "nvim_(buf|win)_(get|set)_option"
  local cmd = { "rg", "--vimgrep", "--no-heading", "--color=never", pattern }
  local result = fn.systemlist(cmd)

  if vim.v.shell_error ~= 0 then
    return matches
  end

  for _, line_raw in ipairs(result) do
    local fname, lnum_str, text = line_raw:match("^(.+):(%d+):%d+:(.*)$")
    if fname and lnum_str and text then
      local migrated = migrate_line_text(text)
      if migrated ~= text then
        table.insert(matches, {
          bufnr = nil,
          fname = fname,
          lnum = tonumber(lnum_str),
          text = text,
          migrated = migrated,
          source = "file",
        })
      end
    end
  end

  return matches
end

---Apply migrations
---@param matches MigrateCommon.Match[]
local function apply_matches(matches)
  for _, match in ipairs(matches) do
    if match.source == "buf" then
      buffer_ops.replace_line(match.bufnr, match.lnum, match.migrated)
    else
      buffer_ops.replace_in_file(match.fname, match.lnum, match.migrated)
    end
  end
end

---Show picker with matches
---@param matches MigrateCommon.Match[]
local function show_picker_impl(matches)
  picker.show(matches, {
    title = "Migrate Option API",
    single_apply = true,

    format_entry = function(match)
      local location = match.fname and (vim.fn.fnamemodify(match.fname, ":t") .. ":" .. match.lnum)
        or ("buf:" .. match.bufnr .. ":" .. match.lnum)

      return str_fmt("%s  %s", location, match.text:sub(1, 60))
    end,

    format_preview = function(match)
      return { match.migrated }
    end,

    on_apply = function(selections)
      apply_matches(selections)
      notify.info(str_fmt("Applied %d migration(s)", #selections))
    end,
  })
end

--- Enable command
function M.enable()
  command.register({
    name = "MigrateOpt",
    scan_range = scan_range,
    scan_buffer = scan_buffer,
    scan_cwd = scan_cwd,
    apply_matches = apply_matches,
    show_picker = show_picker_impl,
  })
end

return M
