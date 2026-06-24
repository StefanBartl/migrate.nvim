---@module 'migrate.notify.parser.aliases'
---@brief Detect notify and levels aliases

local M = {}

local api = vim.api

---Detect notify and levels aliases at top of file
---@param bufnr integer
---@return string|nil notify_alias, string|nil levels_alias
function M.detect(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, 50, false)

  local notify_alias = nil
  local levels_alias = nil

  for _, line in ipairs(lines) do
    -- Pattern 1: local notify, levels = vim.notify, vim.log.levels
    -- Make pattern more flexible with %s* for optional whitespace
    local n, l = line:match(
      "local%s+([%w_]+)%s*,%s*([%w_]+)%s*=%s*vim%.notify%s*,%s*vim%.log%.levels"
    )
    if n and l then
      notify_alias = n
      levels_alias = l
    end

    -- Pattern 2: local notify = vim.notify (standalone)
    if not notify_alias then
      local match = line:match("local%s+([%w_]+)%s*=%s*vim%.notify%s*$")
      if match then
        notify_alias = match
      end
    end

    -- Pattern 3: local levels = vim.log.levels (standalone)
    if not levels_alias then
      local match = line:match("local%s+([%w_]+)%s*=%s*vim%.log%.levels%s*$")
      if match then
        levels_alias = match
      end
    end

    -- Stop after first function definition (but allow local M = {})
    if line:match("^function%s") then
      break
    end
  end

  return notify_alias, levels_alias
end

return M
