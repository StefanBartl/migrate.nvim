---@module 'migrate.health'
---@brief Health check for the migrate.nvim plugin
---@description
--- Run via `:checkhealth migrate`. Verifies that the core modules load, that the
--- required runtime dependencies (lib.nvim, telescope.nvim) are present, that
--- the optional `ripgrep` binary (used for cwd-wide scans) is available, and
--- reports the active configuration (incl. optional keymaps/which-key).
---@see migrate.registry

local M = {}

-- Neovim health integration (vim.health on 0.8+, legacy "health" otherwise)
local health = vim.health or require("health")

---@internal
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

  local registry = require("migrate.registry")

  ---------------------------------------------------------------------------
  -- Core modules
  ---------------------------------------------------------------------------
  local core_ok = check_module("migrate")

  local module_names = vim.tbl_keys(registry.list())
  table.sort(module_names)
  for _, name in ipairs(module_names) do
    check_module(registry.list()[name].module)
  end

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
    health.ok("lib.nvim.usercmd.composer available (user commands)")
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
    health.warn("ripgrep (rg) not found — 'cwd' scans cannot scan the workspace")
  end

  ---------------------------------------------------------------------------
  -- Configuration
  ---------------------------------------------------------------------------
  local cfg_ok, config = pcall(require, "migrate.config")
  if cfg_ok then
    local cfg = config.get()

    local parts = {}
    for _, name in ipairs(module_names) do
      table.insert(parts, string.format("%s=%s", name, tostring(cfg[name])))
    end
    table.insert(parts, string.format("debug=%s", tostring(cfg.debug)))
    health.info(table.concat(parts, ", "))

    if type(cfg.keymaps) == "table" then
      local km_parts = {}
      for _, name in ipairs(module_names) do
        table.insert(km_parts, string.format("%s=%s", name, tostring(cfg.keymaps[name] or false)))
      end
      health.info("keymaps: " .. table.concat(km_parts, ", "))

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

  ---------------------------------------------------------------------------
  -- Declared tools (lib.nvim.deps)
  ---------------------------------------------------------------------------
  -- migrate.nvim's own docs/install.json — the same rg check above, but
  -- with its declared `why` and a pointer to `:Lib deps show`. Does
  -- nothing if lib.nvim.deps is unavailable (older lib.nvim).
  local ok_deps, deps_health = pcall(require, "lib.nvim.deps.health")
  if ok_deps then
    health.start("migrate.nvim: declared tools (lib.nvim.deps)")
    deps_health.report_for("migrate.nvim")
  end
end

return M
