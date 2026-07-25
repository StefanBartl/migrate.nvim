---@module 'migrate.registry'
---@brief Registry of pluggable migration modules.
---@description
--- Single place mapping a config key (e.g. "opt") to the migration module
--- that implements it. Built-ins register themselves below; a third-party
--- module can add itself the same way with `M.register()` before calling
--- `require("migrate").setup()`. `migrate.config.DEFAULTS`,
--- `migrate.bindings.usrcmds`, `migrate.bindings.keymaps`, `migrate.health`,
--- and `migrate.init`'s `enable_all()`/`disable_all()` all iterate this
--- table instead of naming individual modules by hand -- registering here
--- is the only wiring a new migration module needs.

local M = {}

---@class Migrate.RegistryEntry
---@field module string   Module path passed to `require()`; must expose `enable()`.
---@field command string  User command name it registers (used by `disable_all()`).
---@field desc string     One-line description (health check / doc generation).

---@type table<string, Migrate.RegistryEntry>
local modules = {}

---Register a migration module under `name` (the config/keymaps key it's
---toggled by, e.g. "opt").
---@param name string
---@param entry Migrate.RegistryEntry
---@return nil
function M.register(name, entry)
  modules[name] = entry
end

---@return table<string, Migrate.RegistryEntry>
function M.list()
  return modules
end

M.register("opt", {
  module = "migrate.opt",
  command = "MigrateOpt",
  desc = "nvim_{buf,win}_{get,set}_option() -> nvim_{get,set}_option_value()",
})

M.register("notify", {
  module = "migrate.notify",
  command = "MigrateNotify",
  desc = "vim.notify(...) (incl. aliased/existing notify(...)) -> lib.nvim.notify",
})

M.register("hl", {
  module = "migrate.hl",
  command = "MigrateHl",
  desc = "vim.highlight.{range,on_yank,priorities} -> vim.hl.*",
})

M.register("lsp", {
  module = "migrate.lsp",
  command = "MigrateLsp",
  desc = "vim.lsp.buf_get_clients()/get_active_clients() -> vim.lsp.get_clients()",
})

return M
