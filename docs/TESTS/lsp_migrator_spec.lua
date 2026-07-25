-- docs/TESTS/lsp_migrator_spec.lua — migrate.lsp.migrator (pure regex rewrite).

return function(H)
  local eq = H.eq
  local migrator = require("migrate.lsp.migrator")

  eq(
    migrator.migrate_line("local clients = vim.lsp.buf_get_clients(bufnr)"),
    "local clients = vim.lsp.get_clients({ bufnr = bufnr })",
    "buf_get_clients(bufnr) -> get_clients({ bufnr = bufnr }) (vim.lsp. prefix)"
  )

  eq(
    migrator.migrate_line("local clients = vim.lsp.buf_get_clients()"),
    "local clients = vim.lsp.get_clients({ bufnr = 0 })",
    "buf_get_clients() with no arg defaults to { bufnr = 0 }"
  )

  eq(
    migrator.migrate_line("local clients = lsp.buf_get_clients(0)"),
    "local clients = lsp.get_clients({ bufnr = 0 })",
    "buf_get_clients (lsp. prefix)"
  )

  eq(
    migrator.migrate_line("for _, c in ipairs(vim.lsp.get_active_clients({ bufnr = 0 })) do"),
    "for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do",
    "get_active_clients -> get_clients, argument list left untouched"
  )

  eq(migrator.migrate_line("local x = 1"), "local x = 1", "unrelated line is left unchanged")
end
