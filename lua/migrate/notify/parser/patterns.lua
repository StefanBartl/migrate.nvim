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

---Track fenced long-bracket string state (`[[ ]]`, `[=[ ]=]`, `[==[ ]==]`,
---...) across lines, so `vim.notify(...)` written inside a multiline string
---literal isn't mistaken for real code (docs/USAGE-EXAMPLES.md Edge Case 2).
---Naive/line-based like the rest of this parser: does not distinguish a
---bracket that's itself inside a quoted string or comment from a real long-
---string delimiter, and a line that closes a string then contains further
---code is still treated as fully "inside" for that line.
---@param line string
---@param level integer|nil Currently-open long-bracket level (nil = not inside one)
---@return boolean starts_inside_string Whether this line began already inside an open long string
---@return integer|nil new_level Open level after this line (nil = closed by end of line)
function M.track_long_string(line, level)
  local starts_inside = level ~= nil
  local pos = 1

  while true do
    if level then
      local close_start, close_end = line:find("%]" .. string.rep("=", level) .. "%]", pos)
      if not close_start then
        return starts_inside, level
      end
      level = nil
      pos = close_end + 1
    else
      local open_start, open_end, eqs = line:find("%[(=*)%[", pos)
      if not open_start then
        break
      end
      level = #eqs
      pos = open_end + 1
    end
  end

  return starts_inside, level
end

---Check if line contains vim.notify call
---@param line string
---@return boolean
function M.is_vim_notify(line)
  return line:match("vim%.notify%s*%(") ~= nil and not line:match("notify%.[a-z]+%s*%(")
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
  if line:match("require%s*%(%s*[\"']lib%.notify[\"']") then
    return false
  end

  -- Must have a second argument (the level)
  -- More precise: check for comma followed by level-like pattern
  -- This avoids matching: local notify = function(...) end
  if line:match("notify%s*%([^,)]+,%s*[^%)]+%)") then
    return true
  end

  -- Multiline call: notify( opens here without closing on this line (the
  -- level argument is on a later line, so the same-line comma check above
  -- can't see it yet -- let the caller's paren-counting extractor confirm).
  local start_pos = line:find("notify%s*%(")
  if start_pos then
    local depth = 0
    for i = start_pos, #line do
      local char = line:sub(i, i)
      if char == "(" then
        depth = depth + 1
      elseif char == ")" then
        depth = depth - 1
      end
    end
    if depth > 0 then
      return true
    end
  end

  return false
end

return M
