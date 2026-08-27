# Workflow — using migrate.nvim day to day

Every feature here is documented on its own in `docs/FEATURES.md`. This is
the different question: how the four migrations, the picker, and the
`cwd` auto-write behavior actually combine once you're clearing deprecated
API calls out of a real project.

## Scope choice is the first decision, not an afterthought

The four scopes behave differently enough that picking the wrong one
changes the whole interaction, not just how much gets touched:

| Scope | Applies | Opens picker | Auto-writes |
|---|---|---|---|
| *(none)* — current line | immediately | no | no |
| range (`:'<,'>`) | immediately | no | no |
| `%` — buffer | no | yes | no |
| `cwd` | no | yes (via ripgrep) | **yes**, on apply |

Line and range are fire-and-forget — good for a quick fix while you're
already looking at the offending call. `%` and `cwd` are review-first:
nothing changes until you act on an entry in the Telescope picker, and
even then only `cwd` writes the touched files back to disk for you —
`%`-scope edits stay in the buffer, unsaved, exactly like a manual edit
would. Add `-n`/`--dry-run` to a line or range invocation when you want to
see the before/after first — it's the only preview step those two scopes
have, since neither opens a picker; `%`/`cwd` accept the flag too but
already preview through the picker, so it changes nothing there.

## Backup before a `cwd` run — it still writes for you, dry-run or not

`:MigrateNotify cwd` (or any module's `cwd` scope) auto-writes every
touched file the moment you apply a match — there's no `--dry-run` or
confirm-before-write step beyond the picker's own apply action. Treat a
`cwd` run on an unclean working tree as risky: commit or stash first, do
the picker pass, then diff the result. The plugin's own project excludes
itself from `cwd` scans (so it can migrate other projects without touching
its own source), but that self-exclusion doesn't extend to *your* project
having similar guard logic — read the picker preview before applying to a
whole tree you haven't reviewed a sample of first.

## `:MigrateNotify`'s argument slot shifts under range mode — this is the trap

`module_name` is always the *second* token to `:MigrateNotify`, but in
range mode the first slot is already consumed by the (unused) scope
marker, so a range invocation needs an explicit placeholder first:

```vim
:'<,'>MigrateNotify - my.plugin.ui
```

Passing `:'<,'>MigrateNotify my.plugin.ui` puts the module name in the
wrong slot — it's silently treated as if no module name was given, and the
buffer path is auto-detected instead. Worth double-checking the injected
`require(...)` line's module name after a range-scope migration, since a
mistake here doesn't error, it just silently uses the fallback.

## Multiline `vim.notify` calls collapse to one line — expect a diff, not a 1:1 rewrite

`:MigrateNotify`'s parser tracks balanced parens across lines and
consolidates a multiline call onto a single line in the replacement. This
is deliberate (the level-method form rarely needs the original's line
breaks), but it means the picker's before/after preview is the right place
to catch it — don't assume line count is preserved when reviewing a diff
after a `cwd` run.

## A `vim.notify(...)` example embedded in a doc string still gets left alone — verify, don't assume

The notify parser deliberately skips any line that starts inside a
`[[ ]]`/`[=[ ]=]` long-bracket string, so a `vim.notify(...)` call written
as *string content* (a code sample embedded in a Lua doc string) is left
untouched rather than corrupted. If you're migrating a file that documents
its own `vim.notify` usage in a long string, expect that documentation
example to still read `vim.notify(...)` afterward — that's correct
behavior, not a missed migration.

## Partial migrations are safe to re-run

Because `:MigrateNotify` detects existing aliases and already-migrated
`notify.info(...)`-style calls before scanning, running it again on a file
that's already partly migrated (some calls rewritten by hand, some not)
only touches what's left — it won't double-wrap an already-correct call or
re-inject a duplicate `require(...)` line. This makes it reasonable to
interleave a `cwd` migration with manual spot-fixes rather than needing an
all-or-nothing pass.

## Registering a third-party module gets you a command for free — but not a keymap unless you ask

Calling `require("migrate.registry").register("myname", {...})` before
`setup()` wires the new module into `config.DEFAULTS`, `:checkhealth
migrate`, and `enable_all()`/`disable_all()` automatically — but a keymap
for it only appears if you also add `keymaps.myname = "<lhs>"` to
`setup()` yourself; registration alone doesn't assume you want one.
