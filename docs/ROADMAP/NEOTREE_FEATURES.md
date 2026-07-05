# Filetree feature audit — migrate.nvim

> Part of the cross-repo effort to collect filetree-manager features (Neotree,
> NvimTree, Netrw, …) into a future `filetree.nvim` that docks them onto whatever
> manager the user runs. This file records the audit **for migrate.nvim only**.

## Result: none

migrate.nvim is a **code-migration** plugin (deprecated option API,
`vim.notify`). It has **no filetree integration of any kind** — verified by a
full search of `lua/`, `doc/` and `docs/`:

```
grep -riE "neotree|nvim-tree|nvimtree|netrw|filetree" -r lua/ doc/ docs/
→ (no matches)
```

| Feature | Origin (file, line) | Theme | Notes |
| --- | --- | --- | --- |
| — | — | — | migrate.nvim contributes nothing to `filetree.nvim` |

### Why there is nothing to extract

migrate.nvim's only filesystem interaction is reading/writing the specific
files it migrates (`common/buffer.lua`, `notify/refactor/write.lua`) and
listing `*.lua` files under cwd for scans (`common/buffer.find_lua_files`,
via `vim.fn.globpath`) or via `rg --vimgrep`. None of that renders a tree,
inspects a file explorer buffer, or otherwise overlaps with a filetree
manager's feature set.

**Action for migrate.nvim: none.** This audit is complete and closed.
