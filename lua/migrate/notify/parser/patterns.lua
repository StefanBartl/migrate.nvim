---@module 'migrate.notify.parser.patterns'
---@brief Pattern matching and line validation

local M = {}

---Check if line should be processed (not in comment)
---@param line string
---@return boolean
function M.is_processable(line)
  local trimmed = line:match("^%s*(.-)%s*$")
  -- Skip comments
  if trimmed:match("^%-%-") then
    return false
  end
  return true
end

---Check if line contains vim.notify call
---@param line string
---@return boolean
function M.is_vim_notify(line)
  return line:match("vim%.notify%s*%(") ~= nil
    and not line:match("notify%.[a-z]+%s*%(")
end

---Check if line contains aliased notify call
---@param line string
---@param notify_alias string
---@return boolean
function M.is_aliased_notify(line, notify_alias)
  if not notify_alias then
    return false
  end

  -- Escape special pattern characters in alias name
  local escaped = notify_alias:gsub("([%.%-%+%*%?%[%]%^%$%(%)%%])", "%%%1")

  -- Pattern: notify_alias( but NOT notify_alias.level(
  local pattern = escaped .. "%s*%("
  local neg_pattern = escaped .. "%.[a-z]+%s*%("

  return line:match(pattern) and not line:match(neg_pattern)
end

---NEW: Check if line contains existing notify() call (not vim.notify, not aliased)
---This catches standalone notify("...", level) calls
---@param line string
---@return boolean
function M.is_existing_notify(line)
  -- Must contain notify(
  if not line:match("notify%s*%(") then
    return false
  end

  -- But NOT vim.notify
  if line:match("vim%.notify%s*%(") then
    return false
  end

  -- And NOT already migrated (notify.level()
  if line:match("notify%.[a-z]+%s*%(") then
    return false
  end

  -- And NOT lib.notify require/create
  if line:match('require%s*%(%s*["\']lib%.notify["\']') then
    return false
  end

  -- Must have a second argument (the level)
  -- More precise: check for comma followed by level-like pattern
  -- This avoids matching: local notify = function(...) end
  if line:match("notify%s*%([^,)]+,%s*[^%)]+%)") then
    return true
  end

  return false
end

return M
