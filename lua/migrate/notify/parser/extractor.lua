---@module 'migrate.notify.parser.extractor'
---@brief Extract function calls from lines

local M = {}

---Find closing parenthesis for multiline call
---@param lines string[]
---@param start_idx integer
---@return integer|nil end_idx
function M.find_call_end(lines, start_idx)
  local paren_count = 0
  local start_line = lines[start_idx]

  for char in start_line:gmatch(".") do
    if char == "(" then
      paren_count = paren_count + 1
    elseif char == ")" then
      paren_count = paren_count - 1
      if paren_count == 0 then
        return start_idx
      end
    end
  end

  for i = start_idx + 1, #lines do
    local line = lines[i]
    for char in line:gmatch(".") do
      if char == "(" then
        paren_count = paren_count + 1
      elseif char == ")" then
        paren_count = paren_count - 1
        if paren_count == 0 then
          return i
        end
      end
    end
  end

  return nil
end

---Extract vim.notify call
---@param line string
---@return string|nil call_text, integer|nil start_col, integer|nil end_col
function M.extract_vim_notify(line)
  local start_pos = line:find("vim%.notify%s*%(")
  if not start_pos then
    return nil, nil, nil
  end

  local paren_count = 0
  local in_call = false
  local end_pos = nil

  for i = start_pos, #line do
    local char = line:sub(i, i)

    if char == "(" then
      paren_count = paren_count + 1
      in_call = true
    elseif char == ")" then
      paren_count = paren_count - 1

      if in_call and paren_count == 0 then
        end_pos = i
        break
      end
    end
  end

  if not end_pos then
    return nil, nil, nil
  end

  local call_text = line:sub(start_pos, end_pos)
  return call_text, start_pos - 1, end_pos
end

---Extract aliased notify call
---@param line string
---@param notify_alias string
---@return string|nil call_text, integer|nil start_col, integer|nil end_col
function M.extract_aliased(line, notify_alias)
  if not notify_alias then
    return nil, nil, nil
  end

  local start_pos = line:find(notify_alias .. "%s*%(")
  if not start_pos then
    return nil, nil, nil
  end

  local paren_count = 0
  local in_call = false
  local end_pos = nil

  for i = start_pos, #line do
    local char = line:sub(i, i)

    if char == "(" then
      paren_count = paren_count + 1
      in_call = true
    elseif char == ")" then
      paren_count = paren_count - 1

      if in_call and paren_count == 0 then
        end_pos = i
        break
      end
    end
  end

  if not end_pos then
    return nil, nil, nil
  end

  local call_text = line:sub(start_pos, end_pos)
  return call_text, start_pos - 1, end_pos
end

return M
