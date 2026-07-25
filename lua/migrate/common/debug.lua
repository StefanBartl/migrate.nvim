---@module 'migrate.common.debug'
---@brief Opt-in tracing for the scan -> picker -> apply -> write pipeline.
---@description
--- No-ops unless `debug = true` in `migrate.config`. A thin wrapper around
--- `lib.nvim.notify`'s `.debug()` level rather than a bespoke logger, so
--- trace output goes through the same sink/filtering as everything else
--- migrate.nvim reports.

local notify = require("lib.nvim.notify").create("[migrate.debug]")

local M = {}

---Trace a pipeline stage, if `debug = true` in config.
---@param fmt string string.format format string
---@param ... any
---@return nil
function M.trace(fmt, ...)
  if not require("migrate.config").get().debug then
    return
  end
  notify.debug(string.format(fmt, ...))
end

return M
