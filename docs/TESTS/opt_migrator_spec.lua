-- docs/TESTS/opt_migrator_spec.lua — migrate.opt.migrator (pure regex rewrite).

return function(H)
  local eq = H.eq
  local migrator = require("migrate.opt.migrator")

  eq(
    migrator.migrate_line('vim.api.nvim_buf_set_option(bufnr, "filetype", "myft")'),
    'vim.api.nvim_set_option_value("filetype", "myft", { buf = bufnr })',
    "buf_set_option (vim.api. prefix)"
  )

  eq(
    migrator.migrate_line('api.nvim_win_set_option(winid, "number", true)'),
    'api.nvim_set_option_value("number", true, { win = winid })',
    "win_set_option (api. prefix)"
  )

  eq(
    migrator.migrate_line('local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")'),
    'local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })',
    "buf_get_option"
  )

  eq(
    migrator.migrate_line('nvim_win_get_option(winid, "wrap")'),
    'nvim_get_option_value("wrap", { win = winid })',
    "win_get_option (no prefix)"
  )

  eq(migrator.migrate_line("local x = 1"), "local x = 1", "unrelated line is left unchanged")
end
