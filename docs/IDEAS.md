# Ideas

Things considered for migrate.nvim that aren't open tasks — either explored
and deliberately not pursued, or genuinely speculative and not yet worth a
roadmap slot. See [`docs/ROADMAP.md`](ROADMAP.md) for what's actually planned.

## Considered and rejected

- **Treesitter-based scanning** — tried, then deliberately reverted in favor
  of pure regex/paren-counting. An earlier Treesitter implementation had
  offset corruption across multiple replacements and string-slicing
  collisions (Treesitter's exclusive `end_col` vs. Lua's 1-based string
  indexing). Full writeup: [`docs/Regex-statt-TS.md`](Regex-statt-TS.md).
  Revisit only if a concrete correctness bug turns up that the line-based
  approach can't fix.

- **`filetree.nvim` integration** — migrate.nvim was audited as part of a
  cross-repo sweep for filetree-manager features (Neotree/NvimTree/Netrw) to
  fold into a future `filetree.nvim`. Result: none — migrate.nvim is a
  code-migration plugin with no filetree surface at all.
