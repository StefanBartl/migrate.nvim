# Architecture

```
migrate.nvim/
  lua/migrate/
    init.lua               -- setup()
    config/{init,DEFAULTS}  -- merge + get()
    bindings/               -- usrcmds, optional keymaps, which-key
    common/                 -- shared command/picker/buffer helpers
    opt/                    -- nvim_*_option -> *_option_value
    notify/                 -- vim.notify -> lib.nvim.notify
      parser/               -- detection: aliases, patterns, extraction, migration
      refactor/             -- application: import injection, cleanup, apply, write
    health.lua
    @types/init.lua
  docs/BINDINGS.md          -- binding cheatsheet
  docs/USAGE-EXAMPLES.md    -- before/after scenarios
  doc/migrate.txt           -- :h migrate
```
