---@module 'migrate.hl.migrator'
---@brief Pure line-migration logic for `vim.highlight` -> `vim.hl` (no side effects).
---@description
--- `vim.highlight` was removed in favor of `vim.hl` with the same member
--- names (`range`, `on_yank`, `priorities`) -- confirmed against the
--- installed Neovim runtime: `lua/vim/hl.lua` exports exactly those three,
--- and `lua/vim/highlight.lua` no longer exists at all (a hard removal, not
--- merely a `vim.deprecate()`-warned shim). A blanket prefix rename is
--- therefore safe: any `vim.highlight.<member>` becomes `vim.hl.<member>`.

local M = {}

---Migrate a single line of text by replacing `vim.highlight.` with `vim.hl.`.
---@param line string The line to migrate
---@return string migrated The migrated line (unchanged if no match)
function M.migrate_line(line)
  return (line:gsub("vim%.highlight%.", "vim.hl."))
end

return M
