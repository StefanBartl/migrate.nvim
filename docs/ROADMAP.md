# migrate.nvim — ROADMAP

Planned extensions beyond the current feature set. Order is roughly by
value/effort, not binding.

## New migration targets

- **Further 0.10+/0.12+ renames** — `opt`/`notify`/`hl`/`lsp` cover the
  deprecations known today; revisit as new Neovim releases add more
  (`vim.highlight`/`vim.lsp.buf_get_clients` already covered — see
  `lua/migrate/hl/`, `lua/migrate/lsp/`). Ground-truth any new candidate
  against the installed runtime's `@deprecated` tags before adding it,
  the way `lua/migrate/lsp/migrator.lua`'s docstring does.

## Notes / deliberate deviations

- **Treesitter stays out of scope** — deliberately reverted in favor of pure
  regex/paren-counting (see `docs/Regex-statt-TS.md`); revisit only if a
  concrete correctness bug can't be fixed with the line-based approach.

## Checklist audit

migrate.nvim was audited against the personal Lua/Neovim plugin checklist
([ROADMAP/PluginPackagingChecklist.md](ROADMAP/PluginPackagingChecklist.md))
and the three personal architecture/coding checklists. All items that came
out of that audit as open (CI workflow, `lib.nvim.usercmd`, a migration-module
registry, `@see` cross-references) have since been implemented — see each
checklist's own "Fazit" for what changed and which commit. The only
remaining item is a documented, deliberate deviation (a shared `@types`
surface instead of a `/types` folder per subdirectory), not an open task.
Audit docs, kept for reference:

- [ROADMAP/Arch&Coding.md](ROADMAP/Arch&Coding.md) — architecture & coding rules
- [ROADMAP/Zentral-Prinzipien.md](ROADMAP/Zentral-Prinzipien.md) — central module principles
- [ROADMAP/Checklist.md](ROADMAP/Checklist.md) — master checklist (Schnell-Check/PR/Coding)
- [ROADMAP/NEOTREE_FEATURES.md](ROADMAP/NEOTREE_FEATURES.md) — filetree-feature audit (result: none)
