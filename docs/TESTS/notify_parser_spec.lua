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

  -- long-bracket string literal false positive (USAGE-EXAMPLES.md Edge Case 2)
  local opens_inside, open_level = patterns.track_long_string("local example = [[", nil)
  ok(not opens_inside, "the opening [[ line itself is not 'inside' yet")

  local content_inside =
    patterns.track_long_string('  vim.notify("x", vim.log.levels.INFO)', open_level)
  ok(content_inside, "a line fully inside an open [[ ]] string reports starts_inside=true")

  local close_inside, close_level = patterns.track_long_string("]]", open_level)
  ok(close_inside, "the closing ]] line itself still reports starts_inside=true")
  eq(close_level, nil, "state is closed (nil) after the ]] line")

  local string_buf = H.scratch("lua")
  vim.api.nvim_buf_set_lines(string_buf, 0, -1, false, {
    "local example = [[",
    '  vim.notify("test", vim.log.levels.INFO)',
    "]]",
    'vim.notify("real one", vim.log.levels.WARN)',
  })
  local string_matches = parser.scan_buffer(string_buf)
  eq(#string_matches, 1, "only the call outside the string literal is matched")
  eq(string_matches[1].line, 4, "the real call is found on line 4, not inside the string")

  -- multiline aliased notify(...)
  local aliased_buf = H.scratch("lua")
  vim.api.nvim_buf_set_lines(aliased_buf, 0, -1, false, {
    "local notify, levels = vim.notify, vim.log.levels",
    "notify(",
    '  "hello",',
    "  levels.INFO",
    ")",
  })
  local aliased_matches = parser.scan_buffer(aliased_buf)
  eq(#aliased_matches, 1, "finds the multiline aliased call")
  eq(aliased_matches[1].replacement, 'notify.info("hello")', "multiline aliased call is migrated")

  -- multiline bare/existing notify(...) (no alias detected)
  local bare_buf = H.scratch("lua")
  vim.api.nvim_buf_set_lines(bare_buf, 0, -1, false, {
    "notify(",
    '  "hello",',
    "  vim.log.levels.WARN",
    ")",
  })
  local bare_matches = parser.scan_buffer(bare_buf)
  eq(#bare_matches, 1, "finds the multiline bare notify() call")
  eq(bare_matches[1].replacement, 'notify.warn("hello")', "multiline bare call is migrated")
end
