---@module 'migrate.@types'

--=== migrate

---@class UsrCmds.Migrate.Config
---@field opt boolean|nil Enable option API migration (:MigrateOpt)
---@field notify boolean|nil Enable notify migration (:MigrateNotify)
---@field hl boolean|nil Enable vim.highlight -> vim.hl migration (:MigrateHl)
---@field lsp boolean|nil Enable vim.lsp.buf_get_clients/get_active_clients migration (:MigrateLsp)
---@field keymaps UsrCmds.Migrate.Keymaps|false|nil Optional keymaps (default: false = disabled)
---@field debug boolean|nil Trace the scan -> picker -> apply -> write pipeline (default: false)
---@field deps_popup boolean|nil Show the lib.nvim.deps "declared tools" popup once, ever, on first setup() after install (default true; needs lib.nvim.deps — a no-op without it)

---@class UsrCmds.Migrate.Keymaps
---@field opt string|false|nil Keymap that runs :MigrateOpt (current line)
---@field notify string|false|nil Keymap that runs :MigrateNotify (current line)
---@field hl string|false|nil Keymap that runs :MigrateHl (current line)
---@field lsp string|false|nil Keymap that runs :MigrateLsp (current line)

--=== notify

---@class UsrCmds.Migrate.Notify.Match
---@field line integer           # 1-based line number (start)
---@field col integer            # 0-based byte column (start)
---@field end_line integer       # 1-based line number (end, may differ for multiline)
---@field end_col integer        # 0-based byte end column
---@field original? string        # Original call (e.g. "vim.notify(...)")
---@field replacement string     # Target call (e.g. "notify.info(...)")
---@field log_level? LogLevelString

return {}
