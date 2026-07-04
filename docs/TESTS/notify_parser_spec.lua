-- docs/TESTS/notify_parser_spec.lua — migrate.notify.parser.* (pure detection
-- + migration; no lib.nvim/telescope.nvim dependency).

return function(H)
  local eq = H.eq
  local ok = H.ok
  local patterns = require("migrate.notify.parser.patterns")
  local migrator = require("migrate.notify.parser.migrator")
  local parser = require("migrate.notify.parser")

  -- patterns: detection
  ok(patterns.is_vim_notify('vim.notify("hi", vim.log.levels.INFO)'), "detects vim.notify")
  ok(not patterns.is_vim_notify('notify.info("hi")'), "ignores already-migrated notify.info()")

  ok(
    patterns.is_existing_notify('notify("hi", vim.log.levels.WARN)'),
    "detects bare notify(msg, level)"
  )
  ok(
    not patterns.is_existing_notify('vim.notify("hi", vim.log.levels.WARN)'),
    "does not double-match vim.notify"
  )
  ok(
    not patterns.is_existing_notify('notify.info("hi")'),
    "does not match already-migrated notify.info()"
  )

  -- migrator: single-line vim.notify
  local m1, l1 = migrator.migrate_vim_notify_line('vim.notify("hello", vim.log.levels.INFO)')
  eq(m1, 'notify.info("hello")', "vim.notify -> notify.info()")
  eq(l1, "INFO", "reports the matched level name")

  -- migrator: bare/existing notify(...)
  local m2, l2 = migrator.migrate_existing_notify_line('notify("hello", vim.log.levels.WARN)')
  eq(m2, 'notify.warn("hello")', "notify(msg, level) -> notify.warn()")
  eq(l2, "WARN", "reports the matched level name")

  -- parser.scan_buffer: end-to-end on a real (lua-filetype) scratch buffer
  local buf = H.scratch("lua")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "local M = {}",
    "",
    "function M.run()",
    '  vim.notify("Command executed", vim.log.levels.INFO)',
    "end",
    "",
    "return M",
  })

  local matches = parser.scan_buffer(buf)
  eq(#matches, 1, "finds exactly one vim.notify call")
  eq(matches[1].line, 4, "match is on line 4")
  eq(
    matches[1].replacement,
    '  notify.info("Command executed")',
    "replacement text (indent preserved)"
  )
  eq(matches[1].log_level, "INFO", "captured log level")

  -- non-lua buffers are never scanned
  local txt_buf = H.scratch("text")
  vim.api.nvim_buf_set_lines(txt_buf, 0, -1, false, { 'vim.notify("hi", vim.log.levels.INFO)' })
  eq(#parser.scan_buffer(txt_buf), 0, "skips non-lua filetypes")
end
