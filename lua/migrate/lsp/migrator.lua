---@module 'migrate.lsp.migrator'
---@brief Pure line-migration logic for deprecated LSP client-lookup calls (no side effects).
---@description
--- Ground-truthed against the installed Neovim runtime (`lua/vim/lsp.lua`):
--- of every `vim.lsp.buf_*` function, only `buf_get_clients()` carries an
--- `@deprecated` tag (-> `vim.lsp.get_clients()`, since 0.12). Its sibling
--- `get_active_clients()` is deprecated the same way and shares the same
--- replacement, so it's handled here too even though it isn't `buf_`-
--- prefixed. Other `lsp.buf_*` functions (`buf_request*`, `buf_notify`,
--- `buf_attach_client`, `buf_detach_client`, `buf_is_attached`) are NOT
--- deprecated and are left alone; `start_client`/`stop_client`/
--- `client_is_stopped`/`for_each_buffer_client` map onto a different call
--- shape (`Client:stop()`, a loop body, negation, ...) that doesn't fit a
--- safe line-regex rename and are out of scope here.

local M = {}

local str_fmt = string.format

-- Detect prefix used (vim.lsp., lsp., or nothing)
local prefix_map = {
  ["vim%.lsp%."] = "vim.lsp.",
  ["lsp%."] = "lsp.",
  [""] = "",
}

---Migrate a single line of text by replacing deprecated LSP client-lookup calls.
---@param line string The line to migrate
---@return string migrated The migrated line (unchanged if no match)
function M.migrate_line(line)
  local s = line

  -- buf_get_clients(bufnr) -> get_clients({ bufnr = bufnr })  (bufnr optional)
  for pattern_prefix, replacement_prefix in pairs(prefix_map) do
    s = s:gsub(pattern_prefix .. "buf_get_clients%(%s*([%w_%.%[%]:]-)%s*%)", function(bufexpr)
      local expr = bufexpr ~= "" and bufexpr or "0"
      return str_fmt("%sget_clients({ bufnr = %s })", replacement_prefix, expr)
    end)
  end

  -- get_active_clients(filter) -> get_clients(filter) -- name-only rename,
  -- argument list (if any) is left completely untouched.
  for pattern_prefix, replacement_prefix in pairs(prefix_map) do
    s = s:gsub(pattern_prefix .. "get_active_clients%(", replacement_prefix .. "get_clients(")
  end

  return s
end

return M
