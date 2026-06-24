---@module 'migrate.notify.refactor.cleanup'
---@brief Remove old aliases

local M = {}

local api = vim.api

---Detect and remove old notify/levels aliases
---@param bufnr integer
---@return boolean removed True if aliases were removed
function M.remove_aliases(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, 50, false)
  local lines_to_remove = {}

  for i, line in ipairs(lines) do
    -- Pattern 1: local notify, levels = vim.notify, vim.log.levels
    if line:match("local%s+[%w_]+%s*,%s*[%w_]+%s*=%s*vim%.notify%s*,%s*vim%.log%.levels") then
      table.insert(lines_to_remove, i)
    end

    -- Pattern 2: local notify = vim.notify
    if line:match("local%s+[%w_]+%s*=%s*vim%.notify%s*$") then
      table.insert(lines_to_remove, i)
    end

    -- Pattern 3: local levels = vim.log.levels
    if line:match("local%s+[%w_]+%s*=%s*vim%.log%.levels%s*$") then
      table.insert(lines_to_remove, i)
    end
  end

  -- Remove in reverse order to avoid offset issues
  table.sort(lines_to_remove, function(a, b) return a > b end)

  for _, line_num in ipairs(lines_to_remove) do
    api.nvim_buf_set_lines(bufnr, line_num - 1, line_num, false, {})
  end

  return #lines_to_remove > 0
end

return M
