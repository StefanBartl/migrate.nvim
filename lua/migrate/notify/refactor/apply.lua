---@module 'migrate.notify.refactor.apply'
---@brief Apply match replacements

local M = {}

local api = vim.api

---Apply single match replacement
---@param bufnr integer
---@param match UsrCmds.Migrate.Notify.Match
---@return boolean success
function M.apply_match(bufnr, match)
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local start_line = match.line
  local end_line = match.end_line

  if start_line == end_line then
    local start_idx = start_line - 1
    local end_idx = start_line

    local success =
      pcall(api.nvim_buf_set_lines, bufnr, start_idx, end_idx, false, { match.replacement })

    return success
  else
    local start_idx = start_line - 1
    local end_idx = end_line

    local success =
      pcall(api.nvim_buf_set_lines, bufnr, start_idx, end_idx, false, { match.replacement })

    return success
  end
end

return M
