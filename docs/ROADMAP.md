# migrate.nvim — ROADMAP

Open tasks only. Shipped work lives in [`docs/FEATURES.md`](FEATURES.md);
explored-but-not-pursued or speculative work lives in
[`docs/IDEAS.md`](IDEAS.md).

No open items are recorded right now. When something is planned it goes here
as a checklist entry until it ships; shipped work is removed rather than ticked.

---

## `docs/ROADMAP/` — design notes, audits, concepts

Everything below lives in [`docs/ROADMAP/`](ROADMAP/) and is **not** open work
unless it says so. Indexed here because a folder next to a file is easy to
miss, and these are the documents that explain *why* the plugin is shaped the
way it is.

| Document | What it is |
| --- | --- |
| [`Arch&Coding.md`](ROADMAP/Arch&Coding.md) | Architecture and coding rules, applied to this plugin. |
| [`Checklist.md`](ROADMAP/Checklist.md) | The Lua/Neovim master checklist, applied to this plugin. |
| [`Zentral-Prinzipien.md`](ROADMAP/Zentral-Prinzipien.md) | The central principles, applied to this plugin. |
| [`PluginPackagingChecklist.md`](ROADMAP/PluginPackagingChecklist.md) | The plugin/config packaging checklist, applied to this plugin. |
| [`NEOTREE_FEATURES.md`](ROADMAP/NEOTREE_FEATURES.md) | Which of this plugin's features are worth porting into filetree.nvim. |

The audits share a convention: **✅ good · 🟡 partial · ❌ gap**.
Findings that were acted on are removed rather than ticked, so what is left
standing is either an open gap or a deliberate deviation with its reasoning.
