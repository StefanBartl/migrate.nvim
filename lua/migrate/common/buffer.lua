---@module 'migrate.common.buffer'
---@brief Buffer and file operation helpers for migrations.
---@description
--- Provides safe operations for:
---   - Line replacement (single/multiline)
---   - File read/write
---   - Undo point management
---   - File discovery

require("migrate.common.@types")

local M = {}

local api, fn = vim.api, vim.fn

--- Apply line replacement in buffer
---@param bufnr integer
---@param start_line integer 1-based
---@param end_line integer 1-based
---@param replacement string[] New lines
---@return boolean success
function M.replace_lines(bufnr, start_line, end_line, replacement)
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local start_idx = start_line - 1
  local end_idx = end_line

  return pcall(api.nvim_buf_set_lines, bufnr, start_idx, end_idx, false, replacement)
end

--- Apply single line replacement in buffer
---@param bufnr integer
---@param line_num integer 1-based
---@param replacement string New line content
---@return boolean success
function M.replace_line(bufnr, line_num, replacement)
  return M.replace_lines(bufnr, line_num, line_num, { replacement })
end

--- Apply replacement to file (read, modify, write)
---@param filepath string
---@param line_num integer 1-based
---@param replacement string New line content
---@return boolean success
function M.replace_in_file(filepath, line_num, replacement)
  local lines = fn.readfile(filepath)

  if line_num < 1 or line_num > #lines then
    return false
  end

  lines[line_num] = replacement

  local result = fn.writefile(lines, filepath)
  return result == 0
end

--- Create undo point in buffer
---@param bufnr integer
function M.create_undo_point(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end

  api.nvim_buf_call(bufnr, function()
    pcall(vim.cmd, "undojoin")
  end)
end

--- Check if file exists and is writable
---@param filepath string
---@return boolean writable
function M.is_writable(filepath)
  local stat = vim.uv.fs_stat(filepath)
  if not stat then
    return false
  end

  -- Check write permission by attempting to open
  local file = io.open(filepath, "a")
  if file then
    file:close()
    return true
  end

  return false
end

--- Get all Lua files in directory (recursive)
---@param dir string
---@return string[] filepaths
function M.find_lua_files(dir)
  return fn.globpath(dir, "**/*.lua", false, true)
end

--- Load buffer for file if not already loaded
---@param filepath string
---@return integer|nil bufnr
function M.ensure_buffer(filepath)
  local ok, bufnr_or_err = require("lib.nvim.buffer.open_background")(filepath)
  if not ok then
    return nil
  end
  return bufnr_or_err
end

return M
