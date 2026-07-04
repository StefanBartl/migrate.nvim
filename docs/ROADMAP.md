# migrate.nvim — ROADMAP

Planned extensions beyond the current feature set. Order is roughly by
value/effort, not binding.

## New migration targets

- **`vim.lsp.buf_*` deprecations** — track upcoming Neovim LSP API renames
  the same way `opt` tracks `nvim_*_option`.
- **`vim.highlight` → `vim.hl`** and other 0.10+ renames, as they stabilize.
- **Pluggable migration modules** — a small registration API so a third
  module can be dropped in under `lua/migrate/<name>/` without touching
  `migrate.config`/`migrate.bindings` (currently `opt`/`notify` are wired in
  by name).

## Notify module

- **String-literal false positives** — `vim.notify(...)` inside a multiline
  `[[ ]]` string is currently detected as real code (documented in
  `docs/USAGE-EXAMPLES.md` Edge Case 2). Needs a lightweight "inside a long
  string" guard in `patterns.is_processable`.
- **Multiline aliased/existing `notify(...)` calls** — only `vim.notify` is
  handled for multiline calls today; aliased and bare `notify(...)` are
  single-line only (`migrate/notify/parser/init.lua`).

## Quality

- **Test suite** — `docs/TESTS/` with a headless runner (see
  `docs/TESTS/README.md`), covering the `opt` line-migration patterns and
  the `notify` parser/migrator pure functions.
- **CI** — `stylua --check` + `luacheck` + headless `docs/TESTS/run.lua`,
  mirroring the setup already in use on other `StefanBartl/*.nvim` repos.
- **Treesitter stays out of scope** — deliberately reverted in favor of pure
  regex/paren-counting (see `docs/Regex-statt-TS.md`); revisit only if a
  concrete correctness bug can't be fixed with the line-based approach.

## Housekeeping

- `docs/USAGE-EXAMPLES.md` still references the pre-refactor module paths
  (`usrcmds.migrate`, `lib.notify`) — needs a pass to `migrate`/
  `lib.nvim.notify` to match the current code.

## Checklist audit

migrate.nvim was audited against the personal Lua/Neovim plugin checklist.
Results and deliberate deviations: [ROADMAP/Checklist.md](ROADMAP/Checklist.md).
