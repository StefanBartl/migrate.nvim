-- docs/TESTS/hl_migrator_spec.lua — migrate.hl.migrator (pure regex rewrite).

return function(H)
  local eq = H.eq
  local migrator = require("migrate.hl.migrator")

  eq(
    migrator.migrate_line("vim.highlight.range(bufnr, ns, hl, from, to)"),
    "vim.hl.range(bufnr, ns, hl, from, to)",
    "vim.highlight.range -> vim.hl.range"
  )

  eq(
    migrator.migrate_line('vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })'),
    'vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })',
    "vim.highlight.on_yank -> vim.hl.on_yank"
  )

  eq(
    migrator.migrate_line("local p = vim.highlight.priorities.user"),
    "local p = vim.hl.priorities.user",
    "vim.highlight.priorities -> vim.hl.priorities"
  )

  eq(migrator.migrate_line("local x = 1"), "local x = 1", "unrelated line is left unchanged")
end
