# Architecture

```
migrate.nvim/
  lua/migrate/
    init.lua               -- setup()
    registry.lua            -- config key -> {module, command, desc}; pluggable module registration
    config/{init,DEFAULTS}  -- merge + get(); default keys derived from registry.lua
    bindings/               -- usrcmds, optional keymaps, which-key (all driven by registry.lua)
    common/                 -- shared command/picker/buffer/debug helpers
    opt/                    -- nvim_*_option -> *_option_value
    notify/                 -- vim.notify -> lib.nvim.notify
      parser/               -- detection: aliases, patterns, extraction, migration
      refactor/             -- application: import injection, cleanup, apply, write
    hl/                     -- vim.highlight.* -> vim.hl.*
    lsp/                    -- vim.lsp.buf_get_clients()/get_active_clients() -> vim.lsp.get_clients()
    health.lua
    @types/init.lua
  docs/BINDINGS.md          -- binding cheatsheet
  docs/USAGE-EXAMPLES.md    -- before/after scenarios
  TESTS/                -- headless spec suite (opt/hl/lsp.migrator, notify.parser.*)
  doc/migrate.txt           -- :h migrate
```

Adding a new migration module is: write `lua/migrate/<name>/{migrator,init}.lua`
(mirroring `opt`/`hl`), then `registry.register("<name>", { module = ...,
command = ..., desc = ... })` — `migrate.config.DEFAULTS`,
`migrate.bindings.{usrcmds,keymaps}`, `migrate.health`, and
`migrate.init`'s `enable_all()`/`disable_all()` pick it up automatically.
