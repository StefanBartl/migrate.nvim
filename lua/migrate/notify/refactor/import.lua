---@module 'migrate.notify.refactor.import'
---@brief Handle import injection and upgrades

local M = {}

local api = vim.api

---Check what kind of import exists
---@param bufnr integer
---@return boolean has_simple, boolean has_create, integer|nil import_line
local function check_import(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, 50, false)

  local has_simple = false
  local has_create = false
  local import_line = nil

  for i, line in ipairs(lines) do
    if line:match('local%s+notify%s*=%s*require%s*%(%s*["\']lib%.notify["\']%s*%)') then
      has_simple = true
      import_line = i

      if line:match('%.create%s*%(') then
        has_create = true
      end
    end
  end

  return has_simple, has_create, import_line
end

---Find first non-comment line
---@param bufnr integer
---@return integer line_idx 0-based index
local function find_first_code_line(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed ~= "" and not trimmed:match("^%-%-") then
      return i - 1
    end
  end

  return 0
end

---Inject or upgrade import with auto-detected module path
---@param bufnr integer
---@param module_name string|nil Optional override module name
---@return boolean added True if import was added or modified
function M.inject(bufnr, module_name)
  local has_simple, has_create, import_line = check_import(bufnr)

  -- If no module_name provided, auto-detect from buffer path
  if not module_name or module_name == "" then
    local fname = api.nvim_buf_get_name(bufnr)

    if fname ~= "" then
      local ok, get_module_path = pcall(require, "lib.nvim.lua_ls.get_module_path")
      if ok then
        module_name = get_module_path(fname)
      end
    else
    end
  end

  -- Determine what import line to use
  local import_str
  if module_name and module_name ~= "" then
    import_str = string.format('local notify = require("lib.nvim.notify").create("[%s]")', module_name)
  else
    import_str = 'local notify = require("lib.nvim.notify").create("")'
  end

  -- If we already have exactly this import, nothing to do
  if has_simple and import_line then
    local lines = api.nvim_buf_get_lines(bufnr, import_line - 1, import_line, false)
    if lines[1] == import_str then
      return false
    end
  end

  -- If we have .create() with different module name, update it
  if has_create and import_line then
    api.nvim_buf_set_lines(bufnr, import_line - 1, import_line, false, { import_str })
    return true
  end

  -- If we have simple import, upgrade it
  if has_simple and import_line then
    api.nvim_buf_set_lines(bufnr, import_line - 1, import_line, false, { import_str })
    return true
  end

  -- No import exists, add new one
  local insert_pos = find_first_code_line(bufnr)
  api.nvim_buf_set_lines(
    bufnr,
    insert_pos,
    insert_pos,
    false,
    { import_str, "" }
  )
  return true
end

return M
