---@module 'migrate.notify.refactor'
---@brief Main refactor orchestrator

local import = require("migrate.notify.refactor.import")
local cleanup = require("migrate.notify.refactor.cleanup")
local apply = require("migrate.notify.refactor.apply")

local M = {}

-- Re-export functions
M.inject_import = import.inject
M.remove_aliases = cleanup.remove_aliases
M.apply_match = apply.apply_match

return M
