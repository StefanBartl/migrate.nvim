---@module 'migrate.health'
---@brief Health check for the migrate.nvim plugin
---@description
--- Run via `:checkhealth migrate`. Verifies that the core modules load, that the
--- required runtime dependencies (lib.nvim, telescope.nvim) are present, that
--- the optional `ripgrep` binary (used for cwd-wide scans) is available, and
--- reports the active configuration (incl. optional keymaps/which-key).

local M = {}

-- Neovim health integration (vim.health on 0.8+, legacy "health" otherwise)
local health = vim.health or require("health")

---Report a successful require, or an error, for a module.
---@param modname string
---@return boolean ok
local function check_module(modname)
  local ok = pcall(require, modname)
  if ok then
    health.ok(modname .. " loaded")
  else
    health.error(modname .. " failed to load")
  end
  return ok
end

---@return nil
function M.check()
  health.start("migrate.nvim")

  ---------------------------------------------------------------------------
  -- Core modules
  ---------------------------------------------------------------------------
  local core_ok = check_module("migrate")
  check_module("migrate.notify")
  check_module("migrate.opt")

  if not core_ok then
    health.error("Core module 'migrate' did not load — aborting further checks")
    return
  end

  ---------------------------------------------------------------------------
  -- Required dependencies
  ---------------------------------------------------------------------------
  if pcall(require, "lib.nvim.notify") then
    health.ok("lib.nvim is available")
  else
    health.error("lib.nvim not found (required) — install StefanBartl/lib.nvim")
  end

  if pcall(require, "lib.nvim.usercmd.composer") then
    health.ok("lib.nvim.usercmd.composer available (:MigrateOpt/:MigrateNotify)")
  else
    health.error("lib.nvim.usercmd.composer not found — commands will fail to register")
  end

  if pcall(require, "telescope") then
    health.ok("telescope.nvim is available (used for the interactive picker)")
  else
    health.error("telescope.nvim not found (required for '%' and 'cwd' picker modes)")
  end

  ---------------------------------------------------------------------------
  -- Optional external tools
  ---------------------------------------------------------------------------
  if vim.fn.executable("rg") == 1 then
    health.ok("ripgrep (rg) found — cwd-wide scanning enabled")
  else
    health.warn("ripgrep (rg) not found — ':MigrateOpt cwd' cannot scan the workspace")
  end

  ---------------------------------------------------------------------------
  -- Configuration
  ---------------------------------------------------------------------------
  local cfg_ok, config = pcall(require, "migrate.config")
  if cfg_ok then
    local cfg = config.get()
    health.info(string.format("opt=%s, notify=%s", tostring(cfg.opt), tostring(cfg.notify)))

    if type(cfg.keymaps) == "table" then
      health.info(
        string.format(
          "keymaps: opt=%s, notify=%s",
          tostring(cfg.keymaps.opt or false),
          tostring(cfg.keymaps.notify or false)
        )
      )

      if require("migrate.bindings.which_key").available() then
        health.ok("which-key detected (keymap descriptions are picked up automatically)")
      else
        health.info("which-key not found — keymaps still carry their own descriptions")
      end
    else
      health.info("keymaps: disabled (set `keymaps = { opt = ..., notify = ... }` to enable)")
    end
  else
    health.warn("migrate.config failed to load: " .. tostring(config))
  end
end

return M
